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
           let window = description(for: windowID),
           let bounds = validatedBounds(from: window) {
            return bounds
        }

        windowID = nil
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windows = CGWindowListCopyWindowInfo(options, kCGNullWindowID)
            as? [[String: Any]] else { return nil }

        for window in windows {
            guard let bounds = validatedBounds(from: window),
                  let number = window[kCGWindowNumber as String] as? NSNumber else { continue }
            windowID = CGWindowID(number.uint32Value)
            return bounds
        }
        return nil
    }

    private func description(for windowID: CGWindowID) -> [String: Any]? {
        let ids = [NSNumber(value: windowID)] as CFArray
        return (CGWindowListCreateDescriptionFromArray(ids) as? [[String: Any]])?.first
    }

    private func validatedBounds(from window: [String: Any]) -> CGRect? {
        guard let owner = window[kCGWindowOwnerName as String] as? String,
              owner == "ChatGPT" || owner == "Codex",
              window[kCGWindowIsOnscreen as String] as? Bool == true,
              let layer = window[kCGWindowLayer as String] as? NSNumber,
              layer.intValue >= 0 && layer.intValue < 100,
              let alpha = window[kCGWindowAlpha as String] as? NSNumber,
              alpha.doubleValue > 0.01,
              let boundsDictionary = window[kCGWindowBounds as String] as? NSDictionary,
              let bounds = CGRect(dictionaryRepresentation: boundsDictionary),
              bounds.width >= 800,
              bounds.height >= 600 else { return nil }
        return bounds
    }
}

private final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: NSPanel!
    private var badgeView: QuotaMeterView!
    private var positionTimer: Timer?
    private var quotaTimer: Timer?
    private var quotaRefreshRunning = false
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

        positionTimer = Timer.scheduledTimer(
            timeInterval: 0.05,
            target: self,
            selector: #selector(updatePosition),
            userInfo: nil,
            repeats: true
        )
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

        panel.setFrameOrigin(origin)
        badgeView.tick(at: ProcessInfo.processInfo.systemUptime, visible: true,
                       reducedMotion: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion)
        if !panel.isVisible {
            panel.orderFrontRegardless()
        }
    }

    @objc private func frontApplicationDidChange(_ notification: Notification) {
        // AppKit can retain `isVisible == true` after another application takes
        // the foreground while still removing this non-activating panel from the
        // visible window stack. Reorder when the foreground application changes
        // without needlessly issuing an order-front request on every frame.
        updatePosition()
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
