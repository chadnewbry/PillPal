import CoreData
import Foundation

extension Dose {
    var isOverdue: Bool {
        guard !isTaken, let scheduled = scheduledTime else { return false }
        return scheduled < Date()
    }

    var isUpcoming: Bool {
        guard !isTaken, let scheduled = scheduledTime else { return false }
        return scheduled > Date()
    }

    var accessibilityDescription: String {
        let medName = medication?.name ?? "Unknown"
        let status = isTaken ? "taken" : (isOverdue ? "overdue" : "upcoming")
        let timeText: String
        if let scheduled = scheduledTime {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            timeText = formatter.string(from: scheduled)
        } else {
            timeText = "unscheduled"
        }
        return "\(medName) dose at \(timeText), \(status)"
    }

    /// Mark this dose as taken at the current time
    func markTaken() {
        isTaken = true
        actualTimeTaken = Date()
    }

    /// Mark this dose as not taken
    func markUntaken() {
        isTaken = false
        actualTimeTaken = nil
    }

    // MARK: - Factory

    @discardableResult
    static func create(
        in context: NSManagedObjectContext,
        medication: Medication,
        scheduledTime: Date
    ) -> Dose {
        let dose = Dose(context: context)
        dose.id = UUID()
        dose.medication = medication
        dose.scheduledTime = scheduledTime
        dose.isTaken = false
        dose.createdAt = Date()
        return dose
    }
}
