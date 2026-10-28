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
        return (CGWindowListCopyWindowInfo(.optionIncludingWindow, windowID)
            as? [[String: Any]])?.first
    }


}

private final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: NSPanel!
    private let badgeView = QuotaMeterView(frame: NSRect(origin: .zero, size: badgeSize))
    private var positionTimer: Timer?
    private var quotaTimer: Timer?
    private var quotaRefreshSchedule = QuotaRefreshSchedule()
    private var quotaTargetVisible = false
    private var lastVisibilityCheck: TimeInterval = 0
    private var visibilityRecovery = PanelVisibility()
    private let accountBarWindowTracker = AccountBarWindowTracker()
    private lazy var quotaCache = QuotaCache(namespace: LocalQuotaSource.directory.path)

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
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(quotaDidWake),
            name: NSWorkspace.didWakeNotification, object: nil
        )

        positionTimer = Timer(
            timeInterval: 0.05,
            target: self,
            selector: #selector(updatePosition),
            userInfo: nil,
            repeats: true
        )
        RunLoop.main.add(positionTimer!, forMode: .common)
        quotaTimer = Timer(
            timeInterval: 1,
            target: self,
            selector: #selector(refreshQuota),
            userInfo: nil,
            repeats: true
        )
        RunLoop.main.add(quotaTimer!, forMode: .common)
    }

    private func createPanel() {
        panel = QuotaPanel.replacing(panel, with: badgeView)
    }

    @objc private func updatePosition() {
        let now = ProcessInfo.processInfo.systemUptime
        displayQuota(animated: false)
        guard let origin = accountBarWindowTracker.appKitOrigin() else {
            quotaTargetVisible = false
            if panel.isVisible { panel.orderOut(nil) }
            _ = visibilityRecovery.action(at: now, targetVisible: false, appKitVisible: panel.isVisible, windowInfo: nil)
            badgeView.tick(at: now, visible: false,
                           reducedMotion: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion)
            return
        }

        let becameVisible = !quotaTargetVisible
        quotaTargetVisible = true
        if becameVisible { refreshQuota() }

        let moved = panel.frame.origin != origin
        panel.setFrameOrigin(origin)
        badgeView.tick(at: ProcessInfo.processInfo.systemUptime, visible: true,
                       reducedMotion: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion)
        // AppKit's isVisible can stay true while WindowServer has removed the
        // panel from the current Space. Check actual visibility at most once
        // per second, only while the tracked main window is visible.
        var action = PanelVisibility.Action.none
        if now - lastVisibilityCheck >= 1 {
            lastVisibilityCheck = now
            let info = (CGWindowListCopyWindowInfo(.optionIncludingWindow,
                CGWindowID(panel.windowNumber)) as? [[String: Any]])?.first
            action = visibilityRecovery.action(at: now, targetVisible: true,
                appKitVisible: panel.isVisible, windowInfo: info)
        }
        switch action {
        case .recreate:
            createPanel()
            panel.setFrameOrigin(origin)
        case .reorder:
            panel.orderOut(nil)
        case .none:
            break
        }
        if action != .none || !panel.isVisible || moved {
            panel.orderFrontRegardless()
        }
    }

    @objc private func workspaceDidChange(_ notification: Notification) {
        lastVisibilityCheck = 0
        updatePosition()
        refreshQuota()
    }

    @objc private func frontApplicationDidChange(_ notification: Notification) {
        // AppKit can retain `isVisible == true` after another application takes
        // the foreground while still removing this non-activating panel from the
        // visible window stack. Probe on foreground changes without first
        // hiding a healthy panel and counting that as a recovery failure.
        workspaceDidChange(notification)
    }

    @objc private func refreshQuota() {
        guard quotaRefreshSchedule.beginIfDue(at: ProcessInfo.processInfo.systemUptime,
            targetVisible: quotaTargetVisible) else { return }
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let observation = LocalQuotaSource.read()
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.quotaCache.update(observation, at: Date())
                self.displayQuota(animated: !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion)
                self.quotaRefreshSchedule.completed()
            }
        }
    }

    @objc private func quotaDidWake(_ notification: Notification) {
        displayQuota(animated: false)
        quotaRefreshSchedule.woke()
        refreshQuota()
    }

    private func displayQuota(animated: Bool) {
        let now = Date()
        let quota = quotaCache.current(at: now)
        let stale = quota.map { !$0.isFresh(at: now) } ?? false
        badgeView.exhaustionConfirmed = quota?.exhaustionConfirmed == true
        if badgeView.remainingPercent != quota?.remainingPercent {
            badgeView.setPercent(quota?.remainingPercent, animated: animated && !stale)
        }
        badgeView.isStale = stale
    }
}

if CommandLine.arguments.contains("--diagnose-quota") {
    exit(LocalQuotaSource.diagnose())
}
if CommandLine.arguments.contains("--diagnose") {
    exit(WindowDiagnostics.run())
}
let app = NSApplication.shared
private let delegate = AppDelegate()
app.delegate = delegate
app.run()
