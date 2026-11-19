#!/bin/sh
# Runs the Swift Testing suite. With only the Command Line Tools installed, SwiftPM can't
# find Testing.framework on its own, so point the compiler and linker at the copy the
# tools ship. With Xcode selected, plain `swift test` works and this adds nothing.
set -eu
cd "$(dirname "$0")/.."
FRAMEWORKS="$(xcode-select -p)/Library/Developer/Frameworks"
if [ -d "$FRAMEWORKS/Testing.framework" ] && ! xcode-select -p | grep -q Xcode; then
    exec swift test -Xswiftc -F"$FRAMEWORKS" -Xlinker -F"$FRAMEWORKS" -Xlinker -rpath -Xlinker "$FRAMEWORKS" "$@"
fi
exec swift test "$@"
