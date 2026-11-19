#!/bin/zsh
# Builds the Line Apps bundle, dist/Line-Apps-<version>.pkg: one installer that puts Line Apps, Tuck,
# Pulse, Hum and Glow in /Applications, for Apple silicon Macs on macOS 14 or later. Hum needs macOS 15,
# so before it the installer leaves Hum out. Each app is built by its own repository's script and
# stamped with its version as its own release is, so an app from the bundle is the app from its own
# download.
#
#   scripts/build-bundle.sh [version]     Tuck, Pulse and Glow signed with their local identities if
#                                         this Mac has them, the rest ad hoc, the installer unsigned;
#                                         the version is Line Apps' own (Resources/Info.plist) unless
#                                         given
#   LINE_SIGN_IDENTITY="Developer ID Application: …" \
#   LINE_INSTALLER_IDENTITY="Developer ID Installer: …" \
#   LINE_NOTARY_PROFILE=line-notary scripts/build-bundle.sh
#                                         the apps and installer signed, the installer notarized and
#                                         stapled
#
# The other repositories are checked out beside this one, under their GitHub names: ../tuck, ../pulse,
# ../hum and ../glow. TUCK_REPO, PULSE_REPO, HUM_REPO and GLOW_REPO point elsewhere.
set -euo pipefail

root="${0:A:h:h}"

# A checkout from its variable, or beside this one; a relative path is from where the script was run.
checkout() { # checkout NAME
  local variable="${(U)1}_REPO"
  local repo="${(P)variable:-${root:h}/$1}"
  [[ -e $repo/.git ]] || { echo "error: no $1 checkout at $repo; clone it there or set $variable" >&2; return 1; }
  print -r -- "${repo:A}"
}
tuck="$(checkout tuck)"
pulse="$(checkout pulse)"
hum="$(checkout hum)"
glow="$(checkout glow)"

cd "$root"

version="${1:-$(plutil -extract CFBundleShortVersionString raw Resources/Info.plist)}"
version_form='^[0-9]+(\.[0-9]+){0,2}$'
[[ $version =~ $version_form ]] || { echo "error: the version must look like 1.0.0, not '$version'" >&2; exit 64; }

identity="${LINE_SIGN_IDENTITY:-}"
installer_identity="${LINE_INSTALLER_IDENTITY:-}"
profile="${LINE_NOTARY_PROFILE:-}"
if [[ -n $profile && ( -z $identity || -z $installer_identity ) ]]; then
  echo "error: notarizing needs LINE_SIGN_IDENTITY and LINE_INSTALLER_IDENTITY too" >&2
  exit 64
fi

work="$(mktemp -d -t line-apps-bundle)"
trap 'rm -rf "$work"' EXIT
apps="$work/apps"
mkdir -p "$apps"

# A build number as the apps' own releases make one: the UTC date and time, then the commit count.
build_number() {
  local now="$(date -u +%Y%m%d.%H%M%S)"
  echo "${now%.*}.$((10#${now#*.})).$(git -C "$1" rev-list --count HEAD 2>/dev/null || echo 0)"
}
stamp() { # stamp APP VERSION BUILD
  plutil -replace CFBundleShortVersionString -string "$2" "$1/Contents/Info.plist"
  plutil -replace CFBundleVersion -string "$3" "$1/Contents/Info.plist"
}
info() { plutil -extract "$2" raw "$1/Contents/Info.plist"; }

# MARK: Build

# Every app for Apple silicon only, as the installer is. Each script signs what it builds; all are signed
# again below, once stamped.
echo "Building Tuck…"
(cd "$tuck" && scripts/build-app.sh release "$apps/Tuck.app" arm64)
stamp "$apps/Tuck.app" "$(tr -d '[:space:]' < "$tuck/VERSION")" "$(build_number "$tuck")"

echo "Building Pulse…"
(cd "$pulse" && PULSE_ARCHS=arm64 PULSE_SIGN_IDENTITY="" scripts/bundle.sh)
ditto "$pulse/build/Pulse.app" "$apps/Pulse.app"

echo "Building Hum…"
(cd "$hum" && HUM_ARCHS=arm64 HUM_APP_DIR="$apps" scripts/build-app.sh release)

echo "Building Glow…"
(cd "$glow" && GLOW_ARCHS=arm64 GLOW_CONFIGURATION=release GLOW_SIGN_IDENTITY="" scripts/bundle.sh "$apps/Glow.app")
stamp "$apps/Glow.app" "$(tr -d '[:space:]' < "$glow/VERSION")" "$(build_number "$glow")"

echo "Building Line Apps…"
LINE_ARCHS=arm64 LINE_SIGN_IDENTITY="" scripts/build-app.sh
ditto "build/Line Apps.app" "$apps/Line Apps.app"
stamp "$apps/Line Apps.app" "$version" "$(build_number "$root")"

