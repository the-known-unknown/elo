# Elo (macOS) — Writing Assistant

Elo is a background macOS agent. You select text anywhere — in a native app or a
browser — and a small floating menu (e.g. **Make concise**, **Improve Writing**)
appears next to the selection. Choosing an option will eventually run the text
through an LLM. This is the **front-end prototype**: the menu appears and the
chosen action is logged, but no LLM is called yet.

> Status: prototype. The two menu actions only write to the system log.

---

## Quick start

### Prerequisites
- macOS 13 (Ventura) or later
- Swift toolchain (Swift 5.9+ / Xcode Command Line Tools). Verify with `swift --version`.

### Build & run
From this directory (`app/mac`):

```sh
./build_app.sh            # release build -> build/Elo.app
open build/Elo.app        # launch as a background agent
```

For development with live logs in the terminal:

```sh
./build_app.sh debug
./build/Elo.app/Contents/MacOS/Elo
```

You can also open the package directly in Xcode (`File ▸ Open ▸ Package.swift`),
though running from Xcode produces a differently-signed binary that may need the
Accessibility permission re-granted — `build_app.sh` is the smoother path.

> **Make the permission stick:** sign with a stable identity so the Accessibility
> grant survives rebuilds. See *Troubleshooting → "It re-prompts every launch"*
> below. Without it, every rebuild looks like a new app and re-prompts.

### Grant permission (required)
On first launch Elo asks for **Accessibility** access (only if it isn't already
granted). Approve it in:

`System Settings ▸ Privacy & Security ▸ Accessibility` → enable **Elo**.

Accessibility is required to read selected text (Accessibility API) and to
synthesize the ⌘C keystroke used by the hotkey's clipboard fallback. The check
is idempotent: if the permission is already on, Elo stays silent and does **not**
re-prompt on each launch. Re-check anytime from the menu-bar icon (✎) ▸ *Check
Accessibility Permission…*.

### Try it
There are two ways to summon the menu:
1. **Drag-select** across text in TextEdit, Notes, Mail, etc. (automatic), or
2. Select text any way you like and press the **⌃⌘E** hotkey.

The overlay menu then appears beside the selection.
3. Click an action → check the log:

```sh
log stream --predicate 'eventMessage CONTAINS "[Elo]"' --info
```

Apps that don't expose selection over Accessibility (many browsers / Electron
apps) won't auto-trigger — use the hotkey fallback **⌃⌘E** there.

---

## How it works (Approach C — hybrid)

Two selection modalities, both implemented as `SelectionListener` subclasses, feed
one handler that reads the selection and shows the overlay:

| Concern | Mouse modality | Hotkey modality |
| --- | --- | --- |
| **Detect** a selection | Global mouse monitor: drag-select (`MouseSelectionListener`) | Global hotkey ⌃⌘E (`HotkeyListener`) |
| **Read** the text + bounds | Accessibility API: `kAXSelectedText…` (`SelectionReader`) | Accessibility, then synthesize ⌘C + read/restore pasteboard |
| **Show** the menu | Non-activating `NSPanel` hosting SwiftUI (`OverlayPanel` / `OverlayMenuView`) | (same) |

The automatic (mouse) path is **Accessibility-only on purpose**, so Elo never
touches your clipboard behind your back. The clipboard fallback is reserved for
the explicit hotkey trigger.

```
mouse drag-up ──► MouseSelectionListener ─┐
                                          ├─emit─► OverlayController ─► OverlayPanel (SwiftUI menu)
hotkey ⌃⌘E ─────► HotkeyListener ─────────┘                          └─► action logged
        (both subclass SelectionListener; both use SelectionReader)
```

---

## Major decisions

- **Native Swift (AppKit + SwiftUI), not Electron/Tauri/Flutter.** Every hard
  capability Elo needs — reading selected text and bounds (Accessibility API),
  global event monitoring (`NSEvent`/`CGEventTap`), a non-activating floating
  overlay (`NSPanel`), and a background agent (`LSUIElement`/`NSStatusItem`) — is
  a macOS-specific API. Cross-platform frameworks would still require native
  bridge code for exactly these parts, while adding runtime weight that fights
  the "lightweight, invisible until needed" goal. Cross-platform reuse also
  doesn't apply: Windows uses entirely different APIs (UI Automation,
  `SetWinEventHook`). Shared, portable logic belongs in `backend/` instead.

- **Approach C (hybrid) over a single technique.** Pure Accessibility gives the
  best UX (auto-trigger, precise placement) but has weak coverage in browsers /
  Electron. Pure hotkey + clipboard is universal but invasive and imprecise.
  Hybrid uses the best available method and degrades gracefully.

- **Background agent (`LSUIElement = true`) + menu-bar item.** No Dock icon, no
  main window — the app is invisible until a selection summons the overlay.

- **Non-activating `NSPanel`.** Lets the overlay receive clicks without stealing
  focus, so the user's text selection in the source app is preserved.

