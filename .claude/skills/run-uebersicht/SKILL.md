---
name: run-uebersicht
description: Build, run, and drive Übersicht, a macOS desktop widget engine. Use when asked to start the Übersicht server, run/build/screenshot the Übersicht.app macOS shell, test a widget-engine change in server/, or verify a widget renders correctly.
---

Übersicht is two things: a Node/CoffeeScript backend (`server/`) that
bundles and serves widgets over HTTP/WebSocket, and a native Cocoa shell
(`Uebersicht.xcodeproj`) that embeds that backend and draws the widgets
as borderless desktop windows. Most changes land in `server/src` — drive
that with `.claude/skills/run-uebersicht/smoke.sh`, a curl-only script
with no GUI dependency. The native shell is driven by
`.claude/skills/run-uebersicht/native-driver.sh`, which builds it via
`xcodebuild` and screenshots the real desktop windows — **read its
warning below before running the `screenshot` subcommand**, it
temporarily replaces any already-running copy of the app.

All paths below are relative to the repo root.

## Prerequisites

Xcode must have completed first-launch setup (only needed for the native
app path, not the server):

```bash
xcodebuild -checkFirstLaunchStatus   # exit 69 = not done yet
sudo xcodebuild -runFirstLaunch      # one-time, needs your password
```

No other system packages were needed on macOS 26 / Xcode 26.6 — Node 26
and the system `swift`/`screencapture`/`codesign` were already present.

## Setup

```bash
cd server && npm install --no-progress
```

`server/package.json` says it targets Node 8; Node 26 (this machine's
default) installs and runs it fine — nothing in setup needed pinning to
an old version.

## Run (agent path): server only

`smoke.sh` starts `server/server.js` against a throwaway widget +
settings directory, then drives it purely with `curl` — the same
requests the browser client (`client.js`) issues: fetch the widget
bundle, read `/state/`, `POST /run/` to execute the widget's shell
command, and confirm the file watcher picks up an edit. No browser, no
Xcode.

```bash
.claude/skills/run-uebersicht/smoke.sh [port]   # default port 41426
```

Exits 0 and prints `ALL PASSED` on success. It always cleans up its
server process and temp directories on exit, even on failure (via an
EXIT trap that kills the port's listener directly, which is robust
regardless of how the backgrounded `node server.js` ends up parented).

### Optional: visual proof in a real (headless) browser

`smoke.sh` never renders anything — it only proves the HTTP/WS contract.
To see the actual React-rendered widget, build the client bundle and load
it in headless Chromium (verified with the `playwright` npm package,
Chromium already cached under `~/Library/Caches/ms-playwright` on this
machine):

```bash
cd server && npm run build-client   # writes release/public/client.js (gitignored, not built by default)
node server.js -d /path/to/widgets -p 41426 -s /path/to/settings &
```

```js
// scratch.mjs -- npm install playwright in a scratch dir first
import { chromium } from 'playwright';
const browser = await chromium.launch();
const page = await browser.newPage();
page.on('pageerror', (e) => console.log('ERROR', e));
await page.goto('http://127.0.0.1:41426/', { waitUntil: 'networkidle' });
await page.screenshot({ path: '/tmp/shot.png' });
console.log(await page.evaluate(() => document.getElementById('uebersicht').innerHTML));
await browser.close();
```

## Run (native macOS app)

**Read this before running `screenshot`.** Every build of this app —
this one, any copy in `/Applications` — shares the same bundle ID
(`tracesOf.Uebersicht`), the same widget directory, and the same
settings file. Launching a second copy does not run alongside an
existing one; it leaves things in an undefined state (sometimes it
replaces the running copy, sometimes both end up alive with one showing
frozen, stale content). `native-driver.sh screenshot` handles this by
force-killing *every* running copy first and relaunching whichever ones
it killed once it's done, via an EXIT trap so this happens even if the
script fails partway through — but that still means a few seconds where
whatever the user normally sees on their desktop is replaced by this
build. **Confirm with the user before running it**, the same way you'd
confirm before any action that touches their live environment.

