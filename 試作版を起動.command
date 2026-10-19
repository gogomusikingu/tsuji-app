#!/bin/sh
# Double-click in Finder to launch the Mac prototype (test mode: 10-second wait between draws).
RANDOM_ORACLE_COOLDOWN=10 exec "$(dirname "$0")/tools/run_mac.sh"
