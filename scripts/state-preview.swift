import AppKit

// Synthetic sidebar layout. The native ring is a schematic, not an app capture.
let canvas = NSSize(width: 424, height: 270)
let english = CommandLine.arguments.contains("--english")
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
        let center = NSPoint(x: x + BadgeLayout.avatarCenterX, y: 85)
        for angles in [(CGFloat(45), CGFloat(135)), (CGFloat(165), CGFloat(375))] {
            let arc = NSBezierPath()
            arc.appendArc(withCenter: center, radius: 11, startAngle: angles.0, endAngle: angles.1)
            NSColor(calibratedWhite: 0.65, alpha: 1).setStroke()
            arc.lineWidth = 1.75
            arc.lineCapStyle = .round
            arc.stroke()
        }
        let avatar = NSBezierPath(ovalIn: NSRect(x: center.x - 10, y: 26, width: 20, height: 20))
        NSColor(calibratedWhite: 0.3, alpha: 1).setFill()
        avatar.fill()
        let view = QuotaMeterView(frame: NSRect(origin: .zero, size: QuotaMeterView.size))
        view.remainingPercent = state.1
        view.phase = phase
        NSGraphicsContext.saveGraphicsState()
        (AffineTransform(translationByX: center.x - BadgeLayout.size.width / 2,
                         byY: 12 + BadgeLayout.avatarTopFromBottom + BadgeLayout.avatarGap) as NSAffineTransform).concat()
        view.draw(view.bounds)
        NSGraphicsContext.restoreGraphicsState()
    }
    label(english ? "Simulated quota · native ring schematic" : "模拟额度 · 下方圆环为原生样式示意",
          at: NSPoint(x: 10, y: 4), size: 9, color: .gray)
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
