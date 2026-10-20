import AppKit

enum QuotaPanel {
    static func replacing(_ previous: NSPanel?, with view: QuotaMeterView) -> NSPanel {
        // Detach before closing so the live meter (including its animation and
        // quota) survives, while WindowServer gets a genuinely new window.
        previous?.orderOut(nil)
        previous?.contentView = nil
        previous?.close()
        let panel = NSPanel(contentRect: NSRect(origin: .zero, size: BadgeLayout.size),
                            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.level = .statusBar
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.contentView = view
        return panel
    }
}
