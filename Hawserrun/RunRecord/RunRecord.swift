import Foundation

struct RunRecord: Codable, Equatable, Sendable {
    var bestScore: Int
    var highestChapter: Int
    var peakCargo: Int
    var lastPlayedDayKey: Int

    static let empty = RunRecord(bestScore: 0, highestChapter: 0, peakCargo: 0, lastPlayedDayKey: 0)
}

enum DayKey {
    /// Integer `YYYYMMDD` in the Gregorian calendar at UTC.
    static func make(_ date: Date = Date()) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return (parts.year ?? 0) * 10_000 + (parts.month ?? 0) * 100 + (parts.day ?? 0)
    }
}

/// One JSON root under a single `UserDefaults` key. Writes are debounced off the frame loop.
@MainActor
final class RunRecordStore: ObservableObject {
    static let storageKey = "hsr.runrecord.v1"
    static let demoKey = "hsr.demo.v1"
    static let onboardingKey = "hsr.onboarding.complete"

    @Published private(set) var record: RunRecord
    private let defaults: UserDefaults
    private let debounce: TimeInterval
    private var pending: DispatchWorkItem?

    init(defaults: UserDefaults = .standard, debounce: TimeInterval = 0.4) {
        self.defaults = defaults
        self.debounce = debounce
        if let data = defaults.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode(RunRecord.self, from: data) {
            record = decoded
        } else {
            record = .empty
        }
    }

    func current() -> RunRecord {
        record
    }

    /// Simulator cold launch seeds a best run and marks the deck ready. Devices stay empty.
    func prepareColdLaunch() {
        #if targetEnvironment(simulator)
        seedDemoIfNeeded()
        defaults.set(true, forKey: Self.onboardingKey)
        #endif
    }

    func seedDemoIfNeeded() {
        guard defaults.object(forKey: Self.demoKey) == nil else { return }
        record = RunRecord(bestScore: 240, highestChapter: 1, peakCargo: 1, lastPlayedDayKey: DayKey.make())
        defaults.set(true, forKey: Self.demoKey)
        write()
    }

    func noteFinishedRun(score: Int, chapter: Int, cargo: Int, now: Date = Date()) {
        record.bestScore = max(record.bestScore, score)
        record.highestChapter = max(record.highestChapter, chapter)
        record.peakCargo = max(record.peakCargo, cargo)
        record.lastPlayedDayKey = DayKey.make(now)
        scheduleSave()
    }

    func flush() {
        pending?.cancel()
        pending = nil
        write()
    }

    func resetAllData() {
        pending?.cancel()
        pending = nil
        record = .empty
        defaults.removeObject(forKey: Self.storageKey)
        defaults.removeObject(forKey: Self.demoKey)
    }

    private func scheduleSave() {
        pending?.cancel()
        if debounce <= 0 {
            write()
            return
        }
        let work = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated {
                self?.write()
            }
        }
        pending = work
        DispatchQueue.main.asyncAfter(deadline: .now() + debounce, execute: work)
    }

    private func write() {
        guard let data = try? JSONEncoder().encode(record) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }
}
