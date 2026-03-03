import XCTest
@testable import PillPal

final class MedicationTests: XCTestCase {

    func testMedicationAccessibleName() {
        let med = Medication(
            name: "Levothyroxine",
            dosage: "50mcg",
            pronunciationGuide: "LEE-voh-thy-ROX-een",
            schedule: MedicationSchedule(
                frequency: .daily,
                times: [ScheduleTime(hour: 8, minute: 0, label: "Morning")]
            )
        )
        XCTAssertEqual(med.accessibleName, "Levothyroxine (pronounced LEE-voh-thy-ROX-een)")
    }

    func testMedicationWithoutPronunciation() {
        let med = Medication(
            name: "Aspirin",
            dosage: "81mg",
            schedule: MedicationSchedule(frequency: .daily, times: [ScheduleTime(hour: 9, minute: 0)])
        )
        XCTAssertEqual(med.accessibleName, "Aspirin")
    }

    func testScheduleTimeComparison() {
        let morning = ScheduleTime(hour: 8, minute: 0)
        let evening = ScheduleTime(hour: 20, minute: 0)
        XCTAssertTrue(morning < evening)
    }

    func testDoseRecordDefaults() {
        let record = DoseRecord(medicationId: UUID(), scheduledTime: Date())
        XCTAssertEqual(record.status, .pending)
        XCTAssertNil(record.actualTime)
        XCTAssertEqual(record.escalationLevel, 0)
    }

    func testReminderPreferencesDefaults() {
        let prefs = ReminderPreferences()
        XCTAssertFalse(prefs.travelModeEnabled)
        XCTAssertFalse(prefs.holidayModeEnabled)
        XCTAssertEqual(prefs.snoozeIntervalMinutes, 10)
        XCTAssertEqual(prefs.maxEscalationLevel, 3)
    }

    func testPronunciationGuide() {
        XCTAssertEqual(AccessibilityHelpers.pronunciationGuide(for: "Metformin"), "met-FOR-min")
        XCTAssertNil(AccessibilityHelpers.pronunciationGuide(for: "UnknownDrug123"))
    }

    func testAdherenceSummary() {
        let summary = AccessibilityHelpers.adherenceSummary(rate: 0.96, streak: 5, medicationName: "Aspirin")
        XCTAssertTrue(summary.contains("96 percent"))
        XCTAssertTrue(summary.contains("5 day streak"))
        XCTAssertTrue(summary.contains("Excellent"))
    }
}