```bash
.claude/skills/run-uebersicht/native-driver.sh build
.claude/skills/run-uebersicht/native-driver.sh screenshot [outdir]   # default outdir: skill dir/screenshots/
```

`build` runs `xcodebuild` three times (Pods' `SocketRocket`, Pods'
`Pods-Uebersicht`, then the main `Uebersicht` scheme — see Gotchas for
why) and re-signs the embedded node binaries. `screenshot` launches the
built app, waits for its windows to actually render (not just appear —
see Gotchas), captures one PNG per window via `screencapture -l<id>`
(which renders a window's content directly regardless of what else is
on screen — desktop-level windows don't show up in a normal full-screen
capture), then quits it and restores whatever was running before.

## Test

```bash
cd server && npm run test-local
```

Bundling, command-server, and run-command suites all pass. It crashes
(exit 1, uncaught `ECONNRESET`) partway through the "using a login
shell" suite on Node 26 — a pre-existing incompatibility with this old
`tape`/`sinon` stack on a modern Node, not something this skill's driver
triggers or fixes.

---

- **Rapid successive requests on a kept-alive connection occasionally
  get "empty reply from server".** Same family of issue as the
  `ECONNRESET` in `npm test` above — `server.js` sets
  `keepAliveTimeout = 35000` but something in the request sequence
  (particularly right after `/run/`, which spawns a `bash` child per
  request) occasionally resets the connection under Node 26. `curl -H
  "Connection: close"` on every request sidesteps it entirely;
  `smoke.sh` does this and was reliable across 5+ back-to-back runs.
  Without it, expect an occasional (not majority) flake.

## Gotchas

- **No `.xcworkspace` and `pod` isn't installed.** `Pods/` is committed
  to the repo directly (unusual, but that's how this checkout has it),
  so `xcodebuild -project Uebersicht.xcodeproj` alone links against
  nothing from Pods. `Pods.xcodeproj` has its own `SYMROOT` (a
  `$(SRCROOT)/../build` CocoaPods-template default) that doesn't match
  the main project's DerivedData `SYMROOT`, so even building
  `Pods.xcodeproj` separately isn't enough — its output lands somewhere
  the main project's linker never looks. `native-driver.sh` reads the
  main project's real `SYMROOT` via `-showBuildSettings` and passes it
  explicitly to both Pods builds (`SocketRocket`, then
  `Pods-Uebersicht`) so all three share one output directory.

- **A custom "Run Script" build phase codesigns unconditionally.** It
  reads `${CODE_SIGN_IDENTITY}` directly and, if non-empty, signs with
  it — `CODE_SIGNING_ALLOWED=NO` alone doesn't stop this (that only
  disables Xcode's *own* signing step). It resolves to the literal
  string `"Apple Development"` by default, which fails with `Apple
  Development: no identity found` since no such identity exists here.
  Fix: also pass `CODE_SIGN_IDENTITY=""` so the script's own fallback to
  ad-hoc (`"-"`) kicks in.

- **Ad-hoc signing with hardened runtime breaks `fsevents.node`.** That
  same Run Script phase signs `node-arm64`/`node-x64`/`fsevents.node`
  with `-o runtime` (hardened runtime), which turns on library
  validation. `fsevents.node`'s own signature doesn't carry a matching
  Team ID, so node's `dlopen("fsevents.node")` fails with `"different
  Team IDs"` and the embedded server silently never starts (the Cocoa
  shell just retries `startUp` once — see below — leaving a running app
  with no server and no rendered widgets, no crash, no obvious error
  unless you check `log show --predicate 'processID == <pid>'`). Fix:
  re-sign those three files ad hoc *without* `-o runtime` after build.
  You can't just strip the signature entirely instead — Apple Silicon
  requires *some* signature to exec at all; an unsigned `node-arm64`
  gets SIGKILLed immediately on launch. `native-driver.sh build` does
  this re-signing automatically as its last step.

- **`codesign` on the ~80MB `node-x64` binary intermittently fails with
  `"internal error in Code Signing subsystem"`** when run immediately
  after Xcode's own build-phase signing just touched the same file --
  a transient `securityd` contention, not a real problem with the file
  (a delayed retry always succeeds). `native-driver.sh build` retries
  each `codesign` call up to 5 times with a 2s delay.