# MARK: Sign

# Under the hardened runtime, with the Developer ID when there is one. Without it, Tuck, Pulse and Glow
# are signed with their own local identities when this Mac has them (each repository's
# scripts/signing-identity.sh makes one), as their own downloads are: macOS ties the Accessibility grant
# to the signature, so an app then keeps it across updates, whichever way it was installed. The rest are
# signed ad hoc. Hum's widget extension goes first, with its own entitlements, so the app's signature
# covers it.
sign() { # sign PATH [ENTITLEMENTS]
  local flags=(--force --options runtime) name="${${1:t}:r}"
  local keychain="$HOME/Library/Keychains/${(L)name}-signing.keychain-db"
  if [[ -n $identity ]]; then
    flags+=(--timestamp --sign "$identity")
  elif [[ $name == (Tuck|Pulse|Glow) && -f $keychain ]] \
      && security find-certificate -c "$name Local Signing" "$keychain" >/dev/null 2>&1; then
    security unlock-keychain -p "${(L)name}-local-signing" "$keychain"
    flags+=(--keychain "$keychain" --sign "$name Local Signing")
  else
    flags+=(--sign -)
  fi
  if [[ -n ${2:-} ]]; then flags+=(--entitlements "$2"); fi
  codesign $flags "$1"
}
sign "$apps/Hum.app/Contents/PlugIns/HumWidgets.appex" "$hum/Resources/HumWidgets/HumWidgets.entitlements"
sign "$apps/Hum.app" "$hum/Resources/Hum.entitlements"
for app in Tuck Pulse Glow "Line Apps"; do sign "$apps/$app.app"; done

# MARK: Package

# Line Apps opens as the installer finishes, for whoever is logged in, so its line is in the menu bar
# with its note. A copy already running is left as it is.
mkdir -p "$work/scripts"
cat > "$work/scripts/postinstall" <<'EOF'
#!/bin/sh
user="$(stat -f %Su /dev/console)"
[ -n "$user" ] && [ "$user" != root ] || exit 0
pgrep -qx LineApps && exit 0
launchctl asuser "$(id -u "$user")" sudo -u "$user" /usr/bin/open "$2/Line Apps.app" || true
exit 0
EOF
chmod 755 "$work/scripts/postinstall"

# One component per app, so each is a choice the installer can leave out.
typeset -A ids=("Line Apps" line Tuck tuck Pulse pulse Hum hum Glow glow)
order=("Line Apps" Tuck Pulse Hum Glow)
mkdir -p "$work/packages"
for app in $order; do
  id=${ids[$app]}
  stage="$work/stage/$id"
  mkdir -p "$stage"
  ditto "$apps/$app.app" "$stage/$app.app"
  plist="$work/$id.plist"
  pkgbuild --analyze --root "$stage" "$plist" >/dev/null
  # Always into /Applications: never moved onto a copy the installer finds elsewhere on the Mac, such as
  # one in Downloads. A newer copy already there is kept, which pkgbuild's own setting does.
  plutil -replace 0.BundleIsRelocatable -bool NO "$plist"
  scripts=()
  [[ $id == line ]] && scripts=(--scripts "$work/scripts")
  pkgbuild --quiet --root "$stage" --component-plist "$plist" --identifier "com.millerroberts.lineapps.bundle.$id" \
    --version "$(info "$apps/$app.app" CFBundleShortVersionString)" --install-location /Applications \
    $scripts "$work/packages/$id.pkg"
done

mkdir -p "$work/resources"
cat > "$work/resources/welcome.html" <<'EOF'
<!doctype html>
<html><body style="font: 13px -apple-system, sans-serif">
<p>This puts the Line Apps in your Applications folder: Tuck, Pulse, Hum and Glow, and Line Apps, the
short line in the menu bar that collapses their icons into it.</p>
<p>To leave any of them out, choose Customize on the next page. Hum needs macOS 15 or later, so on
macOS 14 it is left out.</p>
</body></html>
EOF
cat > "$work/resources/conclusion.html" <<'EOF'
<!doctype html>
<html><body style="font: 13px -apple-system, sans-serif">
<p>The line is in your menu bar. Click it to collapse Tuck, Pulse, Hum and Glow into it, and click again
to bring them back. Command-drag it to put it beside them.</p>
<p>Open the apps from your Applications folder. Each asks for what it needs the first time.</p>
</body></html>
EOF

