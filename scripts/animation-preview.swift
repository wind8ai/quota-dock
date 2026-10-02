import AppKit

final class PreviewDelegate: NSObject, NSApplicationDelegate {
    private let view = QuotaMeterView(frame: NSRect(origin: .zero, size: QuotaMeterView.size))
    private var window: NSWindow!
    private var timer: Timer?
    private let values: [Int?] = [100, 57, 32, 12, 0, nil]
    private var lastIndex = -1
    private var started: TimeInterval = 0

    func applicationDidFinishLaunching(_ notification: Notification) {
        started = ProcessInfo.processInfo.systemUptime
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 200, height: 200),
                          styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.title = "QuotaDock · 合成额度预览"
        window.backgroundColor = NSColor(calibratedWhite: 0.08, alpha: 1)
        view.setFrameOrigin(NSPoint(x: 84, y: 48))
        window.contentView!.addSubview(view)
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.update()
        }
        update()
        // Bounded smoke runs are useful without leaving a second application running.
        if CommandLine.arguments.contains("--smoke") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 14) { NSApp.terminate(nil) }
        }
    }

    private func update() {
        let now = ProcessInfo.processInfo.systemUptime
        let index = Int((now - started) / 2) % values.count
        let reduced = CommandLine.arguments.contains("--reduce-motion")
            || NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        if index != lastIndex {
            lastIndex = index
            view.setPercent(values[index], animated: !reduced)
        }
        view.tick(at: now, visible: window.isVisible && !window.isMiniaturized, reducedMotion: reduced)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

let application = NSApplication.shared
let delegate = PreviewDelegate()
application.setActivationPolicy(.regular)
application.delegate = delegate
application.run()
