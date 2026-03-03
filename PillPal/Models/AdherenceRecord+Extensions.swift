import CoreData
import Foundation

extension AdherenceRecord {
    var accessibilityDescription: String {
        let dateText: String
        if let date = date {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            dateText = formatter.string(from: date)
        } else {
            dateText = "Unknown date"
        }
        let pct = Int(completionRate * 100)
        return "\(dateText): \(totalTaken) of \(totalScheduled) taken, \(pct)% adherence"
    }

    // MARK: - Factory

    @discardableResult
    static func create(
        in context: NSManagedObjectContext,
        date: Date,
        totalScheduled: Int16,
        totalTaken: Int16
    ) -> AdherenceRecord {
        let record = AdherenceRecord(context: context)
        record.id = UUID()
        record.date = date
        record.totalScheduled = totalScheduled
        record.totalTaken = totalTaken
        record.completionRate = totalScheduled > 0 ? Double(totalTaken) / Double(totalScheduled) : 0
        record.createdAt = Date()
        return record
    }
}
