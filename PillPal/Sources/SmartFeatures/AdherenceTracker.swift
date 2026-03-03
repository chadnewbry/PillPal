import Foundation

// MARK: - Adherence Tracker

/// Tracks medication adherence patterns and provides insights.
public final class AdherenceTracker: ObservableObject {

    @Published public var records: [DoseRecord] = []

    private let storageKey = "pillpal_dose_records"

    public init() {
        loadRecords()
    }

    // MARK: - Recording

    public func recordDose(_ record: DoseRecord) {
        records.append(record)
        saveRecords()
    }

    // MARK: - Analysis

    /// Calculate adherence rate for a medication over a period.
    public func adherenceRate(
        for medicationId: UUID,
        days: Int = 30
    ) -> Double {
        let cutoff = Calendar.current.date(
            byAdding: .day, value: -days, to: Date()
        ) ?? Date()

        let relevant = records.filter {
            $0.medicationId == medicationId && $0.scheduledTime >= cutoff
        }

        guard !relevant.isEmpty else { return 1.0 }

        let taken = relevant.filter { $0.status == .taken }.count
        return Double(taken) / Double(relevant.count)
    }

    /// Analyze patterns — when the user typically takes medication.
    public func analyzePatterns(for medicationId: UUID) -> AdherencePatterns {
        let takenRecords = records.filter {
            $0.medicationId == medicationId && $0.status == .taken && $0.actualTime != nil
        }

        guard takenRecords.count >= 7 else {
            return AdherencePatterns(
                averageDelayMinutes: 0,
                bestTakeWindows: [],
                weekdayAdherence: [:],
                streak: currentStreak(for: medicationId)
            )
        }

        let calendar = Calendar.current

        // Average delay from scheduled to actual
        let delays = takenRecords.compactMap { record -> Double? in
            guard let actual = record.actualTime else { return nil }
            return actual.timeIntervalSince(record.scheduledTime) / 60.0
        }
        let avgDelay = delays.isEmpty ? 0 : delays.reduce(0, +) / Double(delays.count)

        // Best take windows — cluster actual times
        let hourBuckets = Dictionary(grouping: takenRecords) { record -> Int in
            guard let actual = record.actualTime else { return 0 }
            return calendar.component(.hour, from: actual)
        }

        let bestWindows = hourBuckets
            .sorted { $0.value.count > $1.value.count }
            .prefix(3)
            .map { hour, records in
                let avgMinute = records.compactMap { $0.actualTime }
                    .map { calendar.component(.minute, from: $0) }
                    .reduce(0, +) / max(records.count, 1)
                return ScheduleTime(hour: hour, minute: avgMinute)
            }

        // Weekday adherence
        var weekdayAdherence: [Int: Double] = [:]
        for weekday in 1...7 {
            let dayRecords = records.filter {
                $0.medicationId == medicationId &&
                calendar.component(.weekday, from: $0.scheduledTime) == weekday
            }
            guard !dayRecords.isEmpty else { continue }
            let taken = dayRecords.filter { $0.status == .taken }.count
            weekdayAdherence[weekday] = Double(taken) / Double(dayRecords.count)
        }

        return AdherencePatterns(
            averageDelayMinutes: avgDelay,
            bestTakeWindows: bestWindows,
            weekdayAdherence: weekdayAdherence,
            streak: currentStreak(for: medicationId)
        )
    }

    /// Current consecutive days streak.
    public func currentStreak(for medicationId: UUID) -> Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = Date()

        while true {
            let dayStart = calendar.startOfDay(for: checkDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

            let dayRecords = records.filter {
                $0.medicationId == medicationId &&
                $0.scheduledTime >= dayStart &&
                $0.scheduledTime < dayEnd
            }

            guard !dayRecords.isEmpty else { break }

            let allTaken = dayRecords.allSatisfy { $0.status == .taken }
            guard allTaken else { break }

            streak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }

        return streak
    }

    // MARK: - Persistence

    private func saveRecords() {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadRecords() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([DoseRecord].self, from: data)
        else { return }
        records = decoded
    }
}

// MARK: - Adherence Patterns

public struct AdherencePatterns {
    public let averageDelayMinutes: Double
    public let bestTakeWindows: [ScheduleTime]
    public let weekdayAdherence: [Int: Double]
    public let streak: Int

    /// Summary for VoiceOver announcement.
    public var accessibleSummary: String {
        let streakText = streak > 0
            ? "You're on a \(streak)-day streak. Keep it up!"
            : "Start your streak today by taking your medication on time."

        let delayText: String
        if averageDelayMinutes < 5 {
            delayText = "You usually take your medication right on time."
        } else if averageDelayMinutes < 30 {
            delayText = "You typically take it about \(Int(averageDelayMinutes)) minutes after the reminder."
        } else {
            delayText = "You tend to delay about \(Int(averageDelayMinutes)) minutes. Consider adjusting your reminder time."
        }

        return "\(streakText) \(delayText)"
    }
}
