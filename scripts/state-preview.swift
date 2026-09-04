// Appended to the production QuotaBadgeView by render-states.sh.
// Use the supplied account bar at its native pixel size; only quota values are simulated.

private let accountReference = NSImage(contentsOfFile: CommandLine.arguments[2])!
accountReference.size = NSSize(width: 336, height: 48)

private func accountBar(percent: Int?, x: CGFloat, y: CGFloat) {
    NSGraphicsContext.saveGraphicsState()
    (AffineTransform(translationByX: x, byY: y) as NSAffineTransform).concat()
    accountReference.draw(in: NSRect(x: 0, y: 0, width: 336, height: 48))
    // Clear the old badge with an unused span of the same account-bar background.
    accountReference.draw(in: NSRect(x: 96, y: 8, width: 64, height: 30),
                          from: NSRect(x: 176, y: 8, width: 64, height: 30),
                          operation: .copy, fraction: 1)
    let badge = QuotaBadgeView(frame: NSRect(origin: .zero, size: badgeSize))
    badge.remainingPercent = percent
    (AffineTransform(translationByX: 96, byY: 8) as NSAffineTransform).concat()
    badge.draw(badge.bounds)
    NSGraphicsContext.restoreGraphicsState()
}

let canvas = NSSize(width: 728, height: 244)
let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil,
    pixelsWide: Int(canvas.width), pixelsHigh: Int(canvas.height),
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
let context = NSGraphicsContext(bitmapImageRep: bitmap)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
context.imageInterpolation = .none
NSColor(srgbRed: 0.075, green: 0.075, blue: 0.075, alpha: 1).setFill()
NSBezierPath(rect: NSRect(origin: .zero, size: canvas)).fill()
let states: [(String, Int?)] = [
    ("满额", 100), ("充足", 57),
    ("偏低", 32), ("临界", 12),
    ("耗尽", 0), ("无数据", nil)
]
for (index, state) in states.enumerated() {
    let x = CGFloat(16 + (index % 2) * 360)
    let y = CGFloat(166 - (index / 2) * 72)
    (state.0 as NSString).draw(at: NSPoint(x: x + 8, y: y + 52), withAttributes: [
        .font: NSFont.systemFont(ofSize: 11, weight: .medium),
        .foregroundColor: NSColor(srgbRed: 0.6, green: 0.6, blue: 0.6, alpha: 1)
    ])
    accountBar(percent: state.1, x: x, y: y)
}
NSGraphicsContext.restoreGraphicsState()
let destination = URL(fileURLWithPath: CommandLine.arguments[1])
try bitmap.representation(using: .png, properties: [:])!.write(to: destination)
print(destination.path)
