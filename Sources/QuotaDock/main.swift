import AppKit
import CoreGraphics
import Foundation

private let badgeSize = BadgeLayout.size

private final class QuotaBadgeView: NSView {
    var remainingPercent: Int? {
        didSet { needsDisplay = true }
    }

    override var isOpaque: Bool { false }

    private var accentColor: NSColor {
        guard let remainingPercent = remainingPercent else {
            return NSColor(calibratedWhite: 0.72, alpha: 1)
        }
        if remainingPercent >= 50 {
            return NSColor(calibratedRed: 0.56, green: 0.86, blue: 0.40, alpha: 1)
        }
        if remainingPercent >= 20 {
            return NSColor(calibratedRed: 0.96, green: 0.65, blue: 0.28, alpha: 1)
        }
        return NSColor(calibratedRed: 1.0, green: 0.39, blue: 0.39, alpha: 1)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let capsuleRect = bounds.insetBy(dx: 2.5, dy: 3)
        let capsule = NSBezierPath(
            roundedRect: capsuleRect,
            xRadius: capsuleRect.height / 2,
            yRadius: capsuleRect.height / 2
        )

        let gradient = NSGradient(
            starting: NSColor(calibratedWhite: 0.19, alpha: 0.96),
            ending: NSColor(calibratedWhite: 0.09, alpha: 0.96)
        )
        gradient?.draw(in: capsule, angle: -90)

        accentColor.withAlphaComponent(0.72).setStroke()
        capsule.lineWidth = 1.15
        capsule.stroke()

        let text = remainingPercent.map { "\($0)%" } ?? "--%"
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 13.5, weight: .semibold),
            .foregroundColor: NSColor.white.withAlphaComponent(0.96),
            .paragraphStyle: paragraph,
            .kern: 0.1
        ]
        let attributedText = NSAttributedString(string: text, attributes: attributes)
        let measuredSize = attributedText.boundingRect(
            with: NSSize(width: capsuleRect.width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading]
        ).integral.size
        let textRect = NSRect(
            x: capsuleRect.minX,
            y: capsuleRect.midY - measuredSize.height / 2,
            width: capsuleRect.width,
            height: measuredSize.height
        )
        attributedText.draw(
            with: textRect,
            options: [.usesLineFragmentOrigin, .usesFontLeading]
        )
    }
}

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
            near: CGPoint(x: bounds.minX + 48, y: bounds.maxY - 18)
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
    private var badgeView: QuotaBadgeView!
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

        badgeView = QuotaBadgeView(frame: NSRect(origin: .zero, size: badgeSize))
        panel.contentView = badgeView
    }

    @objc private func updatePosition() {
        guard let origin = accountBarWindowTracker.appKitOrigin() else {
            panel.orderOut(nil)
            return
        }

        panel.setFrameOrigin(origin)
        if !panel.isVisible {
            panel.orderFrontRegardless()
        }
    }

    @objc private func frontApplicationDidChange(_ notification: Notification) {
        // AppKit can retain `isVisible == true` after another application takes
        // the foreground while still removing this non-activating panel from the
        // visible window stack. Reorder when the foreground application changes
        // without needlessly issuing an order-front request on every frame.
        panel.orderFrontRegardless()
    }

    @objc private func refreshQuota() {
        guard !quotaRefreshRunning else { return }
        quotaRefreshRunning = true
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let snapshot = QuotaReader.latestSnapshot()
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.badgeView.remainingPercent = self.quotaStabilizer.displayPercent(for: snapshot)
                self.quotaRefreshRunning = false
            }
        }
    }
}

let app = NSApplication.shared
private let delegate = AppDelegate()
app.delegate = delegate
app.run()
