import Foundation

/// What the line tells the family. Tuck, Pulse, Hum and Glow each listen with their copy of
/// Shared/LineAppsFold.swift: a fold hides their menu-bar icon and an unfold shows it again.
enum Fold {
    static let foldName = Notification.Name("com.millerroberts.lineapps.fold")
    static let unfoldName = Notification.Name("com.millerroberts.lineapps.unfold")
    /// Line Apps' preferences hold whether the apps are folded away, so an app that opens later reads
    /// it and starts hidden, and the line comes back as it was left.
    static let savedKey = "folded"

    static var saved: Bool {
        get { UserDefaults.standard.bool(forKey: savedKey) }
        set { UserDefaults.standard.set(newValue, forKey: savedKey) }
    }

    /// Tells every app. The line's middle, in screen points, lets each one go in its turn, the nearest
    /// first; without it they all go at once.
    static func post(folded: Bool, lineX: Double?) {
        DistributedNotificationCenter.default().postNotificationName(
            folded ? foldName : unfoldName,
            object: nil,
            userInfo: lineX.map { ["x": $0] },
            deliverImmediately: true
        )
    }
}
