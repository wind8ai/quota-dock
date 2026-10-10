import CoreGraphics
import Foundation

final class AccountWindowSelectorTests {
    func testFilePickerInFrontDoesNotReplaceMainWindow() {
        let picker = window(id: 33, layer: 0, bounds: CGRect(x: 7, y: 5, width: 1512, height: 715))
        let main = window(id: 22, layer: 0, bounds: CGRect(x: 0, y: 0, width: 1536, height: 1080))
        precondition(AccountWindowSelector.select(in: [picker, main])?.id == 22,
                     "File picker replaced the main-window anchor")
    }
    // Captured mini bounds are deliberately large despite being a floating pet window.
    private func window(id: Int, layer: Int, bounds: CGRect, visible: Bool = true) -> [String: Any] {
        [kCGWindowOwnerName as String: "ChatGPT",
         kCGWindowNumber as String: id,
         kCGWindowLayer as String: layer,
         kCGWindowIsOnscreen as String: visible,
         kCGWindowAlpha as String: 1.0,
         kCGWindowBounds as String: bounds.dictionaryRepresentation]
    }

    func testMiniBeforeMainKeepsMainAvatarAnchor() {
        let mini = window(id: 11, layer: 3, bounds: CGRect(x: 589, y: -44, width: 1128, height: 1869))
        let main = window(id: 22, layer: 0, bounds: CGRect(x: 0, y: 37, width: 1512, height: 945))
        guard let selected = AccountWindowSelector.select(in: [mini, main]) else {
            preconditionFailure("Mini mode lost the visible main window")
        }
        precondition(selected.id == 22, "Floating mini window replaced the main-window anchor")
        let top = BadgeLayout.quartzTopLeft(in: selected.bounds)
        precondition(top == CGPoint(x: 10, y: 841), "Quota bar was positioned outside the screen")
    }

    func testOnlyMiniDoesNotCreateAnAvatarAnchor() {
        let mini = window(id: 11, layer: 3, bounds: CGRect(x: 589, y: -44, width: 1128, height: 1869))
        let hiddenMain = window(id: 22, layer: 0,
                                bounds: CGRect(x: 0, y: 37, width: 1512, height: 945), visible: false)
        precondition(AccountWindowSelector.select(in: [mini, hiddenMain]) == nil)
    }

    func testMainSelectionDoesNotDependOnMiniOrdering() {
        let mini = window(id: 11, layer: 3, bounds: CGRect(x: 589, y: -44, width: 1128, height: 1869))
        let main = window(id: 22, layer: 0, bounds: CGRect(x: -1512, y: 37, width: 1512, height: 945))
        precondition(AccountWindowSelector.select(in: [main, mini])?.id == 22)
        precondition(AccountWindowSelector.select(in: [mini, main])?.id == 22)
    }
}
