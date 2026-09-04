// Appended to the production QuotaBadgeView by render-states.sh.
// Percentages and account-bar surroundings are synthetic; the avatar uses the supplied reference.

private let accountReference = NSImage(contentsOfFile: CommandLine.arguments[2])!

private func label(_ text: String, x: CGFloat, y: CGFloat, size: CGFloat,
                   color: NSColor, weight: NSFont.Weight = .regular) {
    (text as NSString).draw(at: NSPoint(x: x, y: y), withAttributes: [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: color
    ])
}

private func accountBar(percent: Int?, x: CGFloat, y: CGFloat) {
    NSGraphicsContext.saveGraphicsState()
    let translation = AffineTransform(translationByX: x, byY: y)
    (translation as NSAffineTransform).concat()
    NSColor(calibratedWhite: 0.12, alpha: 1).setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: 336, height: 48)).fill()
    NSColor(calibratedWhite: 0.17, alpha: 1).setFill()
    NSBezierPath(roundedRect: NSRect(x: 8, y: 8, width: 272, height: 32),
                 xRadius: 10, yRadius: 10).fill()
    // The supplied 336×48 reference has an 18×18 avatar at top-left (15, 16).
    // NSImage source rectangles use a bottom-left origin. Keep the original pixels.
    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(ovalIn: NSRect(x: 15, y: 15, width: 18, height: 18)).addClip()
    accountReference.draw(in: NSRect(x: 15, y: 15, width: 18, height: 18),
                          from: NSRect(x: 15, y: 14, width: 18, height: 18),
                          operation: .sourceOver, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()
    label("wind8", x: 42, y: 13, size: 16, color: .white)
    let help = NSBezierPath(ovalIn: NSRect(x: 298, y: 17, width: 13, height: 13))
    NSColor(calibratedWhite: 0.52, alpha: 1).setStroke()
    help.lineWidth = 1
    help.stroke()
    label("?", x: 301, y: 17, size: 10, color: NSColor(calibratedWhite: 0.65, alpha: 1))

    let badge = QuotaBadgeView(frame: NSRect(origin: .zero, size: badgeSize))
    badge.remainingPercent = percent
    let badgeTranslation = AffineTransform(translationByX: 96, byY: 8)
    (badgeTranslation as NSAffineTransform).concat()
    badge.draw(badge.bounds)
    NSGraphicsContext.restoreGraphicsState()
}

let canvas = NSSize(width: 768, height: 404)
let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil,
    pixelsWide: Int(canvas.width * 2), pixelsHigh: Int(canvas.height * 2),
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
let context = NSGraphicsContext(bitmapImageRep: bitmap)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
context.cgContext.scaleBy(x: 2, y: 2)
NSColor(calibratedWhite: 0.085, alpha: 1).setFill()
NSBezierPath(rect: NSRect(origin: .zero, size: canvas)).fill()
label("QuotaDock · 额度状态", x: 32, y: 351, size: 24, color: .white, weight: .semibold)
label("账号栏展示模拟 · 非实时额度", x: 32, y: 324, size: 12,
      color: NSColor(calibratedWhite: 0.58, alpha: 1))
let states: [(String, Int?)] = [
    ("满额 / 新周期", 100), ("充足 · ≥50%", 64),
    ("偏低 · 20–49%", 32), ("临界 · <20%", 12),
    ("耗尽", 0), ("无数据且无缓存", nil)
]
for (index, state) in states.enumerated() {
    let x = CGFloat(32 + (index % 2) * 368)
    let y = CGFloat(246 - (index / 2) * 94)
    label(state.0, x: x, y: y + 53, size: 12,
          color: NSColor(calibratedWhite: 0.7, alpha: 1))
    accountBar(percent: state.1, x: x, y: y)
}
label("头像沿用提供的示例；徽标使用原生绘制代码，额度为模拟。", x: 32, y: 20,
      size: 11, color: NSColor(calibratedWhite: 0.5, alpha: 1))
NSGraphicsContext.restoreGraphicsState()
let destination = URL(fileURLWithPath: CommandLine.arguments[1])
try bitmap.representation(using: .png, properties: [:])!.write(to: destination)
print(destination.path)
