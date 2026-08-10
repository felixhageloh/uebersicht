#!/bin/bash
# Build and drive the native macOS Übersicht.app (Cocoa shell + embedded
# Node server) from source, headless-CI style (no Xcode GUI, no Apple
# Development signing identity).
#
# Usage:
#   native-driver.sh build                 # build Übersicht.app via xcodebuild
#   native-driver.sh screenshot [outdir]    # launch it, screenshot it, quit it
#
# See SKILL.md before running `screenshot` — it replaces any already-running
# copy of the app on your real desktop for a few seconds (same bundle ID).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CMD="${1:-}"

build_settings() {
  xcodebuild -project "$ROOT/Uebersicht.xcodeproj" -scheme Uebersicht \
    -configuration Debug -showBuildSettings 2>/dev/null
}

app_path() {
  local build_dir
  build_dir="$(build_settings | awk -F ' = ' '/CONFIGURATION_BUILD_DIR/{print $2; exit}')"
  echo "$build_dir/Übersicht.app"
}

do_build() {
  local symroot
  symroot="$(build_settings | awk -F ' = ' '/^[[:space:]]*SYMROOT /{print $2; exit}')"

  echo "== building Pods (SocketRocket, Pods-Uebersicht) into $symroot =="
  # Pods.xcodeproj has its own SYMROOT (a workspace-relative ../build
  # folder from the CocoaPods template); this repo has no .xcworkspace
  # (it's gitignored and `pod` isn't installed here), so the main
  # project's linker never finds Pods output unless we force both to
  # share the same SYMROOT explicitly.
  xcodebuild -project "$ROOT/Pods/Pods.xcodeproj" -scheme SocketRocket \
    -configuration Debug -destination "platform=macOS" \
    CODE_SIGNING_ALLOWED=NO SYMROOT="$symroot" build
  xcodebuild -project "$ROOT/Pods/Pods.xcodeproj" -scheme Pods-Uebersicht \
    -configuration Debug -destination "platform=macOS" \
    CODE_SIGNING_ALLOWED=NO SYMROOT="$symroot" build

  echo "== building Uebersicht =="
  # CODE_SIGN_IDENTITY="" (not just CODE_SIGNING_ALLOWED=NO) matters: a
  # custom "Run Script" build phase reads ${CODE_SIGN_IDENTITY} directly
  # and, if non-empty, tries to codesign with it even when Xcode's own
  # signing step is disabled. Forcing it empty makes that script fall
  # back to ad-hoc ("-").
  xcodebuild -project "$ROOT/Uebersicht.xcodeproj" -scheme Uebersicht \
    -configuration Debug -destination "platform=macOS" \
    CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY="" build

  local app; app="$(app_path)"
  echo "== fixing up code signing on embedded node binaries =="
  # The Run Script phase above ad-hoc-signs node-arm64/node-x64/fsevents.node
  # WITH hardened runtime (-o runtime). Hardened runtime turns on library
  # validation, and fsevents.node's own signature (or lack of one) doesn't
  # have a matching Team ID, so node's dlopen("fsevents.node") fails with
  # "different Team IDs" and the embedded server never starts. Re-sign
  # ad hoc *without* hardened runtime so validation is skipped entirely.
  # (Apple Silicon requires *some* signature to exec at all -- a plain
  # --remove-signature makes node-arm64 get SIGKILLed on launch.)
  #
  # `codesign` immediately after Xcode's own build-phase signing
  # sometimes hits "internal error in Code Signing subsystem" on the
  # ~80MB node-x64 binary -- a transient securityd contention, not
  # anything wrong with the file (a delayed retry always succeeds).
  codesign_retry() {
    local file="$1" i
    for i in 1 2 3 4 5; do
      codesign --force --sign - "$file" 2>&1 && return 0
      echo "  codesign attempt $i failed, retrying..." >&2
      sleep 2
    done
    return 1
  }
  codesign_retry "$app/Contents/Resources/node-arm64"
  [ -f "$app/Contents/Resources/node-x64" ] && \
    codesign_retry "$app/Contents/Resources/node-x64"
  codesign_retry "$app/Contents/Resources/node_modules/fsevents/fsevents.node"

  echo "== built: $app =="
}

