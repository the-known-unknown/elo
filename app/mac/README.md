# Elo (macOS) — Writing Assistant

Elo is a background macOS **menu-bar agent**. The end goal: select text anywhere,
invoke Elo, and have it rewrite the text via an LLM (e.g. "Improve writing",
"Make concise"). This repo is the app being built up incrementally.

> **Current status.** The shell is complete: a menu-bar app with **Settings** and
> **About** windows, a persisted settings model, a global hotkey, launch-at-login,
> and accessibility handling. The hotkey currently just logs a greeting — the
> text-selection reading and the on-screen overlay are **not built yet**.

---

## Quick start

**Prerequisites:** macOS 13+, the Swift toolchain (`swift --version`).

**Fast dev loop (logs in the terminal):**
```sh
swift run          # from app/mac — builds & runs; press Ctrl-C or use menu → Quit
```
Good for UI, the hotkey, and logs. **Not** for Accessibility or launch-at-login —
those need a real signed app bundle (see below).

**Run as the real app (bundle):**
```sh
./build_app.sh && open build/Elo.app
```

**Watch logs** (when launched via `open`):
```sh
log stream --predicate 'eventMessage CONTAINS "[Elo]"' --info
```

The app has no Dock icon; look for the ✎ icon in the menu bar (Settings / About /
Quit). Default hotkey is **⌘⌥E** (logs a greeting for now).

---

## How the code is organized

One SwiftPM executable target, grouped by responsibility. What to expect in each
folder:

- **`App/`** — application entry point, wiring, and the menu-bar presence.
- **`Common/`** — small app-wide utilities (constants, logging).
- **`Model/`** — pure data types (no logic), including the persisted settings.
- **`Persistence/`** — reads/writes the settings file.
- **`Store/`** — the observable single source of truth for settings.
- **`System/`** — thin wrappers over macOS OS integrations (hotkey, login item, permissions).
- **`Screens/`** — all windows and their SwiftUI views (About, Settings).

### Files at a glance

**`App/`**
- `main.swift` — entry point; runs the app as a background agent (`.accessory`, no Dock icon).
- `AppDelegate.swift` — wires everything on launch: installs the main menu, the status-bar item, the settings store, and registers the global hotkey (re-registering when it changes). Owns the About/Settings windows.
- `MainMenu.swift` — builds an (invisible) App + Edit menu so standard editing shortcuts work (see "Invisible main menu" below).
- `MenuItem.swift` — a tiny declarative model for status-bar menu rows (title + handler, or a separator) backed by a closure-driven `NSMenuItem`.
- `StatusItemController.swift` — the menu-bar ✎ item and its dropdown (Settings, About, Quit).

**`Common/`**
- `AppInfo.swift` — app name, bundle id, version, build, copyright — read from `Info.plist` with sensible fallbacks (so it also works under `swift run`).
- `Log.swift` — global `log(_:)` that prefixes every line with `[Elo]`.

**`Model/`**
- `Hotkey.swift` — a shortcut (key code + modifiers + label); `Codable`/`Equatable`; renders as `⌘⌥E`; default is ⌘⌥E.
- `Function.swift` — a writing action (`id`, `label`, `prompt`); `Codable`; ships the three defaults (Improve writing / Make Concise / Itemize); max 4.
- `AppSettings.swift` — the whole persisted document: a `schemaVersion` plus an `application` section (`hotkey` + `functions`), with defaults.

**`Persistence/`**
- `SettingsRepository.swift` — a protocol plus a file-backed implementation that loads/saves `elo.settings.json`, writes atomically off the main thread, and falls back to defaults if the file is missing or unreadable.

**`Store/`**
- `SettingsStore.swift` — `ObservableObject` that loads settings on init, **auto-saves on change (debounced)**, and exposes **granular publishers** (`hotkeyPublisher`, `functionsPublisher`) so services react only to the slice they care about.

**`System/`**
- `HotkeyManager.swift` — registers a global hotkey via Carbon `RegisterEventHotKey` (no permission needed) and calls a handler; maps AppKit modifiers to Carbon internally.
- `LaunchAtLoginManager.swift` — wraps `SMAppService` (`isEnabled` / `setEnabled`) to add/remove Elo as a login item.
- `AccessibilityManager.swift` — the Accessibility (TCC) permission: live `isTrusted` and a `requestAccess()` that registers Elo and opens the system prompt.

**`Screens/`**
- `AppWindowController.swift` — base class for auxiliary windows: builds lazily, sizes to its SwiftUI content, centers on screen, and brings the app forward. About/Settings subclass it and just supply a title + content.
- `About/AboutView.swift` — the About screen (name, version, copyright).
- `About/AboutWindowController.swift` — the About window.
- `Settings/SettingsWindowController.swift` — the Settings window; injects the settings store into the UI.
- `Settings/SettingsView.swift` — the tabbed container (**Application** | **AI Models**).
- `Settings/ApplicationSettingsView.swift` — the Application tab (General / Hotkey / Functions / Accessibility) plus the function row and the modal function editor.
- `Settings/HotkeyRecorderView.swift` — a small control that records a key combination.
- `Settings/AIModelsSettingsView.swift` — placeholder tab (empty for now).

