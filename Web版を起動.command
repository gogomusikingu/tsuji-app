#!/bin/sh
# Double-click in Finder to open the web version in the browser (test mode: 10-second wait between draws).
COOLDOWN=10 exec "$(dirname "$0")/tools/run_web.sh"
