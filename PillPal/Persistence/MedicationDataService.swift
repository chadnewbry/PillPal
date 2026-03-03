import CoreData
import Foundation
import os.log

/// High-level data service for medication operations with validation and error handling.
final class MedicationDataService: ObservableObject {
    private let persistence: PersistenceController
    private let logger = Logger(subsystem: "com.chadnewbry.pillpal", category: "dataService")

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
    }

    var viewContext: NSManagedObjectContext {
        persistence.viewContext
    }

    // MARK: - Medication CRUD

    @discardableResult
    func addMedication(
        name: String,
        dosage: String,
        form: MedicationForm = .tablet,
        frequency: DosingFrequency = .once,
        timesPerDay: Int16? = nil,
        instructions: String? = nil
    ) throws -> Medication {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw DataServiceError.validationFailed("Medication name cannot be empty")
        }
        guard !dosage.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw DataServiceError.validationFailed("Dosage cannot be empty")
        }

        let med = Medication.create(
            in: viewContext,
            name: name,
            dosage: dosage,
            form: form,
            frequency: frequency,
            timesPerDay: timesPerDay,
            instructions: instructions
        )
        persistence.save()
        logger.info("Created medication: \(name)")
        return med
    }

    func deleteMedication(_ medication: Medication) {
        viewContext.delete(medication)
        persistence.save()
    }

    func fetchActiveMedications() -> [Medication] {
        let request = NSFetchRequest<Medication>(entityName: "Medication")
        request.predicate = NSPredicate(format: "isActive == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Medication.name, ascending: true)]
        do {
            return try viewContext.fetch(request)
        } catch {
            logger.error("Fetch medications error: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Dose Operations

    @discardableResult
    func scheduleDose(for medication: Medication, at time: Date) -> Dose {
        let dose = Dose.create(in: viewContext, medication: medication, scheduledTime: time)
        persistence.save()
        return dose
    }

    func markDoseTaken(_ dose: Dose) {
        dose.markTaken()
        persistence.save()
    }

    func dosesForDate(_ date: Date) -> [Dose] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return [] }

        let request = NSFetchRequest<Dose>(entityName: "Dose")
        request.predicate = NSPredicate(format: "scheduledTime >= %@ AND scheduledTime < %@", start as NSDate, end as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Dose.scheduledTime, ascending: true)]
        do {
            return try viewContext.fetch(request)
        } catch {
            logger.error("Fetch doses error: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Weekly Schedule

    func scheduleSlots(for day: DayOfWeek) -> [ScheduleSlot] {
        let request = NSFetchRequest<ScheduleSlot>(entityName: "ScheduleSlot")
        request.predicate = NSPredicate(format: "dayOfWeek == %d AND isEnabled == YES", day.rawValue)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ScheduleSlot.timeOfDay, ascending: true)]
        do {
            return try viewContext.fetch(request)
        } catch {
            logger.error("Fetch schedule slots error: \(error.localizedDescription)")
            return []
        }
    }

    /// Generate doses for a given date based on schedule slots
    func generateDosesForDate(_ date: Date) {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        // Calendar weekday: 1=Sun, 7=Sat; DayOfWeek: 0=Sun, 6=Sat
        guard let day = DayOfWeek(rawValue: Int16(weekday - 1)) else { return }

        let slots = scheduleSlots(for: day)
        for slot in slots {
            guard let medication = slot.medication, let slotTime = slot.timeOfDay else { continue }

            let timeComponents = calendar.dateComponents([.hour, .minute], from: slotTime)
            guard let scheduledTime = calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                                     minute: timeComponents.minute ?? 0,
                                                     second: 0, of: date) else { continue }

            // Check if dose already exists
            let existing = medication.doses(for: date).contains { dose in
                guard let st = dose.scheduledTime else { return false }
                return abs(st.timeIntervalSince(scheduledTime)) < 60 // within 1 minute
            }
            if !existing {
                Dose.create(in: viewContext, medication: medication, scheduledTime: scheduledTime)
            }
        }
        persistence.save()
    }

    // MARK: - Adherence

    func recordAdherence(for date: Date) -> AdherenceRecord {
        let doses = dosesForDate(date)
        let total = Int16(doses.count)
        let taken = Int16(doses.filter(\.isTaken).count)

        // Update existing or create new
        let request = NSFetchRequest<AdherenceRecord>(entityName: "AdherenceRecord")
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else {
            return AdherenceRecord.create(in: viewContext, date: date, totalScheduled: total, totalTaken: taken)
        }
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", start as NSDate, end as NSDate)

        if let existing = try? viewContext.fetch(request).first {
            existing.totalScheduled = total
            existing.totalTaken = taken
            existing.completionRate = total > 0 ? Double(taken) / Double(total) : 0
            persistence.save()
            return existing
        }

        let record = AdherenceRecord.create(in: viewContext, date: date, totalScheduled: total, totalTaken: taken)
        persistence.save()
        return record
    }

    func adherenceHistory(days: Int = 30) -> [AdherenceRecord] {
        let request = NSFetchRequest<AdherenceRecord>(entityName: "AdherenceRecord")
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        request.predicate = NSPredicate(format: "date >= %@", startDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \AdherenceRecord.date, ascending: false)]
        do {
            return try viewContext.fetch(request)
        } catch {
            logger.error("Fetch adherence error: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Settings

    func fetchSettings() -> UserSettings {
        UserSettings.fetchOrCreate(in: viewContext)
    }
}

// MARK: - Errors

enum DataServiceError: LocalizedError {
    case validationFailed(String)
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .validationFailed(let msg): "Validation error: \(msg)"
        case .saveFailed(let msg): "Save error: \(msg)"
        }
    }
}
