import SwiftUI

struct TimeOfDaySectionView: View {
    let timeOfDay: TimeOfDay
    let doses: [Dose]
    let onTake: (Dose) -> Void
    let onSkip: (Dose) -> Void
    let onTap: (Dose) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 10) {
                Image(systemName: timeOfDay.symbolName)
                    .font(.title3)
                    .foregroundStyle(timeOfDay.color)
                    .frame(width: 32, height: 32)
                    .accessibilityHidden(true)

                Text(timeOfDay.rawValue)
                    .font(.title2.bold())

                Spacer()

                if !doses.isEmpty {
                    let taken = doses.filter(\.isTaken).count
                    Text("\(taken)/\(doses.count)")
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("\(taken) of \(doses.count) taken")
                }
            }
            .padding(.horizontal, 4)

            if doses.isEmpty {
                emptyStateView
            } else {
                ForEach(doses, id: \.objectID) { dose in
                    MedicationCardView(
                        dose: dose,
                        onTake: { onTake(dose) },
                        onSkip: { onSkip(dose) },
                        onTap: { onTap(dose) }
                    )
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private var emptyStateView: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle")
                    .font(.title)
                    .foregroundStyle(.green.opacity(0.6))
                Text("No medications scheduled")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 20)
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No medications scheduled for \(timeOfDay.rawValue)")
    }
}

#Preview {
    TimeOfDaySectionView(
        timeOfDay: .morning,
        doses: [],
        onTake: { _ in },
        onSkip: { _ in },
        onTap: { _ in }
    )
    .padding()
}
