import SwiftUI

struct WeekViewTab: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "calendar")
                    .font(.system(size: 60))
                    .foregroundStyle(.accent)
                    .accessibilityHidden(true)

                Text("Weekly Schedule")
                    .font(.largeTitle.bold())

                Text("Your Monday–Sunday pill schedule will appear here.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Week")
        }
    }
}

#Preview {
    WeekViewTab()
}
