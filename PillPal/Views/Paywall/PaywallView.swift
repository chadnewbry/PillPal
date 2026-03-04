import SwiftUI

// MARK: - Paywall View

/// Senior-friendly paywall with large text, clear buttons, and trust indicators.
struct PaywallView: View {
    @EnvironmentObject private var storeManager: StoreManager
    @Environment(\.dismiss) private var dismiss
    

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    headerSection
                    freeVsPremiumSection
                    purchaseSection
                    trustSection
                    restoreSection
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
            .navigationTitle("Upgrade PillPal")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .font(.title3.bold())
                        .accessibilityLabel("Close upgrade screen")
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.yellow)
                .accessibilityHidden(true)

            Text("Unlock All Features")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            Text("One simple payment. No subscriptions.\nYours forever.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    // MARK: - Free vs Premium Comparison

    private var freeVsPremiumSection: some View {
        VStack(spacing: 16) {
            Text("What You Get")
                .font(.title2.bold())

            VStack(spacing: 12) {
                premiumFeatureRow("Unlimited medications", icon: "pills.fill")
                premiumFeatureRow("Advanced scheduling", icon: "calendar.badge.clock")
                premiumFeatureRow("Adherence analytics", icon: "chart.line.uptrend.xyaxis")
                premiumFeatureRow("Family sharing", icon: "person.2.fill")
                premiumFeatureRow("Data export & reports", icon: "square.and.arrow.up")
                premiumFeatureRow("Emergency contacts", icon: "phone.fill")
                premiumFeatureRow("Doctor visit prep", icon: "stethoscope")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }

    private func premiumFeatureRow(_ text: String, icon: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.accent)
                .frame(width: 32)
                .accessibilityHidden(true)

            Text(text)
                .font(.title3)

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.green)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(text), included with premium")
    }

    // MARK: - Purchase Button

    private var purchaseSection: some View {
        VStack(spacing: 16) {
            Button {
                Task { await storeManager.purchase() }
            } label: {
                VStack(spacing: 8) {
                    if storeManager.isLoading {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.3)
                    } else {
                        Text("Upgrade Now")
                            .font(.title.bold())

                        if let product = storeManager.premiumProduct {
                            Text(product.displayPrice)
                                .font(.title2)
                        }

                        Text("One-Time Purchase")
                            .font(.callout)
                            .opacity(0.9)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(storeManager.isLoading || storeManager.premiumProduct == nil)
            .accessibilityLabel(purchaseAccessibilityLabel)
            .accessibilityHint("Double tap to purchase PillPal Premium")

            if let error = storeManager.purchaseError {
                Text(error)
                    .font(.callout)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .accessibilityLabel("Error: \(error)")
            }
        }
    }

    private var purchaseAccessibilityLabel: String {
        if let product = storeManager.premiumProduct {
            return "Upgrade to PillPal Premium for \(product.displayPrice). One-time purchase."
        }
        return "Upgrade to PillPal Premium"
    }

    // MARK: - Trust Indicators

    private var trustSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                trustBadge("Apple Pay\nSecured", icon: "lock.shield.fill")
                trustBadge("Family\nSharing", icon: "person.2.circle.fill")
            }
            HStack(spacing: 12) {
                trustBadge("No\nSubscription", icon: "calendar.badge.minus")
                trustBadge("Restore\nAnytime", icon: "arrow.clockwise.circle.fill")
            }
        }
    }

    private func trustBadge(_ text: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .accessibilityElement(children: .combine)
    }

    // MARK: - Restore

    private var restoreSection: some View {
        VStack(spacing: 12) {
            Button {
                Task { await storeManager.restorePurchases() }
            } label: {
                Text("Already purchased? Restore here")
                    .font(.title3)
                    .underline()
            }
            .disabled(storeManager.isLoading)
            .accessibilityLabel("Restore previous purchase")
            .accessibilityHint("Double tap to restore a previous PillPal Premium purchase")

            Text("Purchases are processed by Apple and protected by App Store security.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)
        }
    }
}

// MARK: - Compact Upgrade Banner

/// A small banner that can be placed in any screen to prompt upgrade.
struct UpgradeBanner: View {
    @EnvironmentObject private var storeManager: StoreManager
    @Binding var showPaywall: Bool

    var body: some View {
        if !storeManager.isPremium {
            Button {
                showPaywall = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "star.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.yellow)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Upgrade to Premium")
                            .font(.headline)
                        Text("Unlock all features")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.systemGray6))
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Upgrade to PillPal Premium. Unlock all features.")
            .accessibilityHint("Double tap to see upgrade options")
        }
    }
}

// MARK: - Premium Badge

/// Small badge shown next to premium-only features.
struct PremiumBadge: View {
    var body: some View {
        Text("PRO")
            .font(.caption2.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(Color.accentColor)
            )
            .accessibilityLabel("Premium feature")
    }
}

#Preview {
    PaywallView()
        .environmentObject(StoreManager())
}
