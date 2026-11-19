import AppKit

#if DEBUG
if let folder = MarkSnapshots.folder(in: CommandLine.arguments) {
    MarkSnapshots.render(to: folder)
    exit(0)
}
#endif

// A menu-bar app with no Dock icon and no windows of its own: the line is all of it.
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
