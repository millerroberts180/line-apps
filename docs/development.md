# Development

## Building

```sh
scripts/test.sh                  # the tests
scripts/build-app.sh             # build/Line Apps.app, universal, signed ad hoc
scripts/build-bundle.sh          # dist/Line-Apps-<version>.pkg and its .sha256
swift scripts/make-icon.swift    # Resources/AppIcon.icns, drawn in code
swift scripts/make-logo.swift    # design/logo/, the README's lockup, light and reversed
swift run LineApps --snapshot-mark docs/images   # the README's bend and the eleven-step sheet (debug)
```

You need Swift 6.1 or later; the Command Line Tools are enough. `LINE_ARCHS=arm64` builds one
architecture, and `LINE_SIGN_IDENTITY` signs with a Developer ID instead of ad hoc.

The README's picture of the bend is `--snapshot-mark`'s output, drawn off screen from the same code the
menu bar uses, so run it again whenever the line or the curl changes. It writes `bend-light.png` and
`bend-dark.png`, the line, the bend two thirds of the way and the curl at 14 times their menu-bar size,
and [`bend-steps-light.png`](images/bend-steps-light.png) and `bend-steps-dark.png`, the bend at eleven
steps, for checking the shapes between.

## The bundle

`build-bundle.sh` builds each app with its own repository's script, arm64 only, stamps each with its
version and build as its own release does, signs them, and makes one installer with a component per
app. It looks for the four repositories beside this one, cloned under their GitHub names:

```sh
git clone https://github.com/millerroberts180/tuck ../tuck
git clone https://github.com/millerroberts180/pulse ../pulse
git clone https://github.com/millerroberts180/hum ../hum
git clone https://github.com/millerroberts180/glow ../glow
```

`TUCK_REPO`, `PULSE_REPO`, `HUM_REPO` and `GLOW_REPO` point to a checkout elsewhere; if one is missing,
the script stops and names the variable to set. With `LINE_SIGN_IDENTITY`, `LINE_INSTALLER_IDENTITY`
and `LINE_NOTARY_PROFILE` it signs with a Developer ID and notarizes. Without them, Tuck, Pulse and
Glow are signed with their own local identities when this Mac has them (each repository's
`scripts/signing-identity.sh`), as their own downloads are, so each keeps its Accessibility grant across
updates however it was installed; Hum and Line Apps are signed ad hoc.

Everything goes into /Applications, never onto a copy found elsewhere, and a newer copy already there is
kept. Hum's component is offered only on macOS 15 or later. Line Apps' postinstall opens it for whoever
is logged in, so its line is in the menu bar with its note. The installer asks for any open app to be
quit before it replaces it, a Tuck from before its bundle ID changed included. Each app goes in whole,
as its own script built it, so everything in its Resources, its third-party notices included, ships as
in its own download.

The script checks what it built from inside the finished installer: each app's signature, that each is
arm64 only, Line Apps' postinstall, and that the installer asks to close all five apps.

## How the apps hear the line

The line posts a distributed notification, `com.millerroberts.lineapps.fold` or `.unfold`, with its
middle in screen points (`x`). Tuck, Pulse, Hum and Glow each have a copy of
[`Shared/LineAppsFold.swift`](../Shared/LineAppsFold.swift), which hides or shows the app's status item
to match. Change this copy first, then copy it into the four apps.

- Each icon waits a moment, longer the farther it sits from the line, then fades out (or in) over
  0.16 s. Reduce Motion skips the motion.
- macOS forgets a hidden status item's place and brings it back at the far left. The fold notes the
  place (`NSStatusItem Preferred Position <autosave name>`) as the icon goes and writes it back just
  before it shows, so each comes back where it was.
- The state is `folded` in Line Apps' defaults (`com.millerroberts.lineapps`). Apps read it at launch
  only while Line Apps runs, and while collapsed they watch for it quitting.
- Nothing runs between changes: three notification observers per app, and a fourth only while
  collapsed. The line's bend runs a display link only while it moves.

Decisions and what was checked: [decision-log.md](decision-log.md).
