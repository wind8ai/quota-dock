import AppKit


// Keep the user's sidebar, center icon and avatar; simulate both quota displays.
let reference = NSImage(contentsOfFile: CommandLine.arguments[2])!
reference.size = NSSize(width: 51, height: 229)
let canvas = NSSize(width: 424, height: 270)
let english = CommandLine.arguments.contains("--english")
let cachedPreview = CommandLine.arguments.contains("--cached")
func label(_ text: String, at point: NSPoint, size: CGFloat, color: NSColor) {
    NSAttributedString(string: text, attributes: [.font: NSFont.systemFont(ofSize: size, weight: .medium),
        .foregroundColor: color]).draw(at: point)
}
func render(phase: Double, destination: String) throws {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil,
        pixelsWide: Int(canvas.width * 2), pixelsHigh: Int(canvas.height * 2),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let context = NSGraphicsContext(bitmapImageRep: bitmap)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.cgContext.scaleBy(x: 2, y: 2)
    NSColor(srgbRed: 0.07, green: 0.07, blue: 0.07, alpha: 1).setFill()
    NSBezierPath(rect: NSRect(origin: .zero, size: canvas)).fill()
    let labels = english ? ["Full", "Available", "Low", "Critical", "Empty", "No data"]
        : ["满额", "充足", "偏低", "临界", "耗尽", "无数据"]
    let values: [Double?] = [100, 77, 32, 12, 0, nil]
    for (index, state) in Array(zip(labels, values)).enumerated() {
        let x = CGFloat(6 + index * 70)
        label(state.0, at: NSPoint(x: x + 9, y: 245), size: 9, color: .lightGray)
        reference.draw(in: NSRect(x: x, y: 12, width: 51, height: 229))
        // Replace only the captured gauge using adjacent clean sidebar pixels.
        // The avatar stays intact; redraw only the native ring's progress below.
        reference.draw(in: NSRect(x: x + 5, y: 12 + 104, width: 40, height: 110),
                       from: NSRect(x: 44, y: 104, width: 5, height: 110),
                       operation: .copy, fraction: 1)
        reference.draw(in: NSRect(x: x + 12, y: 12 + 54, width: 28, height: 29),
                       from: NSRect(x: 44, y: 54, width: 5, height: 29),
                       operation: .copy, fraction: 1)
        let ringRect = NSRect(x: x + 14.5, y: 12 + 57.5, width: 23, height: 23)
        // The captured diamond's ink center is (26, 70), one point above
        // its crop's center. Align that ink center, not the crop rectangle.
        reference.draw(in: NSRect(x: ringRect.midX - 6, y: ringRect.midY - 7, width: 12, height: 12),
                       from: NSRect(x: 20, y: 63, width: 12, height: 12),
                       operation: .copy, fraction: 1)
        let track = NSBezierPath(ovalIn: ringRect)
        track.lineWidth = 1.75
        NSColor(calibratedWhite: 0.65, alpha: state.1 == nil ? 0.24 : 0.35).setStroke()
        if state.1 == nil { track.setLineDash([2, 2], count: 2, phase: 0) }
        track.stroke()
        if let percent = state.1, percent > 0 {
            let progress: NSBezierPath
            if percent == 100 { progress = NSBezierPath(ovalIn: ringRect) }
            else {
                progress = NSBezierPath()
                progress.appendArc(withCenter: NSPoint(x: ringRect.midX, y: ringRect.midY),
                    radius: ringRect.width / 2, startAngle: 90,
                    endAngle: 90 - CGFloat(percent) * 3.6, clockwise: true)
            }
            progress.lineWidth = 1.75
            progress.lineCapStyle = .round
            (percent < 15 ? NSColor(srgbRed: 0.94, green: 0.60, blue: 0.19, alpha: 1)
                : NSColor(calibratedWhite: 0.72, alpha: 1)).setStroke()
            progress.stroke()
        }
        let view = QuotaMeterView(frame: NSRect(origin: .zero, size: QuotaMeterView.size))
        view.remainingPercent = state.1
        view.isStale = cachedPreview && state.1 != nil
        view.phase = cachedPreview ? 0 : phase
        NSGraphicsContext.saveGraphicsState()
        (AffineTransform(translationByX: x + BadgeLayout.avatarCenterX - BadgeLayout.size.width / 2,
                         byY: 12 + BadgeLayout.avatarTopFromBottom + BadgeLayout.avatarGap) as NSAffineTransform).concat()
        view.draw(view.bounds)
        NSGraphicsContext.restoreGraphicsState()
    }
    NSGraphicsContext.restoreGraphicsState()
    try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: destination))
}
if CommandLine.arguments.contains("--frames") {
    for frame in 0..<120 {
        try render(phase: Double(frame) / 120 * .pi * 4,
                   destination: CommandLine.arguments[1] + String(format: "/frame-%03d.png", frame))
    }
} else {
    try render(phase: 0, destination: CommandLine.arguments[1])
}
print(CommandLine.arguments[1])
