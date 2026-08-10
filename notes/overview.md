# Übersicht — Project Overview

Übersicht is a macOS app that renders live "widgets" directly on the
desktop — behind your icons, below your windows, always visible. A
widget is a small JavaScript/JSX (or legacy CoffeeScript) file that runs
a shell command on a timer and renders the output with React. Think
system stats, weather, calendar agendas, or ASCII-art fortunes, styled
however you like with CSS-in-JS.

Homepage: http://tracesof.net/uebersicht · License: GPL v3

## Architecture

The project is two halves that run as one app:

```
┌─────────────────────────────┐        ┌──────────────────────────────┐
│   Uebersicht/  (Cocoa shell) │  NSTask │   server/  (Node backend)    │
│                               │◄───────►│                              │
│  • Draws borderless windows   │  HTTP/  │  • Watches the widget dir    │
│    at desktop-icon window     │  WS on  │  • Bundles each widget with  │
│    level, one per screen      │ 127.0.0.1│    browserify (JSX/coffee)  │
│  • Embeds a WKWebView that    │  :41416  │  • Serves /state/ (current  │
│    loads the server's page    │         │    widgets+settings)         │
│  • Menu bar item, prefs,      │         │  • POST /run/ executes a     │
│    Sparkle auto-update        │         │    widget's shell command    │
└─────────────────────────────┘        └──────────────────────────────┘
```

- **`Uebersicht/`** — the native macOS app (Objective-C, `Uebersicht.xcodeproj`).
  It has no dock icon (menu-bar/accessory app). On launch it spawns the
  embedded Node server as a child process (`NSTask`), waits for it to
  report `server started`, then opens one borderless `WKWebView` window
  per screen pointed at `http://127.0.0.1:41416/`. It also listens for
  screen/wallpaper changes and re-syncs windows accordingly, and ships
  Sparkle for auto-updates.

- **`server/`** — a Node.js backend, written in CoffeeScript with some
  plain JS, structured as Connect middleware (`server/src/app.coffee`
  wires it all together). Responsibilities:
  - Watches the widget directory (`directory_watcher.coffee`) and
    rebundles a widget with browserify whenever its file changes,
    pushing the update to connected clients over WebSocket
    (`WidgetBundler.js`, `MessageBus.js`).
  - Serves the widget bundle to the browser client on request
    (`serveWidgets.js`).
  - `POST /run/` (`command_server.coffee`) spawns `bash` and streams
    stdout/stderr back — this is what actually executes a widget's
    `command` string on each refresh.
  - `GET /state/` (`StateServer.js`) returns the current Redux-style
    store (`widgets`, `settings`, `screens`) as JSON.
  - Persists widget settings (position, visibility, screen assignment)
    to disk (`Settings.js`, `WidgetSettings.json`) and reloads them on
    boot.
  - A small `client.coffee` bundle (built separately, see below) runs
    *inside* the WKWebView: it connects back over WebSocket, requests
    each widget's bundle, runs `command` on `refreshFrequency` by
    POSTing to `/run/`, and re-renders via React on each response.

The Cocoa shell and the browser client both talk to the same server
over plain HTTP + WebSocket on `127.0.0.1`, guarded by `Host`/`Origin`
checks (`ensureSameHost.js`, `ensureSameOrigin.js`) rather than any
real authentication — it's a localhost-only, single-user tool.

## The widget authoring model

A widget is one `.jsx` (or legacy `.coffee`) file exporting a handful of
well-known bindings:

| Export | Purpose |
|---|---|
| `command` | Shell string (or a function that dispatches events) to run each refresh |
| `refreshFrequency` | Milliseconds between runs, or `false` to disable |
| `className` | CSS (object or string) positioning the widget, compiled via Emotion |
| `render(props)` | React render function |
| `updateState(event, prevState)` | Redux-style reducer from command output to render props |
| `initialState` | Starting state before the first command run |

Files under any `node_modules`, `lib`, or `src` directory are treated as
shared modules rather than standalone widgets. See the root
[`README.md`](../README.md) for the full API and
[`ClassicWidgets.md`](../ClassicWidgets.md) for the older CoffeeScript
widget format still supported for backward compatibility.

## Build & tooling notes

- The Cocoa app is built with Xcode; CocoaPods dependencies
  (`SocketRocket` for WebSockets from the native side, `Sparkle` for
  updates) are vendored directly under `Pods/` in this checkout rather
  than resolved via a `.xcworkspace` + `pod install`.
- The Node backend is bundled for distribution via `browserify`
  (`npm run release` in `server/`), and that release build is what
  Xcode embeds into the app bundle's `Resources/` as `server.js` plus
  a matching `node-arm64`/`node-x64` binary.
- Both halves can be exercised independently of a full Xcode build —
  see [`.claude/skills/run-uebersicht/SKILL.md`](../.claude/skills/run-uebersicht/SKILL.md)
  for a from-source build/run/screenshot workflow for both the server
  and the native app, plus a written-up list of the non-obvious traps
  (code signing, CocoaPods without a workspace, Unicode normalization
  in `Übersicht`'s own name tripping up shell scripts, etc.) hit while
  building that tooling.

## Known issues

- **"Widgets Folder" popup in Preferences doesn't persist on recent
  macOS (reported on macOS 16 "Tahoe" / Darwin 25, app build 82,
  compiled against an older SDK).** Picking a folder from the
  "Widgets Folder:" popup button appears to do nothing: the embedded
  server never starts and "Open Widgets Folder" in the menu bar is a
  no-op. In this checkout's source, the picked path is meant to be
  written to `NSUserDefaults` under the key **`widgetDirectory`**, as
  an `NSKeyedArchiver`-archived `NSURL` (`UBPreferencesController.m`,
  `setWidgetDir:` / `widgetDir`) — plausibly the `_popUpItemAction:`
  handler that's supposed to call `setWidgetDir:` silently fails to
  fire or persist on newer macOS versions.

  A workaround reported for this: fully quit and relaunch the app
  (`killall Übersicht && open /Applications/Übersicht.app`), which
  falls back to the *registered default* widget directory
  (`~/Library/Application Support/Übersicht/widgets`, set via
  `registerDefaults` in `UBPreferencesController`'s init) rather than
  whatever was picked in the popup. A `defaults write` command has
  also been floated as a fix, but note it needs to target the
  **`widgetDirectory`** key with archived `NSURL` data to match what
  this code actually reads — a plain-string write to a differently
  named key (e.g. `widgetDir`) isn't read by any code path here, so
  if that appeared to work, the restart (and its fallback to the
  registered default) was very likely doing the actual work, not the
  `defaults write` itself. Not yet root-caused or fixed upstream.