**Project files**
- `Package.swift` — the SwiftPM target (macOS 13+).
- `Resources/Info.plist` — bundle metadata (`LSUIElement`, bundle id, version, …).
- `build_app.sh` — builds and assembles `build/Elo.app`, code-signing with a stable identity when available (see Troubleshooting).

---

## The settings module

Settings flow through four clean layers, so the UI stays declarative and there's a
single source of truth.

```
elo.settings.json  ⇄  SettingsRepository  ⇄  SettingsStore  ⇄  UI (fragment bindings)
     (file)              (load/save)          (@Published)      $store.settings.application.…
```

1. **Model** (`AppSettings`) — plain `Codable` value types that mirror the file.
2. **Repository** (`SettingsRepository`) — the only thing that touches the file. Loads on launch (defaults if missing/corrupt) and saves atomically in the background.
3. **Store** (`SettingsStore`) — holds the decoded document as `@Published settings`, auto-saves on any change (debounced ~0.5s), and materializes the file on first launch. Exposes per-slice publishers.
4. **UI** — each control binds to **its own fragment** of the document, e.g. the recorder binds to `$store.settings.application.hotkey` and the Functions list edits `store.settings.application.functions`. Editing a fragment mutates the document → the store persists the whole file. **Many fragment editors, one file writer** (the store), which avoids multiple writers clobbering the file.

Services observe slices too: `AppDelegate` subscribes to `hotkeyPublisher` and
re-registers the global hotkey whenever it changes.

**What is (and isn't) persisted.** Only user data lives in the file — the
**hotkey** and **functions**. **Launch-at-login** and **Accessibility** are *live
OS state* (owned by `SMAppService` and TCC); persisting a copy would drift from
reality, so those are always read fresh from their managers and re-checked when
the Settings window opens.

The file lives at `~/Library/Application Support/Elo/elo.settings.json` and is
pretty-printed so it's easy to read, diff, and share.

---

## Invisible main menu (editing shortcuts)

A background agent has no menu bar, but macOS still routes the standard editing
shortcuts (⌘X/⌘C/⌘V/⌘A, ⌘Z/⇧⌘Z) through the app's **main menu** to the focused
text field. With no main menu, copy/paste silently do nothing in text areas.

`MainMenu.install()` (called at launch) builds a minimal App + **Edit** menu so
those shortcuts work in the Settings fields — even though the menu bar itself is
never shown. It also adds ⌘Q to quit.

---

## Key decisions

- **Native Swift (AppKit + SwiftUI).** Everything Elo needs — a background agent, global hotkey, permissions, on-screen overlay later — is macOS-specific. Cross-platform frameworks would still require native bridge code for exactly these parts. Portable logic (LLM calls) will live in `backend/`.
- **Background agent (`LSUIElement`) + menu-bar item.** No Dock icon or main window; invisible until needed.
- **Windows via a shared `AppWindowController`.** One place owns lazy creation, size-to-content, centering, and focus; each screen just supplies title + content.
- **Global hotkey via Carbon `RegisterEventHotKey`.** Works app-wide with no permission and no third-party dependency.
- **Own hotkey recorder instead of a library.** The popular `KeyboardShortcuts` library can't build here (its `#Preview` macro needs full Xcode; this environment has Command Line Tools only), so we built a small recorder.
- **Live OS state is never persisted.** Launch-at-login and Accessibility are read live and re-checked on window focus (macOS sends no change notification).
- **Settings auto-save (no Save button).** The macOS convention; the function editor's Save just commits its fragment into the store, which persists.

---

## Permissions & signing (important)

macOS ties the **Accessibility** grant (and, in practice, launch-at-login
behavior) to the app's **code signature**. An **ad-hoc** signature changes on
every rebuild, so each build looks like a brand-new app: the grant won't stick and
you'll be re-prompted / see the toggle not take effect.

Fix it once with a stable self-signed identity:

1. **Keychain Access ▸ Certificate Assistant ▸ Create a Certificate…**
   - Name: `Elo Dev`, Identity Type: *Self Signed Root*, Certificate Type: *Code Signing*
2. Clear any stale grant: `tccutil reset Accessibility com.tku.elo`
3. Rebuild & run — `build_app.sh` auto-detects `Elo Dev`:
   ```sh
   ./build_app.sh && open build/Elo.app
   ```
   (Override the cert name with `ELO_SIGN_IDENTITY="My Cert" ./build_app.sh`.)

Also note: **Accessibility and launch-at-login only work from the `.app` bundle**,
not `swift run` — a bare binary has no bundle identity for macOS to register.

---

## Not built yet / next steps

- **Text selection + overlay** — the core "select text → floating menu" UX.
- **AI Models tab** — currently empty; API keys will go in the Keychain, not the settings file.
- **Backend** — the LLM calls (separate `backend/` folder, empty for now).
- **Windows app** — separate native client later (`app/win/`, empty for now).