do_screenshot() {
  local outdir="${1:-$SKILL_DIR/screenshots}"
  mkdir -p "$outdir"
  local app; app="$(app_path)"
  [ -d "$app" ] || { echo "not built yet -- run: $0 build" >&2; exit 1; }

  # macOS filesystem paths come back NFD-decomposed ("U" + combining
  # diaeresis, 3 bytes) while the literal "Ü" typed into this script is
  # NFC-precomposed (1 codepoint, 2 bytes) -- byte-identical text that
  # silently fails to grep-match. Route `ps` output through `iconv
  # -f UTF-8-MAC` (NFD -> NFC) before matching against literal "Übersicht".
  #
  # awk (not grep -F) deliberately: `ps ax` also lists the very grep
  # process this function would spawn, and its argv ("grep -F
  # /Übersicht.app/...") contains the search string as a literal
  # substring -- classic "ps | grep pattern matches itself". Requiring
  # the command's *first* token to itself be the absolute path (real
  # launches have no argv) excludes it; grep's first token is "-F".
  running_uebersicht() {
    ps ax -o pid=,command= | iconv -f UTF-8-MAC -t UTF-8 \
      | awk '$2 ~ /^\/.*\/Übersicht\.app\/Contents\/MacOS\/Übersicht$/'
  }

  # Every copy of this app shares bundle ID tracesOf.Uebersicht (this
  # build, any /Applications install, ...), and it turns out `open`ing a
  # second copy leaves the situation undefined -- sometimes it replaces
  # the running one, sometimes both end up alive with one holding stale
  # (frozen) windows and a dead embedded server. So: explicitly kill
  # *every* running copy first (remembering their bundle paths), launch
  # only ours, and restore the others via a trap that fires even if this
  # script fails partway through -- never leave the desktop worse off.
  # (Deliberately not `local`: referenced by the `restore` trap below,
  # which bash still runs after this function returns -- by then any
  # `local` here would already be out of scope.)
  prior_apps=()
  while read -r pid path; do
    [ -n "$pid" ] || continue
    prior_apps+=("${path%/Contents/MacOS/Übersicht}")
    kill -9 "$pid" 2>/dev/null || true
  done < <(running_uebersicht || true)
  [ "${#prior_apps[@]}" -gt 0 ] && sleep 1  # let old server children die too

  our_pid=""
  restore() {
    [ -n "$our_pid" ] && kill -9 "$our_pid" 2>/dev/null || true
    for p in "${prior_apps[@]:-}"; do
      [ -n "$p" ] && open -a "$p"
    done
  }
  trap restore EXIT

  echo "== launching $app =="
  open "$app"
  # Exact equality (not a substring grep) on purpose -- avoids the same
  # self-match trap as above.
  for i in $(seq 1 20); do
    our_pid="$(running_uebersicht | awk -v want="$app/Contents/MacOS/Übersicht" '$2 == want {print $1; exit}')"
    [ -n "$our_pid" ] && break
    sleep 0.5
  done
  [ -n "$our_pid" ] || { echo "app never started" >&2; exit 1; }

  # The Cocoa process (and its windows) exist well before the embedded
  # Node server has answered /state/ and the WebView has actually
  # rendered widget content -- an early screenshot is 5 windows of 0x0 or
  # blank. Wait for real content: multiple windows with non-zero bounds.
  echo "== waiting for its windows to render (pid $our_pid) =="
  local windows=""
  for i in $(seq 1 40); do
    windows="$(swift "$SKILL_DIR/list-windows.swift" "$our_pid" 2>/dev/null || true)"
    local nonzero; nonzero="$(echo "$windows" | grep -cv '"Width": 0' || true)"
    [ "$nonzero" -ge 2 ] && break
    sleep 0.5
  done
  [ -n "$windows" ] || { echo "no windows appeared" >&2; exit 1; }
  echo "$windows"

  echo "== screenshotting each non-empty window (screencapture -l<id> ignores stacking order) =="
  local n=0
  while read -r id _; do
    [ -n "$id" ] || continue
    n=$((n + 1))
    screencapture -x -l"$id" "$outdir/window-$id.png" 2>/dev/null || true
  done < <(echo "$windows" | grep -v '"Width": 0')
  echo "== $n screenshot(s) written to $outdir =="
  # `restore` (quit ours, relaunch any prior copies) runs automatically via the EXIT trap.
}

case "$CMD" in
  build) do_build ;;
  screenshot) do_screenshot "${2:-}" ;;
  *) echo "usage: $0 {build|screenshot [outdir]}" >&2; exit 1 ;;
esac
