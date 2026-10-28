import AppKit

let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
let view = QuotaMeterView(frame: NSRect(origin: .zero, size: BadgeLayout.size))
view.remainingPercent = 37.5
view.phase = 1.5
view.isStale = true
view.isSpendingCredits = true
var panel = QuotaPanel.replacing(nil, with: view)
for _ in 0..<20 {
    let old = panel
    panel = QuotaPanel.replacing(old, with: view)
    precondition(panel !== old, "Recovery must create a new native panel, not reorder the stuck one")
    precondition(old.contentView == nil && !old.isVisible)
    precondition(panel.contentView === view)
    precondition(view.remainingPercent == 37.5 && view.phase == 1.5)
    precondition(view.isStale)
    precondition(view.isSpendingCredits)
    precondition(panel.ignoresMouseEvents && !panel.hidesOnDeactivate)
    precondition(panel.collectionBehavior.contains(.canJoinAllSpaces))
    precondition(panel.collectionBehavior.contains(.fullScreenAuxiliary))
}
panel.close()
view.remainingPercent = 0
view.needsDisplay = false
view.exhaustionConfirmed = true
precondition(view.needsDisplay, "An exhaustion confirmation must redraw even when the percentage stays zero")
view.tick(at: 0, visible: true, reducedMotion: false)
view.tick(at: 1, visible: true, reducedMotion: false)
precondition(view.phase == 0, "Cached readings must not keep animating")
view.isStale = false
view.phase = 1.5
view.tick(at: 2, visible: true, reducedMotion: false)
precondition(view.phase == 0, "The credit-debit warning must pause liquid animation")
view.needsDisplay = false
view.isSpendingCredits = false
precondition(view.needsDisplay, "Resetting the credit warning must redraw the tube")
print("PASS native panel recreation preserves view, quota and animation across 20 replacements")