- **The app doesn't actually retry across ports the way it looks like it
  should.** `UBAppDelegate.m`'s `handleExit` block calls `[self
  shutdown]` (no keep-alive) on *any* task exit before checking whether
  to retry with an incremented `portOffset` — and `shutdown` (no
  argument) always sets `keepServerAlive = NO`. In practice this means:
  if the embedded server ever exits for any reason (port conflict,
  crash, you killing it), the app does not come back on its own even
  though the code looks like it's built to. If you need a clean
  instance, fully quit and relaunch it rather than waiting.

- **`ps ax` paths are NFD-decomposed; a literal "Ü" typed into a script
  is NFC.** `git`'s own README already flags umlaut issues in this repo
  for a related reason. Concretely: the filesystem reports
  `/Applications/Übersicht.app/...` with "U" + a combining diaeresis
  (`0x55 0xCC 0x88`), while a plain `"Übersicht"` string written into a
  shell script is one precomposed codepoint (`0xC3 0x9C`). Byte-for-byte
  different, renders identically, silently fails to `grep`/`pgrep -f`
  match. Fix: pipe `ps` output through `iconv -f UTF-8-MAC -t UTF-8`
  (NFD → NFC) before matching. `native-driver.sh` and
  `list-windows.swift` both do this.

- **`ps ax | grep <pattern>` can match its own `grep` process.** Once
  the NFD/NFC issue above is fixed, the literal target path can appear
  as a *substring of the grep invocation's own argv* in the same `ps`
  snapshot (classic "grep matches itself", sharper here because the
  match text is unusually long and specific). `native-driver.sh` uses
  `awk` with an anchored/exact check on the command's first token
  instead of `grep -F`, since a real launch has no extra argv (`grep`'s
  own first token is `-F`, never a path).

- **Desktop-level windows don't show up in `screencapture -x` (full
  screen).** Übersicht draws at very low `kCGWindowLevel` values
  (negative layers, below normal app windows), so whatever's in the
  foreground (an editor, a browser) fully occludes them in a normal
  screenshot even though they're "on screen". `screencapture -l<id>`
  (a specific window ID from `list-windows.swift`) renders that window's
  content directly, ignoring stacking order.

- **A freshly-launched window can exist with zero size before it has
  rendered anything.** The Cocoa process and its `NSWindow`s appear
  before the embedded server has answered `/state/` and the WebView has
  painted. `native-driver.sh` polls until at least two windows report
  non-zero bounds rather than screenshotting the first thing it sees.

## Troubleshooting

- **`xcodebuild -list` fails with `DVTPlugInLoading` /
  `IDESimulatorFoundation` / `DVTDownloads.framework` errors**: Xcode's
  first-launch setup was never completed on this machine.
  `xcodebuild -checkFirstLaunchStatus` exits 69; fix with
  `sudo xcodebuild -runFirstLaunch` (prompts for password, one-time).

- **`ld: library 'SocketRocket' not found` / `ld: library
  'Pods-Uebersicht' not found`**: the main scheme was built without
  first building the matching Pods targets into the same `SYMROOT` — see
  the "no `.xcworkspace`" gotcha above. Run `native-driver.sh build`
  (or its three `xcodebuild` invocations in order) rather than building
  the main scheme alone.

- **`Apple Development: no identity found` during a "Run Script" build
  phase**: pass `CODE_SIGN_IDENTITY=""` in addition to
  `CODE_SIGNING_ALLOWED=NO`.

- **App launches, no crash, but no widgets ever render and
  `curl 127.0.0.1:41416/` doesn't respond**: the embedded server died on
  a `dlopen` Team ID mismatch for `fsevents.node` — see the hardened
  runtime gotcha. Check with
  `log show --predicate 'processID == <pid>' --last 2m | grep "different Team IDs"`.
  Re-sign as `native-driver.sh build` does.

- **`EADDRINUSE` running `node server.js` standalone on the
  default port**: a real installed Übersicht.app is very likely already
  running and bound to `41416` — pass a different `-p` (that's why
  `smoke.sh` defaults to `41426`).
