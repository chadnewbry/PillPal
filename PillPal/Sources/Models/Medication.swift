import Foundation

// MARK: - Medication Model

/// Represents a medication with scheduling and accessibility metadata.
public struct Medication: Codable, Identifiable, Equatable {
    public let id: UUID
    public var name: String
    public var dosage: String
    public var instructions: String
    public var pronunciationGuide: String?
    public var schedule: MedicationSchedule
    public var isActive: Bool
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        dosage: String,
        instructions: String = "",
        pronunciationGuide: String? = nil,
        schedule: MedicationSchedule,
        isActive: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.dosage = dosage
        self.instructions = instructions
        self.pronunciationGuide = pronunciationGuide
        self.schedule = schedule
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Accessible display name including pronunciation if available.
    public var accessibleName: String {
        if let guide = pronunciationGuide {
            return "\(name) (pronounced \(guide))"
        }
        return name
    }

    /// Short description for notification body.
    public var notificationBody: String {
        "Time to take \(dosage) of \(name). \(instructions)"
    }
}

// MARK: - Medication Schedule

public struct MedicationSchedule: Codable, Equatable {
    public var frequency: Frequency
    public var times: [ScheduleTime]
    public var weekdayOverrides: [Int: [ScheduleTime]]?
    public var startDate: Date
    public var endDate: Date?

    public init(
        frequency: Frequency,
        times: [ScheduleTime],
        weekdayOverrides: [Int: [ScheduleTime]]? = nil,
        startDate: Date = Date(),
        endDate: Date? = nil
    ) {
        self.frequency = frequency
        self.times = times
        self.weekdayOverrides = weekdayOverrides
        self.startDate = startDate
        self.endDate = endDate
    }

    public enum Frequency: String, Codable, CaseIterable {
        case daily
        case twiceDaily
        case threeTimesDaily
        case weekly
        case biweekly
        case monthly
        case asNeeded
        case custom
    }
}

// MARK: - Schedule Time

public struct ScheduleTime: Codable, Equatable, Comparable {
    public var hour: Int
    public var minute: Int
    public var label: String?

    public init(hour: Int, minute: Int, label: String? = nil) {
        self.hour = hour
        self.minute = minute
        self.label = label
    }

    public static func < (lhs: ScheduleTime, rhs: ScheduleTime) -> Bool {
        if lhs.hour != rhs.hour { return lhs.hour < rhs.hour }
        return lhs.minute < rhs.minute
    }

    public var displayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let date = Calendar.current.date(from: components) ?? Date()
        return formatter.string(from: date)
    }
}

// MARK: - Dose Record

public struct DoseRecord: Codable, Identifiable, Equatable {
    public let id: UUID
    public let medicationId: UUID
    public let scheduledTime: Date
    public var status: DoseStatus
    public var actualTime: Date?
    public var snoozedUntil: Date?
    public var escalationLevel: Int

    public init(
        id: UUID = UUID(),
        medicationId: UUID,
        scheduledTime: Date,
        status: DoseStatus = .pending,
        actualTime: Date? = nil,
        snoozedUntil: Date? = nil,
        escalationLevel: Int = 0
    ) {
        self.id = id
        self.medicationId = medicationId
        self.scheduledTime = scheduledTime
        self.status = status
        self.actualTime = actualTime
        self.snoozedUntil = snoozedUntil
        self.escalationLevel = escalationLevel
    }

    public enum DoseStatus: String, Codable {
        case pending
        case taken
        case snoozed
        case missed
        case dismissed
    }
}

// MARK: - Family Contact

public struct FamilyContact: Codable, Identifiable, Equatable {
    public let id: UUID
    public var name: String
    public var relationship: String
    public var notifyOnMissedDose: Bool
    public var notifyAfterMinutes: Int

    public init(
        id: UUID = UUID(),
        name: String,
        relationship: String,
        notifyOnMissedDose: Bool = true,
        notifyAfterMinutes: Int = 30
    ) {
        self.id = id
        self.name = name
        self.relationship = relationship
        self.notifyOnMissedDose = notifyOnMissedDose
        self.notifyAfterMinutes = notifyAfterMinutes
    }
}

// MARK: - User Preferences

public struct ReminderPreferences: Codable, Equatable {
    public var travelModeEnabled: Bool
    public var travelTimeZone: TimeZone?
    public var holidayModeEnabled: Bool
    public var holidayModeEndDate: Date?
    public var snoozeIntervalMinutes: Int
    public var maxEscalationLevel: Int
    public var escalationIntervalMinutes: Int
    public var useCustomSounds: Bool
    public var highContrastNotifications: Bool
    public var voiceAnnouncementsEnabled: Bool
    public var largeTextEnabled: Bool
    public var familyContacts: [FamilyContact]

    public init(
        travelModeEnabled: Bool = false,
        travelTimeZone: TimeZone? = nil,
        holidayModeEnabled: Bool = false,
        holidayModeEndDate: Date? = nil,
        snoozeIntervalMinutes: Int = 10,
        maxEscalationLevel: Int = 3,
        escalationIntervalMinutes: Int = 15,
        useCustomSounds: Bool = true,
        highContrastNotifications: Bool = false,
        voiceAnnouncementsEnabled: Bool = false,
        largeTextEnabled: Bool = false,
        familyContacts: [FamilyContact] = []
    ) {
        self.travelModeEnabled = travelModeEnabled
        self.travelTimeZone = travelTimeZone
        self.holidayModeEnabled = holidayModeEnabled
        self.holidayModeEndDate = holidayModeEndDate
        self.snoozeIntervalMinutes = snoozeIntervalMinutes
        self.maxEscalationLevel = maxEscalationLevel
        self.escalationIntervalMinutes = escalationIntervalMinutes
        self.useCustomSounds = useCustomSounds
        self.highContrastNotifications = highContrastNotifications
        self.voiceAnnouncementsEnabled = voiceAnnouncementsEnabled
        self.largeTextEnabled = largeTextEnabled
        self.familyContacts = familyContacts
    }
}
