import Foundation
import UserNotifications

// MARK: - Notification Manager

/// Manages all medication reminder notifications with accessibility support.
public final class NotificationManager: NSObject, ObservableObject {

    public static let shared = NotificationManager()

    // MARK: - Notification Categories & Actions
    public static let medicationCategoryId = "MEDICATION_REMINDER"
    public static let takenActionId = "TAKEN_ACTION"
    public static let snoozeActionId = "SNOOZE_ACTION"
    public static let dismissActionId = "DISMISS_ACTION"

    // Custom sound names
    public static let gentleReminderSound = "gentle_reminder"
    public static let urgentReminderSound = "urgent_reminder"
    public static let escalatedReminderSound = "escalated_reminder"

    @Published public var isAuthorized = false
    @Published public var pendingNotifications: [UNNotificationRequest] = []

    private let center = UNUserNotificationCenter.current()
    private var preferences = ReminderPreferences()

    private override init() {
        super.init()
        center.delegate = self
        registerCategories()
    }

    // MARK: - Authorization

    /// Request notification permissions.
    public func requestAuthorization() async throws -> Bool {
        let granted = try await center.requestAuthorization(
            options: [.alert, .sound, .badge, .criticalAlert]
        )
        await MainActor.run { self.isAuthorized = granted }
        return granted
    }

    // MARK: - Register Categories with Accessible Actions

    private func registerCategories() {
        let takenAction = UNNotificationAction(
            identifier: Self.takenActionId,
            title: "I Took It ✅",
            options: [.foreground]
        )

        let snoozeAction = UNNotificationAction(
            identifier: Self.snoozeActionId,
            title: "Snooze ⏰",
            options: []
        )

        let dismissAction = UNNotificationAction(
            identifier: Self.dismissActionId,
            title: "Dismiss",
            options: [.destructive]
        )

        let category = UNNotificationCategory(
            identifier: Self.medicationCategoryId,
            actions: [takenAction, snoozeAction, dismissAction],
            intentIdentifiers: [],
            hiddenPreviewsBodyPlaceholder: "Medication Reminder",
            options: [.customDismissAction]
        )

        center.setNotificationCategories([category])
    }

    // MARK: - Schedule Notification

    /// Schedule a medication reminder notification.
    public func scheduleReminder(
        for medication: Medication,
        at time: ScheduleTime,
        on date: Date? = nil,
        escalationLevel: Int = 0
    ) async throws {
        let content = buildNotificationContent(
            for: medication,
            escalationLevel: escalationLevel
        )

        let trigger = buildTrigger(
            time: time,
            date: date,
            medication: medication
        )

        let identifier = notificationId(
            medicationId: medication.id,
            time: time,
            escalation: escalationLevel
        )

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        try await center.add(request)
    }

    /// Schedule all reminders for a medication based on its schedule.
    public func scheduleAllReminders(for medication: Medication) async throws {
        // Remove existing notifications for this medication
        await removeReminders(for: medication.id)

        guard medication.isActive else { return }

        let times = effectiveTimes(for: medication)
        for time in times {
            try await scheduleReminder(for: medication, at: time)
        }
    }

    /// Schedule an escalated reminder for a missed dose.
    public func scheduleEscalatedReminder(
        for medication: Medication,
        doseRecord: DoseRecord,
        level: Int
    ) async throws {
        guard level <= preferences.maxEscalationLevel else {
            // Max escalation reached — notify family if configured
            await notifyFamilyContacts(medication: medication, doseRecord: doseRecord)
            return
        }

        let content = buildNotificationContent(
            for: medication,
            escalationLevel: level
        )

        let interval = TimeInterval(preferences.escalationIntervalMinutes * 60)
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: interval,
            repeats: false
        )

