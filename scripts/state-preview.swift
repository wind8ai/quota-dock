import AppKit

let reference = NSImage(contentsOfFile: CommandLine.arguments[2])!
reference.size = NSSize(width: 62, height: 156)
let canvas = NSSize(width: 424, height: 178)
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
    let states: [(String, Double?)] = [
        ("满额", 100), ("充足", 63), ("偏低", 32),
        ("临界", 12), ("耗尽", 0), ("无数据", nil)
    ]
    for (index, state) in states.enumerated() {
        let x = CGFloat(6 + index * 70)
        let title = NSAttributedString(string: state.0, attributes: [
            .font: NSFont.systemFont(ofSize: 9, weight: .medium),
            .foregroundColor: NSColor(calibratedWhite: 0.65, alpha: 1)
        ])
        title.draw(at: NSPoint(x: x + (62 - title.size().width) / 2, y: 163))
        NSGraphicsContext.saveGraphicsState()
        (AffineTransform(translationByX: x, byY: 4) as NSAffineTransform).concat()
        reference.draw(in: NSRect(x: 0, y: 0, width: 62, height: 156))
        // Clean the old meter with a narrow strip of adjacent sidebar pixels.
        // The avatar and the compact screenshot's background stay unchanged.
        reference.draw(in: NSRect(x: 8, y: 43, width: 36, height: 101),
                       from: NSRect(x: 44, y: 43, width: 6, height: 101),
                       operation: .copy, fraction: 1)
        let view = QuotaMeterView(frame: NSRect(origin: .zero, size: QuotaMeterView.size))
        view.remainingPercent = state.1
        view.phase = phase
        (AffineTransform(translationByX: 10, byY: 45) as NSAffineTransform).concat()
        view.draw(view.bounds)
        NSGraphicsContext.restoreGraphicsState()
    }
    NSGraphicsContext.restoreGraphicsState()
    try bitmap.representation(using: .png, properties: [:])!
        .write(to: URL(fileURLWithPath: destination))
}

if CommandLine.arguments.count > 3 && CommandLine.arguments[3] == "--frames" {
    for frame in 0..<120 {
        let destination = CommandLine.arguments[1] + String(format: "/frame-%03d.png", frame)
        try render(phase: Double(frame) / 120 * .pi * 4, destination: destination)
    }
} else {
    try render(phase: 0, destination: CommandLine.arguments[1])
}
print(CommandLine.arguments[1])
