import AppKit
import CoreGraphics
import Foundation

private let badgeSize = BadgeLayout.size

private struct ScreenCoordinateConverter {
    static func appKitOrigin(quartzTopLeft: CGPoint, near point: CGPoint) -> NSPoint? {
        for screen in NSScreen.screens {
            guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")]
                as? NSNumber else { continue }
            let displayID = CGDirectDisplayID(number.uint32Value)
            let quartzBounds = CGDisplayBounds(displayID)
            guard quartzBounds.contains(point) else { continue }

            return NSPoint(
                x: screen.frame.minX + quartzTopLeft.x - quartzBounds.minX,
                y: screen.frame.maxY - (quartzTopLeft.y - quartzBounds.minY) - badgeSize.height
            )
        }
        return nil
    }
}

private final class AccountBarWindowTracker {
    private var windowID: CGWindowID?

    func appKitOrigin() -> NSPoint? {
        guard let bounds = liveMainWindowBounds() else { return nil }
        let badgeTopLeft = BadgeLayout.quartzTopLeft(in: bounds)
        return ScreenCoordinateConverter.appKitOrigin(
            quartzTopLeft: badgeTopLeft,
            near: CGPoint(x: badgeTopLeft.x + badgeSize.width / 2,
                          y: badgeTopLeft.y + badgeSize.height / 2)
        )
    }

    private func liveMainWindowBounds() -> CGRect? {
        if let windowID = windowID,
           let window = description(for: windowID) {
            // Keep the identity through modal dialogs and Space transitions.
            // If this window is temporarily offscreen, hide instead of adopting
            // another window (which may be a picker or detached chat).
            return AccountWindowSelector.bounds(from: window)
        }

        windowID = nil
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windows = CGWindowListCopyWindowInfo(options, kCGNullWindowID)
            as? [[String: Any]] else { return nil }

        guard let selected = AccountWindowSelector.select(in: windows) else { return nil }
        windowID = selected.id
        return selected.bounds
    }

    private func description(for windowID: CGWindowID) -> [String: Any]? {
        let ids = [NSNumber(value: windowID)] as CFArray
        return (CGWindowListCreateDescriptionFromArray(ids) as? [[String: Any]])?.first
    }


}

private final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: NSPanel!
    private var badgeView: QuotaMeterView!
    private var positionTimer: Timer?
    private var quotaTimer: Timer?
    private var quotaRefreshRunning = false
    private var resyncUntil: TimeInterval = 0
    private var lastReorder: TimeInterval = 0
    private let accountBarWindowTracker = AccountBarWindowTracker()
    private let quotaStabilizer = QuotaStabilizer()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        createPanel()
        updatePosition()
        refreshQuota()
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(frontApplicationDidChange),
            name: NSWorkspace.didActivateApplicationNotification,
            object: NSWorkspace.shared
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(workspaceDidChange),
            name: NSWorkspace.activeSpaceDidChangeNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(workspaceDidChange),
            name: NSApplication.didChangeScreenParametersNotification, object: nil
        )

        positionTimer = Timer(
            timeInterval: 0.05,
            target: self,
            selector: #selector(updatePosition),
            userInfo: nil,
            repeats: true
        )
        RunLoop.main.add(positionTimer!, forMode: .common)
        quotaTimer = Timer.scheduledTimer(
            timeInterval: 30,
            target: self,
            selector: #selector(refreshQuota),
            userInfo: nil,
            repeats: true
        )
    }

    private func createPanel() {
        panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: badgeSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .statusBar
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        badgeView = QuotaMeterView(frame: NSRect(origin: .zero, size: badgeSize))
        panel.contentView = badgeView
    }

    @objc private func updatePosition() {
        guard let origin = accountBarWindowTracker.appKitOrigin() else {
            panel.orderOut(nil)
            badgeView.tick(at: ProcessInfo.processInfo.systemUptime, visible: false,
                           reducedMotion: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion)
            return
        }

        let moved = panel.frame.origin != origin
        panel.setFrameOrigin(origin)
        badgeView.tick(at: ProcessInfo.processInfo.systemUptime, visible: true,
                       reducedMotion: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion)
        let now = ProcessInfo.processInfo.systemUptime
        // A panel may still report visible while absent from the fullscreen
        // Space. Retry briefly through the Space transition, not indefinitely.
        if !panel.isVisible || moved || (now < resyncUntil && now - lastReorder >= 0.25) {
            panel.orderFrontRegardless()
            lastReorder = now
        }
    }

    @objc private func workspaceDidChange(_ notification: Notification) {
        resyncUntil = ProcessInfo.processInfo.systemUptime + 2
        lastReorder = 0
        panel.orderOut(nil)
        updatePosition()
    }

    @objc private func frontApplicationDidChange(_ notification: Notification) {
        // AppKit can retain `isVisible == true` after another application takes
        // the foreground while still removing this non-activating panel from the
        // visible window stack. Reorder when the foreground application changes
        // without needlessly issuing an order-front request on every frame.
        workspaceDidChange(notification)
        if panel.isVisible { panel.orderFrontRegardless() }
    }

    @objc private func refreshQuota() {
        guard !quotaRefreshRunning else { return }
        quotaRefreshRunning = true
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let snapshot = QuotaReader.latestSnapshot()
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.badgeView.setPercent(self.quotaStabilizer.displayPercent(for: snapshot),
                                          animated: !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion)
                self.quotaRefreshRunning = false
            }
        }
    }
}

let app = NSApplication.shared
private let delegate = AppDelegate()
app.delegate = delegate
app.run()