        let identifier = "escalation-\(medication.id)-\(level)-\(UUID().uuidString)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        try await center.add(request)
    }

    /// Schedule a snooze reminder.
    public func scheduleSnooze(
        for medication: Medication,
        minutes: Int? = nil
    ) async throws {
        let interval = TimeInterval((minutes ?? preferences.snoozeIntervalMinutes) * 60)

        let content = buildNotificationContent(for: medication, escalationLevel: 0)
        content.title = "Snoozed Reminder: \(medication.name)"
        content.body = "You snoozed this reminder. \(medication.notificationBody)"

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: interval,
            repeats: false
        )

        let identifier = "snooze-\(medication.id)-\(UUID().uuidString)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        try await center.add(request)
    }

    // MARK: - Remove Notifications

    public func removeReminders(for medicationId: UUID) async {
        let requests = await center.pendingNotificationRequests()
        let ids = requests
            .filter { $0.identifier.contains(medicationId.uuidString) }
            .map(\.identifier)
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    public func removeAllReminders() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Content Builder

    private func buildNotificationContent(
        for medication: Medication,
        escalationLevel: Int
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()

        // Escalation-aware title
        switch escalationLevel {
        case 0:
            content.title = "Medication Reminder"
        case 1:
            content.title = "⚠️ Reminder: Don't forget your medication"
        case 2:
            content.title = "🚨 Important: Medication still not taken"
        default:
            content.title = "🚨🚨 URGENT: Please take your medication"
        }

        // Accessible body text — clear, simple language
        content.body = medication.notificationBody
        content.categoryIdentifier = Self.medicationCategoryId

        // Sound escalation
        if preferences.useCustomSounds {
            switch escalationLevel {
            case 0:
                content.sound = UNNotificationSound(
                    named: UNNotificationSoundName(Self.gentleReminderSound)
                )
            case 1:
                content.sound = UNNotificationSound(
                    named: UNNotificationSoundName(Self.urgentReminderSound)
                )
            default:
                content.sound = .defaultCritical
            }
        } else {
            content.sound = escalationLevel >= 2 ? .defaultCritical : .default
        }

        // User info for handling
        content.userInfo = [
            "medicationId": medication.id.uuidString,
            "medicationName": medication.name,
            "dosage": medication.dosage,
            "escalationLevel": escalationLevel,
            "pronunciationGuide": medication.pronunciationGuide ?? ""
        ]

        // Badge
        content.badge = NSNumber(value: escalationLevel + 1)

        // Thread for grouping
        content.threadIdentifier = "medication-\(medication.id.uuidString)"

        return content
    }

    // MARK: - Trigger Builder

    private func buildTrigger(
        time: ScheduleTime,
        date: Date?,
        medication: Medication
    ) -> UNNotificationTrigger {
        var components = DateComponents()
        components.hour = time.hour
        components.minute = time.minute

        if let date = date {
            let calendar = effectiveCalendar()
            components.year = calendar.component(.year, from: date)
            components.month = calendar.component(.month, from: date)
            components.day = calendar.component(.day, from: date)
            return UNCalendarNotificationTrigger(
                dateMatching: components,
                repeats: false
            )
        }

        // Repeating daily
        return UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: true
        )
    }

    // MARK: - Helpers

    private func notificationId(
        medicationId: UUID,
        time: ScheduleTime,
        escalation: Int
    ) -> String {
        "\(medicationId.uuidString)-\(time.hour):\(time.minute)-e\(escalation)"
    }

    private func effectiveTimes(for medication: Medication) -> [ScheduleTime] {
        let calendar = effectiveCalendar()
        let weekday = calendar.component(.weekday, from: Date())

        if let overrides = medication.schedule.weekdayOverrides,
           let dayTimes = overrides[weekday] {
            return dayTimes
        }
        return medication.schedule.times
    }

    private func effectiveCalendar() -> Calendar {
        var calendar = Calendar.current
        if preferences.travelModeEnabled, let tz = preferences.travelTimeZone {
            calendar.timeZone = tz
        }
        return calendar
    }

    // MARK: - Family Notifications

    private func notifyFamilyContacts(
        medication: Medication,
        doseRecord: DoseRecord
    ) async {
        for contact in preferences.familyContacts where contact.notifyOnMissedDose {
            let content = UNMutableNotificationContent()
            content.title = "Family Alert: Missed Medication"
            content.body = "\(medication.name) dose was missed. Please check in."
            content.sound = .defaultCritical
            content.categoryIdentifier = "FAMILY_ALERT"

            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: TimeInterval(contact.notifyAfterMinutes * 60),
                repeats: false
            )

            let request = UNNotificationRequest(
                identifier: "family-\(contact.id)-\(medication.id)",
                content: content,
                trigger: trigger
            )

            try? await center.add(request)
        }
    }

    // MARK: - Update Preferences

    public func updatePreferences(_ prefs: ReminderPreferences) {
        self.preferences = prefs
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge, .list]
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        guard let medIdString = userInfo["medicationId"] as? String,
              let medicationId = UUID(uuidString: medIdString) else { return }

        switch response.actionIdentifier {
        case Self.takenActionId:
            NotificationCenter.default.post(
                name: .medicationTaken,
                object: nil,
                userInfo: ["medicationId": medicationId]
            )

        case Self.snoozeActionId:
            NotificationCenter.default.post(
                name: .medicationSnoozed,
                object: nil,
                userInfo: ["medicationId": medicationId]
            )

        case Self.dismissActionId, UNNotificationDismissActionIdentifier:
            NotificationCenter.default.post(
                name: .medicationDismissed,
                object: nil,
                userInfo: ["medicationId": medicationId]
            )

        default:
            break
        }
    }
}

// MARK: - Notification Names

public extension Notification.Name {
    static let medicationTaken = Notification.Name("medicationTaken")
    static let medicationSnoozed = Notification.Name("medicationSnoozed")
    static let medicationDismissed = Notification.Name("medicationDismissed")
}
