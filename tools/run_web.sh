#!/bin/sh
# Build the web version's data (first time only) and serve it at http://localhost:8765/.
# Optional: COOLDOWN=<seconds> opens the page with a short wait between draws, for testing.
set -e
cd "$(dirname "$0")/.."
if [ ! -f web/data/index.json ] || [ ! -f web/fonts/verse.woff2 ]; then
  [ -x tools/.venv/bin/python ] || { python3 -m venv tools/.venv && tools/.venv/bin/pip install -q fonttools brotli; }
  tools/.venv/bin/python tools/build_web.py
fi
URL="http://localhost:8765/${COOLDOWN:+?cooldown=$COOLDOWN}"
(sleep 1 && open "$URL") &
echo "Serving $URL  (Ctrl+C to stop)"
exec python3 -m http.server 8765 --bind 127.0.0.1 --directory web
