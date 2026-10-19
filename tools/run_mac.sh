#!/bin/sh
# Build and launch the Mac prototype with Command Line Tools only (no Xcode).
# The macOS 27 SDK needs Xcode's SwiftUI macro plugins, so build against the macOS 26 SDK.
# Optional: RANDOM_ORACLE_COOLDOWN=<seconds> overrides the 1-hour wait between draws.
set -e
cd "$(dirname "$0")/.."
export SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk
swift build --scratch-path .build/sdk26
exec .build/sdk26/out/Products/Debug/RandomOracle
