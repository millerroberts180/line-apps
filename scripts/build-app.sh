#!/bin/zsh
# Builds "Line Apps.app" into build/: a stripped universal release build for Apple silicon and Intel.
#
#   scripts/build-app.sh                      ad hoc signed
#   LINE_SIGN_IDENTITY="Developer ID Application: …" scripts/build-app.sh
#   LINE_ARCHS=arm64 scripts/build-app.sh     one architecture, quicker
set -euo pipefail

root="${0:A:h:h}"
cd "$root"

archs=(${=LINE_ARCHS:-arm64 x86_64})
slices=()
for arch in $archs; do
  swift build -c release --triple "$arch-apple-macosx14.0" --scratch-path ".build/$arch"
  slices+=(".build/$arch/release/LineApps")
done

app="build/Line Apps.app"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp Resources/Info.plist "$app/Contents/Info.plist"
cp Resources/AppIcon.icns "$app/Contents/Resources/AppIcon.icns"
lipo -create "${slices[@]}" -output "$app/Contents/MacOS/LineApps"
# Local symbols are only for debugging.
strip -x "$app/Contents/MacOS/LineApps"

if [[ -n ${LINE_SIGN_IDENTITY:-} ]]; then
  # A Developer ID signature needs a secure timestamp to be notarized.
  codesign --force --options runtime --timestamp --sign "$LINE_SIGN_IDENTITY" "$app"
else
  codesign --force --options runtime --sign - "$app"
fi

echo "Built $app ($(du -sh "$app" | cut -f1), $(lipo -archs "$app/Contents/MacOS/LineApps"))"
