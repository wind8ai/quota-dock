import AppKit


// Keep the user's real sidebar, native indicator and avatar. Only the large
// QuotaDock gauge is replaced with simulated values from the production view.
let reference = NSImage(contentsOfFile: CommandLine.arguments[2])!
reference.size = NSSize(width: 51, height: 229)
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
        reference.draw(in: NSRect(x: x, y: 12, width: 51, height: 229))
        // Replace only the captured gauge using adjacent clean sidebar pixels.
        // The native ring (including its center icon) and avatar stay intact.
        reference.draw(in: NSRect(x: x + 5, y: 12 + 104, width: 40, height: 110),
                       from: NSRect(x: 44, y: 104, width: 5, height: 110),
                       operation: .copy, fraction: 1)
        let view = QuotaMeterView(frame: NSRect(origin: .zero, size: QuotaMeterView.size))
        view.remainingPercent = state.1
        view.phase = phase
        NSGraphicsContext.saveGraphicsState()
        (AffineTransform(translationByX: x + BadgeLayout.avatarCenterX - BadgeLayout.size.width / 2,
                         byY: 12 + BadgeLayout.avatarTopFromBottom + BadgeLayout.avatarGap) as NSAffineTransform).concat()
        view.draw(view.bounds)
        NSGraphicsContext.restoreGraphicsState()
    }
    label(english ? "Simulated quota · captured native ring and avatar" : "模拟额度 · 原生圆环与头像取自用户截图",
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
