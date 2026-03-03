import CoreData
import Foundation

extension ScheduleSlot {
    var dayOfWeekEnum: DayOfWeek {
        get { DayOfWeek(rawValue: dayOfWeek) ?? .sunday }
        set { dayOfWeek = newValue.rawValue }
    }

    /// Time formatted for display
    var timeString: String {
        guard let time = timeOfDay else { return "" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }

    var accessibilityDescription: String {
        let day = dayOfWeekEnum.displayName
        let med = medication?.name ?? "Unknown"
        return "\(med) on \(day) at \(timeString)"
    }

    // MARK: - Factory

    @discardableResult
    static func create(
        in context: NSManagedObjectContext,
        medication: Medication,
        dayOfWeek: DayOfWeek,
        timeOfDay: Date
    ) -> ScheduleSlot {
        let slot = ScheduleSlot(context: context)
        slot.id = UUID()
        slot.medication = medication
        slot.dayOfWeek = dayOfWeek.rawValue
        slot.timeOfDay = timeOfDay
        slot.isEnabled = true
        return slot
    }
}
