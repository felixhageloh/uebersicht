#!/bin/bash
# Server-only smoke test for the Übersicht Node/CoffeeScript backend (server/).
# Launches server/server.coffee against a throwaway widget+settings dir,
# drives it purely with curl (the same requests client.js issues from the
# browser), and asserts a full widget round trip: bundle -> state -> run.
#
# Usage: .claude/skills/run-uebersicht/smoke.sh [port]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SERVER_DIR="$ROOT/server"
PORT="${1:-41426}"
BASE="http://127.0.0.1:$PORT"

SCRATCH="$(mktemp -d)"
mkdir -p "$SCRATCH/widgets" "$SCRATCH/settings"
# `$!` below is only the subshell that execs coffee; it does not forward
# signals to the node process it spawns (which ends up reparented to
# launchd). Killing the port's listener is what actually frees it.
trap 'lsof -ti:"$PORT" -sTCP:LISTEN | xargs -r kill 2>/dev/null || true; rm -rf "$SCRATCH"' EXIT

cat > "$SCRATCH/widgets/smoke.jsx" <<'EOF'
export const command = "echo smoke-test-output";
export const refreshFrequency = false;
export const render = ({ output }) => <div id="smoke">{output}</div>;
EOF

echo "== starting server on port $PORT =="
( cd "$SERVER_DIR" && node_modules/.bin/coffee server.coffee -d "$SCRATCH/widgets" -p "$PORT" -s "$SCRATCH/settings" ) \
  > "$SCRATCH/server.log" 2>&1 &

for i in $(seq 1 30); do
  curl -sf -H "Connection: close" "$BASE/" > /dev/null 2>&1 && break
  sleep 0.5
  if [ "$i" -eq 30 ]; then
    echo "server never came up; log:"; cat "$SCRATCH/server.log"; exit 1
  fi
done

echo "== GET / serves the shell =="
curl -sf -H "Connection: close" "$BASE/" | grep -q "Übersicht" || { echo "FAIL: index missing title"; exit 1; }

echo "== GET /state/ lists the widget =="
curl -sf -H "Connection: close" "$BASE/state/" | grep -q "smoke-jsx" || { echo "FAIL: widget not in state"; exit 1; }

echo "== POST /run/ executes the widget command (needs Origin header) =="
OUT="$(curl -sf -H "Connection: close" -X POST "$BASE/run/" -H "Origin: $BASE" -d "echo smoke-test-output")"
[ "$OUT" = "smoke-test-output" ] || { echo "FAIL: got '$OUT'"; exit 1; }

echo "== POST /run/ without Origin is rejected (403) =="
CODE="$(curl -s -H "Connection: close" -o /dev/null -w '%{http_code}' -X POST "$BASE/run/" -d "echo nope")"
[ "$CODE" = "403" ] || { echo "FAIL: expected 403, got $CODE"; exit 1; }

echo "== file watcher picks up edits (hot reload) =="
sleep 1.1  # mtime resolution
cat > "$SCRATCH/widgets/smoke.jsx" <<'EOF'
export const command = "echo smoke-test-updated";
export const refreshFrequency = false;
export const render = ({ output }) => <div id="smoke">{output}</div>;
EOF
NEW_MTIME=""
for i in $(seq 1 20); do
  NEW_MTIME="$(curl -sf -H "Connection: close" "$BASE/state/" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{console.log(JSON.parse(d).widgets['smoke-jsx'].mtime)}catch(e){}})")"
  [ -n "$NEW_MTIME" ] && break
  sleep 0.3
done
echo "smoke-jsx mtime now: $NEW_MTIME"

echo
echo "ALL PASSED"
