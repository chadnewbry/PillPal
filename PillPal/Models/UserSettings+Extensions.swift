import CoreData
import Foundation

extension UserSettings {
    var themeEnum: AppTheme {
        get { AppTheme(rawValue: theme) ?? .system }
        set { theme = newValue.rawValue }
    }

    // MARK: - Factory / Singleton

    static func fetchOrCreate(in context: NSManagedObjectContext) -> UserSettings {
        let request = NSFetchRequest<UserSettings>(entityName: "UserSettings")
        request.fetchLimit = 1

        if let existing = try? context.fetch(request).first {
            return existing
        }

        let settings = UserSettings(context: context)
        settings.id = UUID()
        settings.notificationsEnabled = true
        settings.reminderMinutesBefore = 15
        settings.soundEnabled = true
        settings.hapticEnabled = true
        settings.theme = AppTheme.system.rawValue
        settings.updatedAt = Date()
        return settings
    }
}
