# Decision log

Newest first. Each entry records what was decided, why, what was checked, and what is deferred. Entries
are not rewritten: when a later decision changes one, a **Superseded** (or **Superseded in part**) note
at the top of the earlier entry says what changed and names the entry that changed it.

## 2026-11-19: The bundle finds the apps beside it, and the bend is drawn to read at 820

- **Decision:**
  - **`build-bundle.sh`** looks for the four repositories beside this one, under their GitHub names
    (`../tuck`, `../pulse`, `../hum`, `../glow`), where it had looked in folders only my Mac has.
    `TUCK_REPO`, `PULSE_REPO`, `HUM_REPO` and `GLOW_REPO` still point elsewhere, and a missing checkout
    stops the script with the variable to set.
  - **The README's picture** is three moments of the bend, the line, two thirds of the way and the curl,
    at 14 times their menu-bar size. The eleven steps in a row came out about 45 px high at the README's
    820, and the shapes between read as squiggles. `--snapshot-mark` still draws the eleven steps, as
    `bend-steps-*.png`, for checking by eye.
- **Why:** anyone who clones the repositories should be able to build the bundle without editing the
  script, and the first picture should show the line and the curl clearly.
- **Checked:** the script with each checkout missing in turn, and with a relative override, stopped
  before building and named the right variable; with all four found it resolved `../pulse` to Pulse,
  since the Mac's disk ignores case. The steps sheet is byte for byte the old picture. Each app goes
  into the installer whole: an app with `THIRD_PARTY_NOTICES.md` in Resources, taken through the
  script's stamp, signing, `ditto` and `pkgbuild`, still had it after `pkgutil --expand-full`, with a
  valid signature. Line Apps adapts no open-source code, so it has no notices of its own.

## 2026-11-19: The README in the family's layout, with a lockup drawn as theirs are

- **Decision:**
  - **The README** follows the layout Tuck's, Pulse's, Hum's and Glow's share: a lockup, the tagline
    "One line for all four.", the meta line, the bend as the picture, then What it does, Install,
    Private and light, Requirements, Build from source, Documentation, The apps and Licence. Building
    the bundle and how the apps hear the line moved to `docs/development.md`.
  - **The lockup**, from `scripts/make-logo.swift`: the curl beside "line apps" on the family's 256
    grid, all one 24-unit round-capped line. The letters are Glow's and Pulse's; the i's dot is the line
    at no length, and the words' facing lines are 110 apart, against 50 between letters. The curl spans
    x 28-228 as Pulse's and Hum's lines do, where the website's 4.5 stroke comes out at the family's
    24, and carries the icon's gradient.
  - **The installer's components** describe each app in the words the four READMEs use.
- **Why:** the hub should read as one of the family: the same page, and a wordmark drawn the same way.
- **Checked:** the lockup drawn by AppKit beside Pulse's, Hum's and Glow's, light and reversed, at full
  size and at the README's 64 px; the bend images byte for byte against a fresh `--snapshot-mark`; the
  first-run note drawn off screen, light and dark, against what the line does; every relative link and
  image path in the README and docs.

## 2026-11-13: The installer asks to quit the apps it replaces

- **Decision:** the installer lists each of its five apps under `must-close`, so Installer asks for any
  that is open to be quit before it installs.
- **Why:** without it, Installer replaced an open app's files under it: the app kept running the old
  copy until next opened, with no sign that anything had changed. Tuck, open on my Mac, was the case that
  showed it.
- **Checked:** `build-bundle.sh` now fails unless the shipped Distribution has five `must-close` lists.
  On my Mac (macOS 15.6), with Tuck open, the installer ran to the end: Installer quit Tuck itself
  (`PUKApplicationCloser` in /var/log/install.log), installed all five apps and opened Line Apps. It
  doesn't reopen the apps it quit, so Tuck stayed closed until opened again; the conclusion page
  already says to open the apps from Applications.

## 2026-11-13: Line Apps, the line that collapses the family's icons, and the bundle

**Superseded in part:** the installer has since run to the end on my Mac, postinstall included; see
"The installer asks to quit the apps it replaces".

