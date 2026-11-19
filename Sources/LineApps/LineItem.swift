import AppKit
import ServiceManagement

/// The line in the menu bar. A click collapses Tuck, Pulse, Hum and Glow into it, and the line bends
/// into the Line Apps curl; a click on the curl brings them back and it straightens again. A
/// right-click or Control-click opens its menu: the same, the apps themselves, Open at Login and Quit.
@MainActor
final class LineItem: NSObject, NSMenuDelegate, NSPopoverDelegate {
    static let duration: CFTimeInterval = 0.45

    private let item = NSStatusBar.system.statusItem(withLength: LineMark.itemLength(at: 0))
    private let menu = NSMenu()
    /// Whether the apps are collapsed into the line.
    private(set) var folded = Fold.saved
    /// Where the drawing is: 0 the line, 1 the curl.
    private var progress: CGFloat = 0
    /// The bend under way, while there is one; the display link exists only then.
    private var bend: (from: CGFloat, to: CGFloat, start: CFTimeInterval)?
    private var link: CADisplayLink?
    private var intro: NSPopover?

    override init() {
        super.init()
        progress = folded ? 1 : 0
        // Keeps the place the line is Command-dragged to.
        item.autosaveName = "LineAppsLine"
        menu.delegate = self
        menu.autoenablesItems = false
        if let button = item.button {
            button.target = self
            button.action = #selector(clicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.setAccessibilityLabel("Line Apps")
        }
        draw()
        describe()
        // Apps that opened before Line Apps did are showing; this collapses them again.
        if folded { Fold.post(folded: true, lineX: nil) }
    }

    // MARK: Clicks

    @objc private func clicked() {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            showMenu()
        } else {
            toggle()
        }
    }

    /// Collapses the apps into the line, or brings them back.
    @objc func toggle() {
        intro?.close()
        folded.toggle()
        Fold.saved = folded
        Fold.post(folded: folded, lineX: item.button?.window.map { Double($0.frame.midX) })
        bend(to: folded ? 1 : 0)
        describe()
    }

    /// The menu, dropped from the line as a status item's menu is.
    private func showMenu() {
        intro?.close()
        item.menu = menu
        item.button?.performClick(nil)
        item.menu = nil
    }

    // MARK: Drawing

    private func draw() {
        item.length = LineMark.itemLength(at: progress)
        item.button?.image = LineMark.image(at: progress)
    }

    private func describe() {
        guard let button = item.button else { return }
        button.toolTip = folded ? "Show Line Apps" : "Collapse Line Apps into the line"
        button.setAccessibilityValue(folded ? "Apps collapsed" : "Apps showing")
        button.setAccessibilityHelp(folded ? "Shows Tuck, Pulse, Hum and Glow in the menu bar again"
                                           : "Collapses Tuck, Pulse, Hum and Glow into the line")
    }

    /// Bends the stroke from where it is to the line (0) or the curl (1), over the display's own frames.
    /// With Reduce Motion on it is simply redrawn there.
    private func bend(to target: CGFloat) {
        guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion, let button = item.button else {
            stopBending()
            progress = target
            draw()
            return
        }
        bend = (progress, target, CACurrentMediaTime())
        if link == nil {
            let link = button.displayLink(target: self, selector: #selector(step))
            link.add(to: .main, forMode: .common)
            self.link = link
        }
    }

    @objc private func step(_ link: CADisplayLink) {
        guard let bend else { return stopBending() }
        let t = (CACurrentMediaTime() - bend.start) / Self.duration
        progress = t >= 1 ? bend.to : bend.from + (bend.to - bend.from) * LineMark.ease(t)
        draw()
        if t >= 1 { stopBending() }
    }

    private func stopBending() {
        bend = nil
        link?.invalidate()
        link = nil
    }

    // MARK: Menu

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        menu.addItem(entry(folded ? "Show Line Apps" : "Collapse Line Apps", #selector(toggle)))
        // Each app opens as from Finder: one already open shows its Settings or player.
        let installed = FamilyApp.all.compactMap { app in app.url.map { (app, $0) } }
        if !installed.isEmpty {
            menu.addItem(.separator())
            for (app, url) in installed {
                let open = entry(app.name, #selector(openApp(_:)))
                open.representedObject = url
                let icon = NSWorkspace.shared.icon(forFile: url.path)
                icon.size = NSSize(width: 16, height: 16)
                open.image = icon
                menu.addItem(open)
            }
        }
        menu.addItem(.separator())
        let login = entry("Open at Login", #selector(toggleOpenAtLogin))
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(login)
        menu.addItem(.separator())
        menu.addItem(entry("Quit Line Apps", #selector(quit), key: "q"))
    }

    private func entry(_ title: String, _ action: Selector, key: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    @objc private func openApp(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
    }

    @objc private func toggleOpenAtLogin() {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled { try service.unregister() } else { try service.register() }
        } catch {
            NSApp.activate()
            let alert = NSAlert()
            alert.messageText = "Open at Login couldn’t be changed"
            alert.informativeText = "\(error.localizedDescription) You can add Line Apps in System Settings › General › Login Items."
            alert.runModal()
        }
    }

    @objc private func quit() { NSApp.terminate(nil) }

    // MARK: Introduction

    /// The first time Line Apps opens, a note under the line says what it does.
    func introduceIfNew() {
        let key = "introduced"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)
        showIntro()
    }

    /// The note, also shown when Line Apps is opened again while it runs.
    func showIntro() {
        guard intro == nil, let button = item.button, button.window != nil else { return }
        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = IntroViewController()
        popover.delegate = self
        NSApp.activate()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        intro = popover
    }

    func popoverDidClose(_ notification: Notification) { intro = nil }
}

/// Says what the line does, in three short lines.
private final class IntroViewController: NSViewController {
    override func loadView() {
        let title = NSTextField(labelWithString: "This line holds your Line Apps")
        title.font = .systemFont(ofSize: 13, weight: .semibold)
        let body = NSTextField(wrappingLabelWithString:
            "Click it to collapse Tuck, Pulse, Hum and Glow into it, and click again to bring them back. Right-click for the apps, Open at Login and Quit.")
        body.font = .systemFont(ofSize: 12)
        body.textColor = .secondaryLabelColor
        body.preferredMaxLayoutWidth = 248
        let move = NSTextField(wrappingLabelWithString: "Command-drag the line to put it beside them.")
        move.font = .systemFont(ofSize: 12)
        move.textColor = .secondaryLabelColor
        let stack = NSStackView(views: [title, body, move])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 6
        stack.edgeInsets = NSEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        stack.widthAnchor.constraint(equalToConstant: 280).isActive = true
        view = stack
    }
}
