import SwiftUI

@main
struct PillPalApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var storeManager = StoreManager()
    @StateObject private var premiumManager = PremiumManager()

    init() {
        #if DEBUG
        if ScreenshotSampleData.isScreenshotMode {
            ScreenshotSampleData.populate(context: persistenceController.viewContext)
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.viewContext)
                .environmentObject(storeManager)
                .environmentObject(premiumManager)
        }
    }
}
