import CoreData
import SwiftUI

// MARK: - Time of Day

enum TimeOfDay: String, CaseIterable, Identifiable {
    case morning = "Morning"
    case afternoon = "Afternoon"
    case evening = "Evening"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .morning: "sunrise.fill"
        case .afternoon: "sun.max.fill"
        case .evening: "moon.stars.fill"
        }
    }

    var color: Color {
        switch self {
        case .morning: .orange
        case .afternoon: .blue
        case .evening: .indigo
        }
    }

    static func from(date: Date) -> TimeOfDay {
        let hour = Calendar.current.component(.hour, from: date)
        if (5...11).contains(hour) { return .morning }
        if (12...16).contains(hour) { return .afternoon }
        return .evening
    }
}

// MARK: - Today View

struct TodayView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var dataService = MedicationDataService()
    @State private var doses: [Dose] = []
    @EnvironmentObject private var storeManager: StoreManager
    @EnvironmentObject private var premiumManager: PremiumManager
    @State private var showingAddMedication = false
    @State private var showingEmergencyContact = false
    @State private var selectedDose: Dose?

    private let today = Date()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    dailyProgressSection
                    pillOrganizerSections
                    emergencyContactButton
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if premiumManager.recordMedicationAdded(isPremium: storeManager.isPremium) {
                            showingAddMedication = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .accessibilityLabel("Add medication")
                    .accessibilityHint(storeManager.isPremium ? "Opens the add medication form" : "\(premiumManager.freeUsesRemaining) free slots remaining. Opens the add medication form")
                }
            }
            .sheet(isPresented: $showingAddMedication) {
                AddMedicationView(dataService: dataService) {
                    refreshDoses()
                }
            }
            .sheet(item: $selectedDose) { dose in
                MedicationDetailSheet(dose: dose)
            }
            .alert("Emergency Contact", isPresented: $showingEmergencyContact) {
                Button("Call 911", role: .destructive) { }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("In a medical emergency, call 911 or your local emergency number immediately.")
            }
            .onAppear {
                dataService.generateDosesForDate(today)
                refreshDoses()
            }
            .refreshable {
                refreshDoses()
            }
        }
    }

    // MARK: - Daily Progress

    private var dailyProgressSection: some View {
        let total = doses.count
        let taken = doses.filter(\.isTaken).count
        let progress = total > 0 ? Double(taken) / Double(total) : 0

        return DailyProgressView(
            taken: taken,
            total: total,
            progress: progress
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Daily progress: \(taken) of \(total) medications taken, \(Int(progress * 100)) percent complete")
    }

    // MARK: - Pill Organizer Sections

    private var pillOrganizerSections: some View {
        ForEach(TimeOfDay.allCases) { timeOfDay in
            let sectionDoses = doses(for: timeOfDay)
            TimeOfDaySectionView(
                timeOfDay: timeOfDay,
                doses: sectionDoses,
                onTake: { dose in markDoseTaken(dose) },
                onSkip: { dose in markDoseSkipped(dose) },
                onTap: { dose in selectedDose = dose }
            )
            .accessibilityElement(children: .contain)
            .accessibilityLabel("\(timeOfDay.rawValue) medications, \(sectionDoses.count) doses")
        }
    }

    // MARK: - Emergency Contact

    private var emergencyContactButton: some View {
        Button {
            showingEmergencyContact = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "phone.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.red, in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("Emergency Contact")
                        .font(.headline)
                    Text("Tap for emergency information")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Emergency contact")
        .accessibilityHint("Shows emergency contact information")
        .frame(minHeight: 44)
    }

    // MARK: - Helpers

    private func doses(for timeOfDay: TimeOfDay) -> [Dose] {
        doses.filter { dose in
            guard let scheduled = dose.scheduledTime else { return false }
            return TimeOfDay.from(date: scheduled) == timeOfDay
        }
    }

    private func refreshDoses() {
        doses = dataService.dosesForDate(today)
    }

    private func markDoseTaken(_ dose: Dose) {
        withAnimation(.easeInOut(duration: 0.3)) {
            dataService.markDoseTaken(dose)
            _ = dataService.recordAdherence(for: today)
            refreshDoses()
        }
    }

    private func markDoseSkipped(_ dose: Dose) {
        withAnimation(.easeInOut(duration: 0.3)) {
            dose.notes = "Skipped"
            dose.isTaken = false
            try? viewContext.save()
            refreshDoses()
        }
    }
}

// MARK: - Medication Detail Sheet

private struct MedicationDetailSheet: View {
    let dose: Dose
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if let medication = dose.medication {
                    Section("Medication") {
                        DetailRow(label: "Name", value: medication.name ?? "Unknown")
                        DetailRow(label: "Dosage", value: medication.dosage ?? "—")
                        DetailRow(label: "Form", value: medication.formEnum.displayName)
                        DetailRow(label: "Frequency", value: medication.frequencyEnum.displayName)
                    }

                    if let instructions = medication.instructions, !instructions.isEmpty {
                        Section("Instructions") {
                            Text(instructions)
                                .font(.body)
                                .accessibilityLabel("Instructions: \(instructions)")
                        }
                    }
                }

                Section("Dose Info") {
                    if let scheduled = dose.scheduledTime {
                        DetailRow(label: "Scheduled", value: scheduled.formatted(date: .omitted, time: .shortened))
                    }
                    DetailRow(label: "Status", value: dose.isTaken ? "Taken" : (dose.isOverdue ? "Overdue" : "Upcoming"))
                    if let taken = dose.actualTimeTaken {
                        DetailRow(label: "Taken at", value: taken.formatted(date: .omitted, time: .shortened))
                    }
                }
            }
            .navigationTitle("Medication Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

#Preview {
    TodayView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
