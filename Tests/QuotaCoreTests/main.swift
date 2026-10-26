import Foundation


let refresh = QuotaRefreshScheduleTests()
let refreshTests: [(String, () -> Void)] = [
    ("testVisibleQuotaRefreshDoesNotWaitThirtySeconds", refresh.testVisibleQuotaRefreshDoesNotWaitThirtySeconds),
    ("testHiddenWindowSlowsPollingAndRevealChecksImmediately", refresh.testHiddenWindowSlowsPollingAndRevealChecksImmediately),
    ("testInFlightAndWakeNeverOverlapRequests", refresh.testInFlightAndWakeNeverOverlapRequests)
]
for (name, test) in refreshTests { test(); print("PASS \(name)") }

let account = AccountQuotaTests()
let accountTests: [(String, () -> Void)] = [
    ("testUsesCodexBucketAndWindowDurationRatherThanPrimaryPosition", account.testUsesCodexBucketAndWindowDurationRatherThanPrimaryPosition),
    ("testWeeklyOnlyAndServerCorrectionsRemainAuthoritative", account.testWeeklyOnlyAndServerCorrectionsRemainAuthoritative),
    ("testRejectsNonCodexBucket", account.testRejectsNonCodexBucket),
    ("testRejectsInvalidExpiredAndUnsupportedWindows", account.testRejectsInvalidExpiredAndUnsupportedWindows),
    ("testFreshnessExpiresAtResetOrAfterFifteenMinutes", account.testFreshnessExpiresAtResetOrAfterFifteenMinutes)
]
for (name, test) in accountTests { test(); print("PASS \(name)") }
let local = LocalQuotaReaderTests()
let localTests: [(String, () throws -> Void)] = [
    ("testReadsRecentLocalQuotaWithoutCLI", local.testReadsRecentLocalQuotaWithoutCLI),
    ("testNewestObservationWinsOverFileModificationAndReset", local.testNewestObservationWinsOverFileModificationAndReset),
    ("testNestedReceiptsIgnoreNewerSpark", local.testNestedReceiptsIgnoreNewerSpark),
    ("testNewerCorrectionCanIncreaseRemaining", local.testNewerCorrectionCanIncreaseRemaining),
    ("testExpiredNewestDoesNotResurrectOlderWindow", local.testExpiredNewestDoesNotResurrectOlderWindow),
    ("testRejectsOldFutureAndMissingTimestamp", local.testRejectsOldFutureAndMissingTimestamp),
    ("testTruncatedUTF8AndPartialJSONDoNotHideValidTail", local.testTruncatedUTF8AndPartialJSONDoNotHideValidTail),
    ("testOnlyTwelveRecentFilesAreRead", local.testOnlyTwelveRecentFilesAreRead)
]
for (name, test) in localTests { try test(); print("PASS \(name)") }

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
print("All \(refreshTests.count + accountTests.count + localTests.count + layoutTests.count + animationTests.count + windowTests.count + displayTests.count + visibilityTests.count) tests passed.")
