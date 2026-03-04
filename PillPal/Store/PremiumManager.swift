import Foundation
import SwiftUI

/// Tracks free-tier usage and gates premium features.
@MainActor
final class PremiumManager: ObservableObject {

    static let freeUsageLimit = 5

    @AppStorage("medicationsAddedCount") private var medicationsAddedCount: Int = 0
    @Published var showPaywall: Bool = false

    var freeUsesRemaining: Int {
        max(0, Self.freeUsageLimit - medicationsAddedCount)
    }

    /// Call when user adds a medication. Returns true if allowed, false if gated.
    func recordMedicationAdded(isPremium: Bool) -> Bool {
        if isPremium { return true }
        if medicationsAddedCount < Self.freeUsageLimit {
            medicationsAddedCount += 1
            return true
        }
        showPaywall = true
        return false
    }

    /// Check if a premium-only feature should be available.
    func canAccessPremiumFeature(isPremium: Bool) -> Bool {
        if isPremium { return true }
        showPaywall = true
        return false
    }

    /// Reset usage counter (for testing).
    func resetUsage() {
        medicationsAddedCount = 0
    }
}