choice() { # choice ID TITLE DESCRIPTION [ATTRIBUTES]
  print "    <choice id=\"$1\" title=\"$2\" description=\"$3\"${4:+ $4}>"
  print "        <pkg-ref id=\"com.millerroberts.lineapps.bundle.$1\"/>"
  print "    </choice>"
}
{
  print '<?xml version="1.0" encoding="utf-8"?>'
  print '<installer-gui-script minSpecVersion="2">'
  print '    <title>Line Apps</title>'
  print '    <welcome file="welcome.html" mime-type="text/html"/>'
  print '    <conclusion file="conclusion.html" mime-type="text/html"/>'
  print '    <options customize="allow" require-scripts="false" hostArchitectures="arm64"/>'
  print '    <domains enable_anywhere="false" enable_currentUserHome="false" enable_localSystem="true"/>'
  print '    <volume-check><allowed-os-versions><os-version min="14.0"/></allowed-os-versions></volume-check>'
  print '    <script>function humRuns() { return system.compareVersions(system.version.ProductVersion, "15.0") >= 0; }</script>'
  print '    <choices-outline>'
  for app in $order; do print "        <line choice=\"${ids[$app]}\"/>"; done
  print '    </choices-outline>'
  choice line "Line Apps" "The line in the menu bar. Click it and the others’ icons collapse into it; click again and they come back."
  choice tuck Tuck "Windows, files, links and notes, kept in your Mac’s notch."
  choice pulse Pulse "Feel web pages through your trackpad, and give typing a nicer sound."
  choice hum Hum "The song you’re playing, as album art in a small floating player. Needs macOS 15 or later." \
    'start_enabled="humRuns()" start_selected="humRuns()"'
  choice glow Glow "Brightness, volume and each monitor’s own settings, for every display."
  for app in $order; do
    id=${ids[$app]}
    print "    <pkg-ref id=\"com.millerroberts.lineapps.bundle.$id\" version=\"$(info "$apps/$app.app" CFBundleShortVersionString)\" onConclusion=\"none\">$id.pkg</pkg-ref>"
    # An app left running would be replaced under itself and keep running the old copy, so the
    # installer asks for it to be quit first.
    # Tuck was app.tuck.prototype until 2026-11-19, so a copy from before then is asked to quit too.
    closes="<app id=\"$(info "$apps/$app.app" CFBundleIdentifier)\"/>"
    [[ $id == tuck ]] && closes+='<app id="app.tuck.prototype"/>'
    print "    <pkg-ref id=\"com.millerroberts.lineapps.bundle.$id\"><must-close>$closes</must-close></pkg-ref>"
  done
  print '</installer-gui-script>'
} > "$work/distribution.xml"

mkdir -p dist
pkg="dist/Line-Apps-$version.pkg"
rm -f "$pkg" "$pkg.sha256"
signing=()
[[ -n $installer_identity ]] && signing=(--sign "$installer_identity" --timestamp)
productbuild --quiet --distribution "$work/distribution.xml" --resources "$work/resources" \
  --package-path "$work/packages" $signing "$pkg"

if [[ -n $profile ]]; then
  echo "Notarizing ${pkg:t}; Apple usually answers within a few minutes…"
  # Whatever notarytool's exit status, the status it reports is what counts.
  xcrun notarytool submit "$pkg" --keychain-profile "$profile" --wait --output-format json > "$work/notary.json" || true
  notary_status="$(plutil -extract status raw -o - "$work/notary.json" 2>/dev/null || echo "no answer")"
  [[ $notary_status == Accepted ]] || { echo "error: notarization ended as: $notary_status" >&2; cat "$work/notary.json" >&2; exit 1; }
  xcrun stapler staple "$pkg"
fi

# MARK: Check

# Checks run on what ships: each app as it is inside the installer.
pkgutil --expand-full "$pkg" "$work/check"
for app in $order; do
  shipped="$work/check/${ids[$app]}.pkg/Payload/$app.app"
  codesign --verify --deep --strict "$shipped"
  archs="$(lipo -archs "$shipped/Contents/MacOS/$(info "$shipped" CFBundleExecutable)")"
  [[ $archs == arm64 ]] || { echo "error: $app in the installer is built for $archs, not arm64 only" >&2; exit 1; }
  signer="$(codesign -dvv "$shipped" 2>&1 | sed -n 's/^Authority=//p' | head -1)"
  echo "  $app $(info "$shipped" CFBundleShortVersionString) ($(info "$shipped" CFBundleVersion)), $(info "$shipped" CFBundleIdentifier), signed ${signer:-ad hoc}"
done
[[ -x "$work/check/line.pkg/Scripts/postinstall" ]] || { echo "error: Line Apps' postinstall is missing" >&2; exit 1; }
closing="$(grep -c '<must-close>' "$work/check/Distribution" || true)"
[[ $closing == ${#order} ]] || { echo "error: the installer asks to close $closing apps, not ${#order}" >&2; exit 1; }

(cd dist && shasum -a 256 "${pkg:t}" > "${pkg:t}.sha256")
echo "Built $pkg ($(du -h "$pkg" | cut -f1))"
if [[ -z $installer_identity ]]; then
  echo "Unsigned: macOS asks before it opens the installer (System Settings › Privacy & Security › Open Anyway)."
fi
