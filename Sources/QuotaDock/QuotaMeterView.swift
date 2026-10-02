import AppKit

/// Shared by the application and the deterministic state preview.
final class QuotaMeterView: NSView {
    static let size = NSSize(width: 32, height: 96)

    var remainingPercent: Int? {
        didSet { needsDisplay = true }
    }

    /// Fixed for static previews; the application's animation clock will advance it.
    var phase: Double = 0 {
        didSet { needsDisplay = true }
    }

    override var isOpaque: Bool { false }

    private var liquidColor: NSColor {
        switch remainingPercent ?? 0 {
        case 50...: return NSColor(srgbRed: 0.46, green: 0.80, blue: 0.30, alpha: 1)
        case 20..<50: return NSColor(srgbRed: 0.94, green: 0.60, blue: 0.19, alpha: 1)
        default: return NSColor(srgbRed: 0.91, green: 0.26, blue: 0.28, alpha: 1)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let shellRect = bounds.insetBy(dx: 0.75, dy: 0.75)
        let shell = capsule(shellRect)
        NSGradient(starting: NSColor(calibratedWhite: 0.21, alpha: 0.82),
                   ending: NSColor(calibratedWhite: 0.035, alpha: 0.9))?.draw(in: shell, angle: 0)

        let chamberRect = bounds.insetBy(dx: 3, dy: 3)
        let chamber = capsule(chamberRect)
        NSColor(calibratedWhite: 0.025, alpha: 0.60).setFill()
        chamber.fill()

        if let percent = remainingPercent {
            drawLiquid(percent: max(0, min(100, percent)), in: chamberRect, clip: chamber)
        }

        // A subtle glass reflection stays neutral at every quota level.
        let reflection = NSBezierPath()
        reflection.move(to: NSPoint(x: shellRect.minX + 3.5, y: shellRect.minY + 19))
        reflection.line(to: NSPoint(x: shellRect.minX + 3.5, y: shellRect.maxY - 19))
        NSColor.white.withAlphaComponent(0.17).setStroke()
        reflection.lineWidth = 1
        reflection.stroke()
        NSColor.white.withAlphaComponent(remainingPercent == nil ? 0.20 : 0.29).setStroke()
        shell.lineWidth = 0.8
        shell.stroke()
        drawPercent(in: chamberRect, clip: chamber)
    }

    private func capsule(_ rect: NSRect) -> NSBezierPath {
        NSBezierPath(roundedRect: rect, xRadius: rect.width / 2, yRadius: rect.width / 2)
    }

    private func drawLiquid(percent: Int, in rect: NSRect, clip: NSBezierPath) {
        NSGraphicsContext.saveGraphicsState()
        clip.addClip()
        let surfaceY = rect.minY + rect.height * CGFloat(percent) / 100
        // A rear wave gives the surface depth without changing the mean quota height.
        let rear = NSBezierPath()
        rear.move(to: NSPoint(x: rect.minX, y: rect.minY))
        rear.line(to: NSPoint(x: rect.maxX, y: rect.minY))
        let amplitude: CGFloat = (1..<100).contains(percent) ? min(1.45, rect.height * CGFloat(percent) / 350) : 0
        for step in 0...40 {
            let fraction = Double(step) / 40
            let wave = sin(fraction * .pi * 2 - phase + 1.1) * Double(amplitude)
            rear.line(to: NSPoint(x: rect.maxX - CGFloat(fraction) * rect.width,
                                 y: surfaceY + CGFloat(wave) + amplitude * 0.45))
        }
        rear.close()
        liquidColor.withAlphaComponent(0.42).setFill()
        rear.fill()

        let fill = NSBezierPath()
        fill.move(to: NSPoint(x: rect.minX, y: rect.minY))
        fill.line(to: NSPoint(x: rect.maxX, y: rect.minY))
        let surface = NSBezierPath()
        // Keep endpoint states exact; the zero marker is drawn separately below.
        for step in 0...40 {
            let fraction = CGFloat(step) / 40
            let x = rect.maxX - fraction * rect.width
            let wave = (sin(Double(fraction) * .pi * 2 + phase)
                        + 0.22 * sin(Double(fraction) * .pi * 4 - phase)) * Double(amplitude)
            let point = NSPoint(x: x, y: surfaceY + CGFloat(wave))
            fill.line(to: point)
            if step == 0 { surface.move(to: point) } else { surface.line(to: point) }
        }
        fill.close()
        NSGradient(starting: liquidColor.blended(withFraction: 0.48, of: .black)!,
                   ending: liquidColor)?.draw(in: fill, angle: 90)
        liquidColor.blended(withFraction: 0.36, of: .white)!.withAlphaComponent(0.9).setStroke()
        surface.lineWidth = 0.7
        surface.stroke()

        if percent > 0 {
            NSGraphicsContext.saveGraphicsState()
            fill.addClip()
            let liquidHeight = rect.height * CGFloat(percent) / 100
            let bubbles: [(CGFloat, Double, CGFloat)] = [(0.27, 0.19, 1.65), (0.68, 0.48, 2.15), (0.43, 0.78, 1.1)]
            for (xFraction, offset, radius) in bubbles {
                let travel = (offset + phase / (.pi * 2)).truncatingRemainder(dividingBy: 1)
                let sway = sin(phase + offset * .pi * 2) * 1.2
                let center = NSPoint(x: rect.minX + rect.width * xFraction + CGFloat(sway),
                                     y: rect.minY - radius * 2 + (liquidHeight + radius * 4) * CGFloat(travel))
                let bubble = NSBezierPath(ovalIn: NSRect(x: center.x - radius, y: center.y - radius,
                                                       width: radius * 2, height: radius * 2))
                NSColor.white.withAlphaComponent(0.12).setFill()
                bubble.fill()
                NSColor.white.withAlphaComponent(0.54).setStroke()
                bubble.lineWidth = 0.55
                bubble.stroke()
                let glint = NSBezierPath(ovalIn: NSRect(x: center.x - radius * 0.6,
                                                      y: center.y + radius * 0.15,
                                                      width: radius * 0.55, height: radius * 0.55))
                NSColor.white.withAlphaComponent(0.72).setFill()
                glint.fill()
            }
            NSGraphicsContext.restoreGraphicsState()
        }
        NSGraphicsContext.restoreGraphicsState()

        if percent == 0 {
            // A hairline follows the lower bowl below the percentage.
            let marker = NSBezierPath()
            marker.move(to: NSPoint(x: rect.minX + 2, y: rect.minY + 6))
            marker.curve(to: NSPoint(x: rect.maxX - 2, y: rect.minY + 6),
                         controlPoint1: NSPoint(x: rect.minX + 5, y: rect.minY),
                         controlPoint2: NSPoint(x: rect.maxX - 5, y: rect.minY))
            liquidColor.withAlphaComponent(0.85).setStroke()
            marker.lineWidth = 1
            marker.stroke()
        }
    }

    private func drawPercent(in rect: NSRect, clip: NSBezierPath) {
        NSGraphicsContext.saveGraphicsState()
        clip.addClip()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.85)
        shadow.shadowBlurRadius = 2
        shadow.shadowOffset = NSSize(width: 0, height: -0.5)
        let text = remainingPercent.map { "\(max(0, min(100, $0)))%" } ?? "--%"
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 8, weight: .semibold),
            .foregroundColor: NSColor.white.withAlphaComponent(0.96),
            .paragraphStyle: paragraph,
            .shadow: shadow
        ]
        let string = NSAttributedString(string: text, attributes: attributes)
        let height = string.size().height
        string.draw(in: NSRect(x: rect.minX - 1, y: rect.minY + 16 - height / 2,
                              width: rect.width + 2, height: height))
        NSGraphicsContext.restoreGraphicsState()
    }
}
