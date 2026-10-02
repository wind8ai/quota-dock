import Foundation

// Built without optimization: native preconditions fail the process on a regression.
let reader = QuotaReaderTests()
let readerTests: [(String, () throws -> Void)] = [
    ("testReadsMainPrimaryAndIgnoresNewerSpark", reader.testReadsMainPrimaryAndIgnoresNewerSpark),
    ("testSupportsNestedRateLimits", reader.testSupportsNestedRateLimits),
    ("testUsesLastValidEventWithinFile", reader.testUsesLastValidEventWithinFile),
    ("testNewResetCycleWinsOverNewerObservationOfOldCycle", reader.testNewResetCycleWinsOverNewerObservationOfOldCycle),
    ("testWithin120SecondsUsesNewestObservation", reader.testWithin120SecondsUsesNewestObservation),
    ("testClampsAndPreservesFractionalPercent", reader.testClampsAndPreservesFractionalPercent),
    ("testMissingOrInvalidDataReturnsNil", reader.testMissingOrInvalidDataReturnsNil),
    ("testFallbackToFileModificationDate", reader.testFallbackToFileModificationDate),
    ("testOnlySearchesTwelveMostRecentlyModifiedFiles", reader.testOnlySearchesTwelveMostRecentlyModifiedFiles),
    ("testReadsTailOfLargeFile", reader.testReadsTailOfLargeFile)
]
for (name, test) in readerTests {
    try reader.setUp()
    defer { try! reader.tearDown() }
    try test()
    print("PASS \(name)")
}

let stabilizer = QuotaStabilizerTests()
let stabilizerTests: [(String, () throws -> Void)] = [
    ("testEmptyCacheShowsUnknown", stabilizer.testEmptyCacheShowsUnknown),
    ("testSameCycleDecreasesButDoesNotIncrease", stabilizer.testSameCycleDecreasesButDoesNotIncrease),
    ("testJitterBoundaryDoesNotResetCache", stabilizer.testJitterBoundaryDoesNotResetCache),
    ("testNewCycleCanIncreaseQuotaAndOldCycleCannotReplaceIt", stabilizer.testNewCycleCanIncreaseQuotaAndOldCycleCannotReplaceIt),
    ("testCacheSurvivesRecreationAndMissingRead", stabilizer.testCacheSurvivesRecreationAndMissingRead),
    ("testReadsLegacyV2CacheSchema", stabilizer.testReadsLegacyV2CacheSchema),
    ("testCorruptOrInvalidCacheIsIgnored", stabilizer.testCorruptOrInvalidCacheIsIgnored),
    ("testHistoryIsBoundedAndEqualObservationDoesNotAppend", stabilizer.testHistoryIsBoundedAndEqualObservationDoesNotAppend),
    ("testFractionalCacheSurvivesRestartAndOnlyDecreases", stabilizer.testFractionalCacheSurvivesRestartAndOnlyDecreases),
    ("testLegacyRoundingCanBeCorrectedOnceWithinHalfPoint", stabilizer.testLegacyRoundingCanBeCorrectedOnceWithinHalfPoint)
]
for (name, test) in stabilizerTests {
    stabilizer.setUp()
    defer { stabilizer.tearDown() }
    try test()
    print("PASS \(name)")
}

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

print("All \(readerTests.count + stabilizerTests.count + layoutTests.count + animationTests.count + windowTests.count + displayTests.count) tests passed.")
