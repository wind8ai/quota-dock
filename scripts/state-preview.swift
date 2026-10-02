import AppKit

let reference = NSImage(contentsOfFile: CommandLine.arguments[2])!
reference.size = NSSize(width: 214, height: 71)
let canvas = NSSize(width: 690, height: 354)
let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil,
    pixelsWide: Int(canvas.width * 2), pixelsHigh: Int(canvas.height * 2),
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
let context = NSGraphicsContext(bitmapImageRep: bitmap)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
context.cgContext.scaleBy(x: 2, y: 2)
NSColor(srgbRed: 0.055, green: 0.055, blue: 0.055, alpha: 1).setFill()
NSBezierPath(rect: NSRect(origin: .zero, size: canvas)).fill()
let states: [(String, Int?)] = [
    ("满额", 100), ("充足", 57), ("偏低", 32),
    ("临界", 12), ("耗尽", 0), ("无数据", nil)
]
for (index, state) in states.enumerated() {
    let x = CGFloat(12 + (index % 3) * 226)
    let y = CGFloat(182 - (index / 3) * 172)
    (state.0 as NSString).draw(at: NSPoint(x: x, y: y + 153), withAttributes: [
        .font: NSFont.systemFont(ofSize: 10, weight: .medium),
        .foregroundColor: NSColor(calibratedWhite: 0.65, alpha: 1)
    ])
    NSGraphicsContext.saveGraphicsState()
    (AffineTransform(translationByX: x, byY: y) as NSAffineTransform).concat()
    NSColor(srgbRed: 0.082, green: 0.082, blue: 0.082, alpha: 1).setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: 214, height: 150)).fill()
    reference.draw(in: NSRect(x: 0, y: 0, width: 214, height: 71))
    // Replace the previous horizontal overlay with clean pixels from the same main pane.
    reference.draw(in: NSRect(x: 95, y: 9, width: 64, height: 29),
                   from: NSRect(x: 167, y: 9, width: 40, height: 29),
                   operation: .copy, fraction: 1)
    let view = QuotaMeterView(frame: NSRect(origin: .zero, size: QuotaMeterView.size))
    view.remainingPercent = state.1
    view.phase = 0
    (AffineTransform(translationByX: 8, byY: 43) as NSAffineTransform).concat()
    view.draw(view.bounds)
    NSGraphicsContext.restoreGraphicsState()
}
NSGraphicsContext.restoreGraphicsState()
try bitmap.representation(using: .png, properties: [:])!
    .write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
print(CommandLine.arguments[1])
