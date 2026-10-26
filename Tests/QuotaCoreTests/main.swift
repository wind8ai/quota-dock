import Foundation

let account = AccountQuotaTests()
let accountTests: [(String, () -> Void)] = [
    ("testUsesCodexBucketAndWindowDurationRatherThanPrimaryPosition", account.testUsesCodexBucketAndWindowDurationRatherThanPrimaryPosition),
    ("testWeeklyOnlyAndServerCorrectionsRemainAuthoritative", account.testWeeklyOnlyAndServerCorrectionsRemainAuthoritative),
    ("testRejectsMissingCodexBucketEvenWhenLegacyExists", account.testRejectsMissingCodexBucketEvenWhenLegacyExists),
    ("testRejectsInvalidExpiredAndUnsupportedWindows", account.testRejectsInvalidExpiredAndUnsupportedWindows),
    ("testFreshnessExpiresAtResetOrAfterOneMinute", account.testFreshnessExpiresAtResetOrAfterOneMinute)
]
for (name, test) in accountTests { test(); print("PASS \(name)") }
let client = CodexQuotaClientTests()
let clientTests: [(String, () -> Void)] = [
    ("testReadsOfficialProtocolAndIgnoresNotifications", client.testReadsOfficialProtocolAndIgnoresNotifications),
    ("testRejectsAccountChange", client.testRejectsAccountChange),
    ("testTimeoutAndProtocolErrorsAreBounded", client.testTimeoutAndProtocolErrorsAreBounded)
]
for (name, test) in clientTests { test(); print("PASS \(name)") }

let layout = BadgeLayoutTests()
let layoutTests: [(String, () throws -> Void)] = [
    ("testAccountBarOffsetsOnTranslatedWindows", layout.testAccountBarOffsetsOnTranslatedWindows)
]
for (name, test) in layoutTests {
    try test()
    print("PASS \(name)")
}

let animation = QuotaMeterAnimationTests()
let animationTests: [(String, () -> Void)] = [
    ("testTransitionReachesTargetInSixTenths", animation.testTransitionReachesTargetInSixTenths),
    ("testHiddenStatePausesTransitionAndBubbles", animation.testHiddenStatePausesTransitionAndBubbles),
    ("testReducedMotionSnapsLevelAndFreezesPhase", animation.testReducedMotionSnapsLevelAndFreezesPhase),
    ("testRetargetingStartsAtCurrentLevel", animation.testRetargetingStartsAtCurrentLevel),
    ("testZeroAndUnknownStopAmbientAnimation", animation.testZeroAndUnknownStopAmbientAnimation),
    ("testFractionalTargetSurvivesTransition", animation.testFractionalTargetSurvivesTransition)
]
for (name, test) in animationTests {
    test()
    print("PASS \(name)")
}

let windowSelector = AccountWindowSelectorTests()
let windowTests: [(String, () -> Void)] = [
    ("testFilePickerInFrontDoesNotReplaceMainWindow", windowSelector.testFilePickerInFrontDoesNotReplaceMainWindow),
    ("testMiniBeforeMainKeepsMainAvatarAnchor", windowSelector.testMiniBeforeMainKeepsMainAvatarAnchor),
    ("testOnlyMiniDoesNotCreateAnAvatarAnchor", windowSelector.testOnlyMiniDoesNotCreateAnAvatarAnchor),
    ("testMainSelectionDoesNotDependOnMiniOrdering", windowSelector.testMainSelectionDoesNotDependOnMiniOrdering)
]
for (name, test) in windowTests {
    test()
    print("PASS \(name)")
}

let display = QuotaDisplayValueTests()
let displayTests: [(String, () -> Void)] = [
    ("testIntegerWithoutPercentSign", display.testIntegerWithoutPercentSign),
    ("testUnknownAndInvalidValuesHaveNoPercentSign", display.testUnknownAndInvalidValuesHaveNoPercentSign)
]
for (name, test) in displayTests {
    test()
    print("PASS \(name)")
}

let visibility = PanelVisibilityTests()
let visibilityTests: [(String, () -> Void)] = [
    ("testRestoresPanelMissingFromScreenEvenWhenAppKitSaysVisible", visibility.testRestoresPanelMissingFromScreenEvenWhenAppKitSaysVisible),
    ("testRepeatedFailedReorderRecreatesPanel", visibility.testRepeatedFailedReorderRecreatesPanel),
    ("testRecoveryCooldownAndSuccessfulDisplayReset", visibility.testRecoveryCooldownAndSuccessfulDisplayReset),
    ("testHiddenTargetDoesNotRecoverOrAccumulateFailures", visibility.testHiddenTargetDoesNotRecoverOrAccumulateFailures)
]
for (name, test) in visibilityTests {
    test()
    print("PASS \(name)")
}
print("All \(accountTests.count + clientTests.count + layoutTests.count + animationTests.count + windowTests.count + displayTests.count + visibilityTests.count) tests passed.")
