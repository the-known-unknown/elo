#!/usr/bin/env bash
#
# Builds the Elo executable with SwiftPM and assembles a proper .app bundle so
# that LSUIElement (background agent) and the Accessibility permission behave
# correctly.
#
# IMPORTANT — code signing & the Accessibility permission:
#   macOS TCC pins the Accessibility grant to the app's *code signature*. An
#   ad-hoc signature has no stable identity, so every rebuild looks like a brand
#   new app and you get re-prompted. To make the grant persist across rebuilds,
#   sign with a stable identity (a self-signed cert is fine for local dev):
#
#     1. Keychain Access ▸ Certificate Assistant ▸ Create a Certificate…
#          Name: "Elo Dev"   Identity Type: Self Signed Root
#          Certificate Type: Code Signing
#     2. Re-run this script. It auto-detects the "Elo Dev" identity.
#
#   Override the identity name with ELO_SIGN_IDENTITY if you use another cert.
#
# Usage:
#   ./build_app.sh            # release build (default)
#   ./build_app.sh debug      # debug build

set -euo pipefail
cd "$(dirname "$0")"

CONFIG="${1:-release}"
APP_NAME="Elo"
BUILD_BIN=".build/${CONFIG}/${APP_NAME}"
APP_BUNDLE="build/${APP_NAME}.app"
SIGN_IDENTITY="${ELO_SIGN_IDENTITY:-Elo Dev}"

echo "▶ Building (${CONFIG})…"
swift build -c "${CONFIG}"

echo "▶ Assembling ${APP_BUNDLE}…"
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"
cp "${BUILD_BIN}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
cp "Resources/Info.plist" "${APP_BUNDLE}/Contents/Info.plist"

# Prefer a stable identity so the Accessibility grant survives rebuilds.
if security find-identity -v -p codesigning | grep -q "${SIGN_IDENTITY}"; then
    echo "▶ Code signing with stable identity: ${SIGN_IDENTITY}"
    codesign --force --deep --options runtime --sign "${SIGN_IDENTITY}" "${APP_BUNDLE}"
else
    echo "⚠ No '${SIGN_IDENTITY}' code-signing identity found — falling back to AD-HOC."
    echo "  The Accessibility permission will NOT persist across rebuilds and you"
    echo "  will be re-prompted every launch. To fix this, create a self-signed"
    echo "  'Code Signing' certificate named '${SIGN_IDENTITY}' in Keychain Access"
    echo "  (see the header of this script), then rebuild."
    codesign --force --deep --sign - "${APP_BUNDLE}"
fi

echo ""
echo "✔ Built ${APP_BUNDLE}"
echo "  Launch (background agent):  open \"${APP_BUNDLE}\""
echo "  Launch with live logs:      \"${APP_BUNDLE}/Contents/MacOS/${APP_NAME}\""
