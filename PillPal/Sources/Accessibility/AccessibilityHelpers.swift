import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Accessibility Helpers

/// Provides accessibility utilities for medication reminders.
public enum AccessibilityHelpers {

    // MARK: - VoiceOver Announcements

    /// Create a VoiceOver-friendly medication reminder announcement.
    public static func reminderAnnouncement(for medication: Medication) -> String {
        var parts: [String] = []

        parts.append("Medication reminder.")
        parts.append("It's time to take \(medication.dosage) of \(medication.accessibleName).")

        if !medication.instructions.isEmpty {
            parts.append(medication.instructions)
        }

        return parts.joined(separator: " ")
    }

    /// Create an accessible adherence summary.
    public static func adherenceSummary(
        rate: Double,
        streak: Int,
        medicationName: String
    ) -> String {
        let percentage = Int(rate * 100)
        var summary = "Your adherence rate for \(medicationName) is \(percentage) percent."

        if streak > 0 {
            summary += " You have a \(streak) day streak."
        }

        if rate >= 0.95 {
            summary += " Excellent job staying on track!"
        } else if rate >= 0.8 {
            summary += " Good progress. Try to improve consistency."
        } else {
            summary += " Consider setting additional reminders to help you stay on schedule."
        }

        return summary
    }

    // MARK: - Pronunciation Guides

    /// Common medication pronunciation mappings.
    public static let commonPronunciations: [String: String] = [
        "Acetaminophen": "uh-SEE-tuh-MIN-oh-fen",
        "Amoxicillin": "uh-MOX-ih-SIL-in",
        "Atorvastatin": "uh-TOR-vuh-STAT-in",
        "Ciprofloxacin": "SIP-roh-FLOX-uh-sin",
        "Hydrochlorothiazide": "HY-droh-KLOR-oh-THY-uh-zide",
        "Ibuprofen": "eye-BYOO-proh-fen",
        "Levothyroxine": "LEE-voh-thy-ROX-een",
        "Lisinopril": "ly-SIN-oh-pril",
        "Metformin": "met-FOR-min",
        "Metoprolol": "meh-TOH-proh-lol",
        "Omeprazole": "oh-MEP-rah-zole",
        "Pantoprazole": "pan-TOH-prah-zole",
        "Sertraline": "SER-truh-leen",
        "Simvastatin": "sim-vuh-STAT-in",
    ]

    /// Look up or generate a pronunciation guide.
    public static func pronunciationGuide(for medicationName: String) -> String? {
        // Check known pronunciations (case-insensitive)
        for (name, guide) in commonPronunciations {
            if name.lowercased() == medicationName.lowercased() {
                return guide
            }
        }
        return nil
    }

    // MARK: - High Contrast Support

    /// Check if the user has high contrast or bold text enabled.
    public static var isHighContrastEnabled: Bool {
        #if canImport(UIKit)
        return UIAccessibility.isDarkerSystemColorsEnabled
        #else
        return false
        #endif
    }

    /// Check if VoiceOver is running.
    public static var isVoiceOverRunning: Bool {
        #if canImport(UIKit)
        return UIAccessibility.isVoiceOverRunning
        #else
        return false
        #endif
    }

    /// Post a VoiceOver announcement.
    public static func announce(_ message: String) {
        #if canImport(UIKit)
        UIAccessibility.post(
            notification: .announcement,
            argument: message
        )
        #endif
    }

    // MARK: - Dynamic Type Support

    /// Notification body formatted for large text if needed.
    public static func formattedNotificationBody(
        medication: Medication,
        largeText: Bool
    ) -> String {
        if largeText {
            // Shorter, clearer text for large type display
            return "Take \(medication.dosage)\n\(medication.name)"
        }
        return medication.notificationBody
    }
}
