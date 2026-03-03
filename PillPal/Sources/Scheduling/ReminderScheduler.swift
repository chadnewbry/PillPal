import Foundation

// MARK: - Reminder Scheduler

/// Coordinates scheduling of medication reminders with smart adjustments.
public final class ReminderScheduler: ObservableObject {

    private let notificationManager: NotificationManager
    private let adherenceTracker: AdherenceTracker
    private var preferences: ReminderPreferences

    public init(
        notificationManager: NotificationManager = .shared,
        adherenceTracker: AdherenceTracker = AdherenceTracker(),
        preferences: ReminderPreferences = ReminderPreferences()
    ) {
        self.notificationManager = notificationManager
        self.adherenceTracker = adherenceTracker
        self.preferences = preferences
    }

    // MARK: - Schedule Management

    /// Reschedule all reminders for a list of medications.
    public func rescheduleAll(medications: [Medication]) async {
        for medication in medications where medication.isActive {
            do {
                try await notificationManager.scheduleAllReminders(for: medication)
            } catch {
                print("Failed to schedule reminders for \(medication.name): \(error)")
            }
        }
    }

    /// Handle a taken dose — cancel escalations, record adherence.
    public func markDoseTaken(
        medication: Medication,
        scheduledTime: Date
    ) async -> DoseRecord {
        var record = DoseRecord(
            medicationId: medication.id,
            scheduledTime: scheduledTime,
            status: .taken,
            actualTime: Date()
        )
        adherenceTracker.recordDose(record)
        await notificationManager.removeReminders(for: medication.id)
        // Re-schedule future reminders
        try? await notificationManager.scheduleAllReminders(for: medication)
        return record
    }

    /// Handle a snoozed dose.
    public func snoozeDose(
        medication: Medication,
        minutes: Int? = nil
    ) async -> DoseRecord {
        let snoozeMin = minutes ?? preferences.snoozeIntervalMinutes
        let snoozeUntil = Date().addingTimeInterval(TimeInterval(snoozeMin * 60))

        var record = DoseRecord(
            medicationId: medication.id,
            scheduledTime: Date(),
            status: .snoozed,
            snoozedUntil: snoozeUntil
        )
        adherenceTracker.recordDose(record)

        try? await notificationManager.scheduleSnooze(
            for: medication,
            minutes: snoozeMin
        )

        return record
    }

    /// Handle escalation for a missed dose.
    public func escalateMissedDose(
        medication: Medication,
        currentRecord: DoseRecord
    ) async {
        let newLevel = currentRecord.escalationLevel + 1
        try? await notificationManager.scheduleEscalatedReminder(
            for: medication,
            doseRecord: currentRecord,
            level: newLevel
        )
    }

    // MARK: - Smart Adjustments

    /// Get optimized schedule times based on adherence patterns.
    public func suggestOptimalTimes(
        for medication: Medication
    ) -> [ScheduleTime] {
        let patterns = adherenceTracker.analyzePatterns(for: medication.id)

        guard !patterns.bestTakeWindows.isEmpty else {
            return medication.schedule.times
        }

        return patterns.bestTakeWindows.map { window in
            ScheduleTime(
                hour: window.hour,
                minute: window.minute,
                label: window.label
            )
        }
    }

    /// Check if holiday mode should suppress reminders.
    public func shouldSuppressReminder() -> Bool {
        if preferences.holidayModeEnabled {
            if let endDate = preferences.holidayModeEndDate, Date() > endDate {
                preferences.holidayModeEnabled = false
                return false
            }
            return true
        }
        return false
    }

    // MARK: - Preferences

    public func updatePreferences(_ prefs: ReminderPreferences) {
        self.preferences = prefs
        notificationManager.updatePreferences(prefs)
    }
}