- **SwiftUI inside `NSHostingView`.** AppKit owns the panel mechanics; SwiftUI
  builds the menu — fast iteration on UI without giving up window control.

- **SwiftPM + `build_app.sh` instead of a committed `.xcodeproj`.** Builds from
  the command line with no generated project to maintain. The script signs with a
  stable identity (`Elo Dev`) when available so the Accessibility (TCC) grant
  survives rebuilds, falling back to ad-hoc with a warning otherwise. Opening
  `Package.swift` in Xcode still works for those who prefer the IDE.

- **Carbon `RegisterEventHotKey` for the hotkey.** Zero third-party dependencies
  for the prototype; can be swapped for a configurable shortcut library later.

- **`SelectionListener` abstract base.** Both modalities subclass it and override
  `start()`/`stop()`, then call `emit(_:)` to surface a selection through one
  shared handler. Adding a new trigger later means adding one subclass.

- **Idempotent permission check.** `AccessibilityManager.requestAccessIfNeeded()`
  prompts only when the permission is actually missing, so granted users are
  never nagged on launch.

- **Files grouped by responsibility** (`App/`, `Permissions/`, `Selection/`,
  `Listeners/`, `Overlay/`) rather than a flat folder.

---

## Project layout

```
app/mac/
├── Package.swift              # SwiftPM executable target (macOS 13+)
├── build_app.sh              # build + assemble + ad-hoc sign Elo.app
├── Resources/Info.plist      # bundle metadata (LSUIElement, bundle id, …)
└── Sources/Elo/
    ├── App/
    │   ├── main.swift               # entry point; sets .accessory activation policy
    │   ├── AppDelegate.swift        # wires listeners + overlay together
    │   └── StatusItemController.swift # menu-bar item (permission check, quit)
    ├── Permissions/
    │   └── AccessibilityManager.swift # idempotent TCC permission check/prompt
    ├── Listeners/
    │   ├── SelectionListener.swift      # abstract base (start/stop/emit)
    │   ├── MouseSelectionListener.swift # drag-select detection (AX-only)
    │   └── HotkeyListener.swift         # ⌃⌘E hotkey (AX + clipboard fallback)
    ├── Selection/
    │   └── SelectionReader.swift    # AX read + clipboard fallback (text + bounds)
    └── Overlay/
        ├── OverlayController.swift  # overlay lifecycle + action logging
        ├── OverlayPanel.swift       # non-activating NSPanel + positioning
        └── OverlayMenuView.swift    # SwiftUI menu (Make concise / Improve Writing)
```

---

## Known limitations (prototype)

- Actions only log; no LLM/backend call yet (hook in `OverlayController.handle`).
- Web/Electron apps often don't expose selection over Accessibility → rely on the
  ⌃⌘E hotkey there. A browser extension (Approach D) is the long-term fix for web.
- The drag-select heuristic can occasionally trigger on drag-scrolls; tuning the
  threshold / gesture detection is future work. (Selection is now limited to the
  two intended modalities: drag-select and the ⌃⌘E hotkey.)
- Selection-bounds placement assumes the primary screen origin; multi-display
  edge cases may need refinement.
- Not sandboxed and only ad-hoc signed — fine for local dev, not for
  distribution. Notarization / Developer ID signing comes later.

## Troubleshooting

### "It re-prompts for Accessibility every launch"
macOS pins the Accessibility grant to the app's **code signature**. An ad-hoc
signature changes on every rebuild, so each build looks like a new app and the
old grant (which still shows as ON in System Settings) no longer applies.

Fix it once by signing with a stable, self-signed identity:

1. **Create a code-signing certificate** (one time):
   Keychain Access ▸ *Certificate Assistant* ▸ *Create a Certificate…*
   - Name: `Elo Dev`
   - Identity Type: *Self Signed Root*
   - Certificate Type: *Code Signing*
2. **Clear the stale grant** so macOS prompts cleanly once more:
   ```sh
   tccutil reset Accessibility com.tku.elo
   ```
   (Or remove the old `Elo` row in System Settings ▸ Privacy & Security ▸
   Accessibility with the `–` button.)
3. **Rebuild and run** — `build_app.sh` now auto-detects `Elo Dev`:
   ```sh
   ./build_app.sh && open build/Elo.app
   ```
   Grant access once. Subsequent rebuilds keep the same identity, so it sticks.

Use a different certificate name via `ELO_SIGN_IDENTITY="My Cert" ./build_app.sh`.

Also make sure you launch the **bundle** (`build/Elo.app`), not the bare binary
(`swift run` / `.build/.../Elo`) — the bare binary has a different identity and
won't be covered by the grant.

## Next steps

1. Validate Accessibility coverage across your real target apps.
2. Replace the logging in `OverlayController.handle` with a call to `backend/`.
3. Add an outside-the-AX clipboard-restore safety pass and richer gesture tuning.
4. Consider a browser extension for first-class web support.
