import CoreData
import Foundation

extension Medication {
    var formEnum: MedicationForm {
        get { MedicationForm(rawValue: form) ?? .tablet }
        set { form = newValue.rawValue }
    }

    var frequencyEnum: DosingFrequency {
        get { DosingFrequency(rawValue: frequency) ?? .once }
        set { frequency = newValue.rawValue }
    }

    var sortedDoses: [Dose] {
        let set = doses as? Set<Dose> ?? []
        return set.sorted { ($0.scheduledTime ?? .distantPast) < ($1.scheduledTime ?? .distantPast) }
    }

    var sortedScheduleSlots: [ScheduleSlot] {
        let set = scheduleSlots as? Set<ScheduleSlot> ?? []
        return set.sorted {
            if $0.dayOfWeek != $1.dayOfWeek {
                return $0.dayOfWeek < $1.dayOfWeek
            }
            return ($0.timeOfDay ?? .distantPast) < ($1.timeOfDay ?? .distantPast)
        }
    }

    /// Doses scheduled for a specific date
    func doses(for date: Date) -> [Dose] {
        let calendar = Calendar.current
        return sortedDoses.filter { dose in
            guard let scheduled = dose.scheduledTime else { return false }
            return calendar.isDate(scheduled, inSameDayAs: date)
        }
    }

    /// Schedule slots for a specific day of the week
    func scheduleSlots(for day: DayOfWeek) -> [ScheduleSlot] {
        sortedScheduleSlots.filter { $0.dayOfWeek == day.rawValue && $0.isEnabled }
    }

    /// Adherence rate for a given date range
    func adherenceRate(from startDate: Date, to endDate: Date) -> Double {
        let calendar = Calendar.current
        let relevantDoses = sortedDoses.filter { dose in
            guard let scheduled = dose.scheduledTime else { return false }
            return scheduled >= startDate && scheduled <= endDate
        }
        guard !relevantDoses.isEmpty else { return 0 }
        let taken = relevantDoses.filter { $0.isTaken }.count
        return Double(taken) / Double(relevantDoses.count)
    }

    // MARK: - Accessibility

    var accessibilityDescription: String {
        let formText = formEnum.accessibilityLabel
        let freqText = frequencyEnum.accessibilityLabel
        return "\(name ?? "Unknown"), \(dosage ?? ""), \(formText), \(freqText)"
    }

    // MARK: - Validation

    var isValid: Bool {
        guard let name = name, !name.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        guard let dosage = dosage, !dosage.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        return timesPerDay >= 0
    }

    // MARK: - Factory

    @discardableResult
    static func create(
        in context: NSManagedObjectContext,
        name: String,
        dosage: String,
        form: MedicationForm = .tablet,
        frequency: DosingFrequency = .once,
        timesPerDay: Int16? = nil,
        instructions: String? = nil
    ) -> Medication {
        let medication = Medication(context: context)
        medication.id = UUID()
        medication.name = name
        medication.dosage = dosage
        medication.form = form.rawValue
        medication.frequency = frequency.rawValue
        medication.timesPerDay = timesPerDay ?? frequency.defaultTimesPerDay
        medication.instructions = instructions
        medication.isActive = true
        medication.createdAt = Date()
        medication.updatedAt = Date()
        return medication
    }
}
