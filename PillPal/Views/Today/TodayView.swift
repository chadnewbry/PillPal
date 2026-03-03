import SwiftUI

struct TodayView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "pills.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.accent)
                    .accessibilityHidden(true)

                Text("Today's Medications")
                    .font(.largeTitle.bold())

                Text("Your daily pill organizer will appear here.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Today")
        }
    }
}

#Preview {
    TodayView()
}