- **Decision:**
  - **The line.** A menu-bar app with no Dock icon and no windows: a status item drawn in code as a
    short vertical line. A click collapses Tuck's, Pulse's, Hum's and Glow's icons into it, and the
    line bends into the Line Apps curl (from the website's `assets/line.svg`) over 0.45 s with a
    slight overshoot; a click on the curl brings them back and it straightens. The line and the curl
    share their 19 points (a move and six cubics), so every step between is a real shape. A display
    link runs only while it bends; Reduce Motion jumps.
  - **Its menu** (right-click or Control-click): Collapse or Show, the four apps with their icons,
    Open at Login (`SMAppService.mainApp`) and Quit. A first launch shows a short note under the line;
    opening Line Apps again shows it too.
  - **The protocol.** Distributed notifications, `com.millerroberts.lineapps.fold` and `.unfold`,
    carrying the line's mid x so each icon goes in its turn, the nearest first. The state is `folded`
    in Line Apps' defaults. Quitting posts unfold and keeps the state; opening re-posts fold if folded.
  - **One shared file**, `Shared/LineAppsFold.swift`, copied into the four apps. It hides with the
    status item's `isVisible` (Glow's SwiftUI `MenuBarExtra` with `isInserted`), notes the item's
    place as it goes and hands it back as it returns, and holds collapsed only while Line Apps runs.
  - **The bundle**, `scripts/build-bundle.sh`: a productbuild installer with one component per app, all
    into /Applications (never relocated onto a copy elsewhere), arm64 only, macOS 14 or later, with Hum
    enabled only on macOS 15 (`humRuns()`). Line Apps' postinstall opens it for the logged-in user.
    Without a Developer ID the apps are signed ad hoc and the installer is unsigned.
- **Why:** four icons from one family crowd the menu bar, most of all beside a notch. One line keeps a
  place for all of them, and no app loses its icon for good: it's one click away, and quitting the
  line brings it back.
- **Found on the way:**
  - **A hidden status item loses its place.** On macOS 15, `isVisible = false` deletes `NSStatusItem
    Preferred Position <name>` and writes `NSStatusItem Visible <name>` = 0; shown again, the item goes
    to the far left. Writing the position back (screen's right edge to the item's left edge) just
    before `isVisible = true` puts it where it was. macOS writes positions itself on a normal quit.
  - **Zero-length items still take 16 pt each**, so collapsing by length was dropped.
  - **SwiftUI's `MenuBarExtra(isInserted:)` writes `false` back through the binding** as it takes the
    item out. Announcing each write remade the scene, which wrote again: Glow's main thread at about
    100% for as long as the mark was out. Glow now announces only real changes (its ADR 0003).
  - **An item collapsed as its app opens isn't laid out yet**, so measuring it gave a wrong place;
    it keeps the place macOS opened it at instead.
  - **Window frames of status items can be stale**; `CGWindowList` gave the true positions when
    checking.
- **Checked:** on a macOS 15 test Mac, a virtual machine, from the bundle's own apps: collapse and
  back keep the order (line 892, Glow 920, Hum 954, Pulse 992, Tuck 1030 pt); Pulse quit and reopened
  while collapsed stays in the line and returns to 992; quitting Line Apps while collapsed brings every
  icon back in place, and reopening it collapses them again; every app at 0.0% CPU while collapsed;
  the line's menu, including Glow from it opening Glow's Settings while collapsed, and Open at Login on
  and off; Glow Desk and Glow's menu after the mark returns. I expanded the installer on my Mac
  (`pkgutil --expand-full`), and its five apps are what the test Mac ran; there, macOS 15 blocked its
  first open as expected and Open Anyway in Privacy & Security asked for an administrator's password.
  Tests: Line Apps 7, Tuck 416, Pulse 85, Hum 1117, Glow 344, all passing.
- **Deferred:**
  - **The choices page and Customize haven't been watched on screen yet.** On my Mac,
    `installer -showChoicesXML` lists the five choices, with Hum on from macOS 15; the full run,
    postinstall included, is under "The installer asks to quit the apps it replaces".
  - **An app opened for the very first time while the others are collapsed** has no place yet, so it
    comes back at the left end; from then on it keeps its place.
  - **No Developer ID yet**, so macOS asks before opening the installer (Open Anyway).
