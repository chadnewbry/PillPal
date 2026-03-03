import CoreData
import os.log

/// Manages the Core Data stack with CloudKit sync support.
final class PersistenceController: @unchecked Sendable {
    static let shared = PersistenceController()

    /// In-memory store for SwiftUI previews and testing
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        // Seed sample data for previews
        let med = Medication.create(
            in: context,
            name: "Lisinopril",
            dosage: "10mg",
            form: .tablet,
            frequency: .once,
            instructions: "Take in the morning with water"
        )
        let med2 = Medication.create(
            in: context,
            name: "Metformin",
            dosage: "500mg",
            form: .tablet,
            frequency: .twice,
            instructions: "Take with meals"
        )

        // Sample doses
        let now = Date()
        let dose1 = Dose.create(in: context, medication: med, scheduledTime: now)
        dose1.markTaken()
        Dose.create(in: context, medication: med2, scheduledTime: now)

        // Sample schedule slots
        for day in DayOfWeek.allCases {
            ScheduleSlot.create(in: context, medication: med, dayOfWeek: day, timeOfDay: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: now)!)
        }

        // Sample adherence
        AdherenceRecord.create(in: context, date: now, totalScheduled: 3, totalTaken: 2)

        _ = UserSettings.fetchOrCreate(in: context)

        try? context.save()
        return controller
    }()

    let container: NSPersistentCloudKitContainer

    private let logger = Logger(subsystem: "com.chadnewbry.pillpal", category: "persistence")

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "PillPal")

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        } else {
            guard let description = container.persistentStoreDescriptions.first else {
                fatalError("No persistent store descriptions found")
            }
            // Enable CloudKit sync
            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.com.chadnewbry.pillpal"
            )
            // Enable persistent history tracking for CloudKit sync
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        }

        container.loadPersistentStores { [weak self] _, error in
            if let error = error as NSError? {
                self?.logger.error("Core Data load error: \(error), \(error.userInfo)")
                #if DEBUG
                fatalError("Core Data load error: \(error)")
                #endif
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.undoManager = nil
        container.viewContext.shouldDeleteInaccessibleFaults = true
    }

    // MARK: - Convenience

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    /// Creates a background context for heavy operations
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    /// Save the view context if there are changes
    func save() {
        let context = viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            logger.error("Save error: \(nsError), \(nsError.userInfo)")
            #if DEBUG
            fatalError("Save error: \(nsError)")
            #endif
        }
    }

    /// Save a given context
    func save(context: NSManagedObjectContext) {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            logger.error("Save error: \(nsError), \(nsError.userInfo)")
        }
    }
}
