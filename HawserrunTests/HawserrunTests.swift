import XCTest
@testable import Hawserrun

@MainActor
final class HawserrunTests: XCTestCase {
    func testFixedSeedClearsTheFirstChunks() {
        let simulation = GameSimulation.fixedSeed()
        XCTAssertGreaterThanOrEqual(simulation.chunksCleared, 3, simulation.diagnostics)
        XCTAssertFalse(simulation.failed, simulation.diagnostics)
        XCTAssertGreaterThan(simulation.score, 0)
        XCTAssertLessThanOrEqual(simulation.chunks.count, Physics.poolCount)
    }

    func testLightEnvelopeIsReachableAndHeavyIsStricter() {
        let light = GameSimulation.flatReach(burden: 0)
        let heavyVelocity = Physics.jumpVelocity * (1 - Physics.tradeoffDelta)
        let heavy = Physics.runSpeed * (2 * heavyVelocity / Physics.gravity) * Physics.reachFactor
        XCTAssertEqual(light, Physics.runSpeed * (2 * Physics.jumpVelocity / Physics.gravity) * 0.85, accuracy: 0.001)
        XCTAssertEqual(GameSimulation.flatReach(burden: 1), heavy, accuracy: 0.001)
        XCTAssertTrue(GameSimulation.reachable(gap: Physics.maxGap, burden: 0, heelPhase: 0))
        XCTAssertTrue(GameSimulation.reachable(gap: Physics.minGap, burden: 1, heelPhase: .pi / 2))
        XCTAssertFalse(GameSimulation.reachable(gap: Physics.maxGap, burden: 1, heelPhase: 0))
        XCTAssertGreaterThan(
            GameSimulation.reachableEnvelope(burden: 0, heelPhase: 0),
            GameSimulation.reachableEnvelope(burden: 1, heelPhase: 0)
        )
        XCTAssertEqual(Physics.gravity, 2200)
        XCTAssertEqual(Physics.runSpeed, 280)
        XCTAssertEqual(Physics.jumpVelocity, 900)
        XCTAssertEqual(Physics.minGap, 70)
        XCTAssertEqual(Physics.maxGap, 160)
        XCTAssertEqual(Physics.velocityScale, 1 - Physics.tradeoffDelta, accuracy: 0.0001)
    }

    func testImpossibleBeatIsRefused() {
        var simulation = GameSimulation.fixedSeed()
        let cleared = simulation.chunksCleared
        XCTAssertTrue(simulation.refuseImpossibleBeat(maxGap: 480, burden: 0, heelPhase: 0))
        XCTAssertEqual(simulation.chunksCleared, cleared)
        XCTAssertTrue(simulation.refuseImpossibleBeat(maxGap: Physics.maxGap, burden: 1, heelPhase: 0))
        XCTAssertFalse(simulation.refuseImpossibleBeat(maxGap: Physics.minGap, burden: 1, heelPhase: .pi / 2))
        let shortened = Physics.nextWindow(window: Physics.window, minWindow: Physics.minWindow, delta: Physics.tradeoffDelta)
        XCTAssertEqual(shortened, max(Physics.minWindow, Physics.window * (1 - Physics.tradeoffDelta)), accuracy: 0.001)
        XCTAssertTrue(Physics.refusesWindow(40))
        XCTAssertFalse(Physics.refusesWindow(shortened))
        XCTAssertTrue(Physics.refusesPocket(height: 900, burden: 1))
        XCTAssertFalse(Physics.refusesPocket(height: 40, burden: 0))
        XCTAssertTrue(Physics.liftClearsGravity(lift: Physics.lift, gravity: Physics.gravity, delta: Physics.tradeoffDelta))
        XCTAssertEqual(
            Physics.tiltedRestitution(restitution: Physics.restitution, delta: Physics.tradeoffDelta),
            Physics.restitution * (1 - Physics.tradeoffDelta),
            accuracy: 0.001
        )
    }

    func testNodeBudgetStaysAtOrUnder400() {
        let simulation = GameSimulation.fixedSeed()
        XCTAssertLessThanOrEqual(simulation.nodeBudget, 400)
        XCTAssertGreaterThan(simulation.nodeBudget, 0)
        XCTAssertLessThanOrEqual(NodeBudget.live(chunkCount: Physics.poolCount), Physics.nodeBudgetCap)
    }

    func testBestScoreRoundTrips() {
        let suite = "hsr.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let store = RunRecordStore(defaults: defaults, debounce: 0)
        var parts = DateComponents()
        parts.year = 2026
        parts.month = 10
        parts.day = 24
        parts.timeZone = TimeZone(secondsFromGMT: 0)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        let day = calendar.date(from: parts) ?? Date()
        store.noteFinishedRun(score: 88, chapter: 3, cargo: 2, now: day)
        store.flush()
        let again = RunRecordStore(defaults: defaults, debounce: 0)
        XCTAssertEqual(again.current().bestScore, 88)
        XCTAssertEqual(again.current().highestChapter, 3)
        XCTAssertEqual(again.current().peakCargo, 2)
        XCTAssertEqual(again.current().lastPlayedDayKey, 20261024)
        store.noteFinishedRun(score: 10, chapter: 1, cargo: 0, now: day)
        store.flush()
        XCTAssertEqual(store.current().bestScore, 88)
        store.resetAllData()
        XCTAssertEqual(store.current().bestScore, 0)
        XCTAssertEqual(store.current().highestChapter, 0)
        XCTAssertEqual(store.current().peakCargo, 0)
        defaults.removePersistentDomain(forName: suite)
    }

    func testReviewLaunchScreenParsesPose() {
        let screen = ReviewLaunch.screen
        if let screen {
            XCTAssertNotNil(ReviewPose(rawValue: screen))
        } else {
            XCTAssertNil(ReviewLaunch.screen)
        }
        XCTAssertNil(ReviewPose(rawValue: "ledger"))
        XCTAssertEqual(ReviewPose.play.rawValue, "play")
        XCTAssertEqual(ReviewPose.allCases.count, 8)
    }
}
