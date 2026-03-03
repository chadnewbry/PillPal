import Foundation

// MARK: - Medication Form

enum MedicationForm: Int16, CaseIterable, Identifiable {
    case tablet = 0
    case capsule = 1
    case liquid = 2
    case injection = 3
    case topical = 4
    case inhaler = 5
    case drops = 6
    case patch = 7
    case suppository = 8
    case other = 9

    var id: Int16 { rawValue }

    var displayName: String {
        switch self {
        case .tablet: "Tablet"
        case .capsule: "Capsule"
        case .liquid: "Liquid"
        case .injection: "Injection"
        case .topical: "Topical"
        case .inhaler: "Inhaler"
        case .drops: "Drops"
        case .patch: "Patch"
        case .suppository: "Suppository"
        case .other: "Other"
        }
    }

    var symbolName: String {
        switch self {
        case .tablet: "pills.fill"
        case .capsule: "capsule.fill"
        case .liquid: "drop.fill"
        case .injection: "syringe.fill"
        case .topical: "hand.raised.fill"
        case .inhaler: "lungs.fill"
        case .drops: "drop.fill"
        case .patch: "bandage.fill"
        case .suppository: "pill.fill"
        case .other: "cross.vial.fill"
        }
    }

    var accessibilityLabel: String {
        "\(displayName) form medication"
    }
}

// MARK: - Dosing Frequency

enum DosingFrequency: Int16, CaseIterable, Identifiable {
    case once = 0        // QD - Once daily
    case twice = 1       // BID - Twice daily
    case thrice = 2      // TID - Three times daily
    case fourTimes = 3   // QID - Four times daily
    case asNeeded = 4    // PRN - As needed
    case everyOtherDay = 5
    case weekly = 6
    case custom = 7

    var id: Int16 { rawValue }

    var displayName: String {
        switch self {
        case .once: "Once daily (QD)"
        case .twice: "Twice daily (BID)"
        case .thrice: "Three times daily (TID)"
        case .fourTimes: "Four times daily (QID)"
        case .asNeeded: "As needed (PRN)"
        case .everyOtherDay: "Every other day"
        case .weekly: "Weekly"
        case .custom: "Custom"
        }
    }

    var shortName: String {
        switch self {
        case .once: "QD"
        case .twice: "BID"
        case .thrice: "TID"
        case .fourTimes: "QID"
        case .asNeeded: "PRN"
        case .everyOtherDay: "Q2D"
        case .weekly: "QW"
        case .custom: "Custom"
        }
    }

    /// Default number of times per day for this frequency
    var defaultTimesPerDay: Int16 {
        switch self {
        case .once: 1
        case .twice: 2
        case .thrice: 3
        case .fourTimes: 4
        case .asNeeded: 0
        case .everyOtherDay: 1
        case .weekly: 1
        case .custom: 1
        }
    }

    var accessibilityLabel: String {
        displayName
    }
}

// MARK: - Day of Week

enum DayOfWeek: Int16, CaseIterable, Identifiable {
    case sunday = 0
    case monday = 1
    case tuesday = 2
    case wednesday = 3
    case thursday = 4
    case friday = 5
    case saturday = 6

    var id: Int16 { rawValue }

    var displayName: String {
        switch self {
        case .sunday: "Sunday"
        case .monday: "Monday"
        case .tuesday: "Tuesday"
        case .wednesday: "Wednesday"
        case .thursday: "Thursday"
        case .friday: "Friday"
        case .saturday: "Saturday"
        }
    }

    var shortName: String {
        String(displayName.prefix(3))
    }
}

// MARK: - App Theme

enum AppTheme: Int16, CaseIterable, Identifiable {
    case system = 0
    case light = 1
    case dark = 2

    var id: Int16 { rawValue }

    var displayName: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }
}
