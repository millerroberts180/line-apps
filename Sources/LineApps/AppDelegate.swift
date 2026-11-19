import AppKit

/// Owns the line for the app's lifetime.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var line: LineItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let line = LineItem()
        self.line = line
        // A moment for the menu bar to place the line, so the note has something to point at.
        Task {
            try? await Task.sleep(for: .milliseconds(600))
            line.introduceIfNew()
        }
    }

    /// The apps come back as Line Apps quits, so none is left hidden with nothing to bring it back.
    /// Whether they were collapsed stays saved, and the line collapses them again when it next opens.
    func applicationWillTerminate(_ notification: Notification) {
        Fold.post(folded: false, lineX: nil)
    }

    /// Opening Line Apps again, from Finder or Spotlight, shows the note on what the line does.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        line?.showIntro()
        return false
    }
}
