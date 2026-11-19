import AppKit

/// The apps that fold into the line, in the order the family is always named.
struct FamilyApp: Equatable, Sendable {
    let name: String
    let bundleID: String

    static let all = [
        FamilyApp(name: "Tuck", bundleID: "com.millerroberts.Tuck"),
        FamilyApp(name: "Pulse", bundleID: "com.millerroberts.Pulse"),
        FamilyApp(name: "Hum", bundleID: "com.millerroberts.hum"),
        FamilyApp(name: "Glow", bundleID: "com.millerroberts.Glow"),
    ]

    /// Where it is installed: found by its ID, or failing that by name in Applications.
    @MainActor var url: URL? {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) { return url }
        let fallback = URL(fileURLWithPath: "/Applications/\(name).app")
        return FileManager.default.fileExists(atPath: fallback.path) ? fallback : nil
    }

    @MainActor var isRunning: Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).isEmpty
    }
}
