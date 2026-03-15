import CoreData
import Foundation

#if DEBUG
/// Populates the Core Data store with curated sample data for screenshot capture.
enum ScreenshotSampleData {
    static var isScreenshotMode: Bool {
        ProcessInfo.processInfo.arguments.contains("--screenshot-mode")
    }

    /// Clears existing data and inserts polished sample content.
    static func populate(context: NSManagedObjectContext) {
        let entityNames = ["Dose", "ScheduleSlot", "AdherenceRecord", "Medication", "UserSettings"]
        for entityName in entityNames {
            let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let delete = NSBatchDeleteRequest(fetchRequest: fetch)
            delete.resultType = .resultTypeObjectIDs
            if let result = try? context.execute(delete) as? NSBatchDeleteResult,
               let ids = result.result as? [NSManagedObjectID] {
                NSManagedObjectContext.mergeChanges(
                    fromRemoteContextSave: [NSDeletedObjectsKey: ids],
                    into: [context]
                )
            }
        }

        let calendar = Calendar.current
        let now = Date()

        // MARK: - Medications

        let lisinopril = Medication.create(
            in: context, name: "Lisinopril", dosage: "10mg",
            form: .tablet, frequency: .once, instructions: "Take in the morning with water"
        )
        let metformin = Medication.create(
            in: context, name: "Metformin", dosage: "500mg",
            form: .tablet, frequency: .twice, instructions: "Take with meals"
        )
        let vitaminD = Medication.create(
            in: context, name: "Vitamin D3", dosage: "2000 IU",
            form: .capsule, frequency: .once, instructions: "Take with breakfast"
        )
        let atorvastatin = Medication.create(
            in: context, name: "Atorvastatin", dosage: "20mg",
            form: .tablet, frequency: .once, instructions: "Take at bedtime"
        )
        let omeprazole = Medication.create(
            in: context, name: "Omeprazole", dosage: "20mg",
            form: .capsule, frequency: .once, instructions: "Take 30 min before breakfast"
        )

        // MARK: - Today's Doses

        let morningTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: now)!
        let noonTime = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: now)!
        let eveningTime = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: now)!

        // Morning — taken
        let d1 = Dose.create(in: context, medication: lisinopril, scheduledTime: morningTime)
        d1.markTaken()
        let d2 = Dose.create(in: context, medication: vitaminD, scheduledTime: morningTime)
        d2.markTaken()
        let d3 = Dose.create(in: context, medication: omeprazole, scheduledTime: calendar.date(bySettingHour: 7, minute: 30, second: 0, of: now)!)
        d3.markTaken()

        // Noon — taken
        let d4 = Dose.create(in: context, medication: metformin, scheduledTime: noonTime)
        d4.markTaken()

        // Evening — upcoming
        Dose.create(in: context, medication: atorvastatin, scheduledTime: eveningTime)
        Dose.create(in: context, medication: metformin, scheduledTime: calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now)!)

        // MARK: - Schedule Slots

        let allMeds: [(Medication, Int, Int)] = [
            (lisinopril, 8, 0), (vitaminD, 8, 0), (omeprazole, 7, 30),
            (metformin, 12, 0), (atorvastatin, 20, 0),
        ]
        for (med, hour, minute) in allMeds {
            let time = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now)!
            for day in DayOfWeek.allCases {
                ScheduleSlot.create(in: context, medication: med, dayOfWeek: day, timeOfDay: time)
            }
        }
        let metEveTime = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now)!
        for day in DayOfWeek.allCases {
            ScheduleSlot.create(in: context, medication: metformin, dayOfWeek: day, timeOfDay: metEveTime)
        }

        // MARK: - Adherence History (14 days)

        for dayOffset in 1...14 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let scheduled: Int16 = 6
            let taken: Int16 = dayOffset <= 3 ? 6 : (dayOffset <= 7 ? 5 : Int16.random(in: 4...6))

            let pastMorning = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: date)!
            let pastNoon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date)!
            let pastEvening = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: date)!

            for (med, time) in [(lisinopril, pastMorning), (vitaminD, pastMorning), (omeprazole, pastMorning),
                                (metformin, pastNoon), (metformin, pastEvening), (atorvastatin, pastEvening)] {
                let dose = Dose.create(in: context, medication: med, scheduledTime: time)
                dose.markTaken()
            }
            AdherenceRecord.create(in: context, date: date, totalScheduled: scheduled, totalTaken: taken)
        }

        // Today's adherence
        AdherenceRecord.create(in: context, date: now, totalScheduled: 6, totalTaken: 4)

        _ = UserSettings.fetchOrCreate(in: context)
        try? context.save()
    }
}
#endif
