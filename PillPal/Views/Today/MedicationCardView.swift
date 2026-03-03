import SwiftUI

struct MedicationCardView: View {
    let dose: Dose
    let onTake: () -> Void
    let onSkip: () -> Void
    let onTap: () -> Void

    private var medication: Medication? { dose.medication }
    private var isSkipped: Bool { dose.notes == "Skipped" }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Pill icon with color
                pillIcon

                // Medication info
                medicationInfo

                Spacer(minLength: 8)

                // Action buttons
                if !dose.isTaken && !isSkipped {
                    actionButtons
                } else {
                    statusBadge
                }
            }
            .padding(16)
            .background(cardBackground, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(borderColor, lineWidth: dose.isOverdue ? 2 : 0)
            )
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("Double tap for details")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Pill Icon

    private var pillIcon: some View {
        Image(systemName: medication?.formEnum.symbolName ?? "pills.fill")
            .font(.title2)
            .foregroundStyle(.white)
            .frame(width: 52, height: 52)
            .background(pillColor, in: RoundedRectangle(cornerRadius: 14))
            .accessibilityHidden(true)
    }

    private var pillColor: Color {
        if dose.isTaken { return .green }
        if isSkipped { return .gray }
        if dose.isOverdue { return .red }
        return .accentColor
    }

    // MARK: - Medication Info

    private var medicationInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(medication?.name ?? "Unknown")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Text(medication?.dosage ?? "")
                .font(.body)
                .foregroundStyle(.secondary)

            if let scheduled = dose.scheduledTime {
                Text(scheduled.formatted(date: .omitted, time: .shortened))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(dose.isOverdue ? .red : .secondary)
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 8) {
            Button(action: onTake) {
                Image(systemName: "checkmark")
                    .font(.body.bold())
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.green, in: Circle())
            }
            .accessibilityLabel("Take \(medication?.name ?? "medication")")

            Button(action: onSkip) {
                Image(systemName: "xmark")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
                    .background(Color(.systemGray5), in: Circle())
            }
            .accessibilityLabel("Skip \(medication?.name ?? "medication")")
        }
    }

    // MARK: - Status Badge

    private var statusBadge: some View {
        Group {
            if dose.isTaken {
                Label("Taken", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.green)
            } else if isSkipped {
                Label("Skipped", systemImage: "minus.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minWidth: 44, minHeight: 44)
    }

    // MARK: - Styling

    private var cardBackground: Color {
        if dose.isTaken { return Color.green.opacity(0.06) }
        if isSkipped { return Color(.systemGray6) }
        if dose.isOverdue { return Color.red.opacity(0.06) }
        return Color(.secondarySystemGroupedBackground)
    }

    private var borderColor: Color {
        dose.isOverdue ? .red.opacity(0.4) : .clear
    }

    // MARK: - Accessibility

    private var accessibilityDescription: String {
        let name = medication?.name ?? "Unknown medication"
        let dosage = medication?.dosage ?? ""
        let form = medication?.formEnum.displayName ?? ""
        let status: String
        if dose.isTaken {
            status = "taken"
        } else if isSkipped {
            status = "skipped"
        } else if dose.isOverdue {
            status = "overdue"
        } else {
            status = "upcoming"
        }
        let time: String
        if let scheduled = dose.scheduledTime {
            time = "at \(scheduled.formatted(date: .omitted, time: .shortened))"
        } else {
            time = ""
        }
        return "\(name), \(dosage) \(form), \(time), \(status)"
    }
}

#Preview {
    VStack {
        Text("Preview requires Core Data context")
            .foregroundStyle(.secondary)
    }
}
