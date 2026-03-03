import SwiftUI

struct AddMedicationView: View {
    @ObservedObject var dataService: MedicationDataService
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var dosage = ""
    @State private var form: MedicationForm = .tablet
    @State private var frequency: DosingFrequency = .once
    @State private var instructions = ""
    @State private var scheduleTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Medication Name") {
                    TextField("e.g. Aspirin", text: $name)
                        .font(.title3)
                        .frame(minHeight: 44)
                        .accessibilityLabel("Medication name")
                }

                Section("Dosage") {
                    TextField("e.g. 500mg", text: $dosage)
                        .font(.title3)
                        .frame(minHeight: 44)
                        .accessibilityLabel("Dosage amount")
                }

                Section("Type") {
                    Picker("Form", selection: $form) {
                        ForEach(MedicationForm.allCases) { f in
                            Label(f.displayName, systemImage: f.symbolName)
                                .tag(f)
                        }
                    }
                    .frame(minHeight: 44)

                    Picker("Frequency", selection: $frequency) {
                        ForEach(DosingFrequency.allCases) { f in
                            Text(f.displayName)
                                .tag(f)
                        }
                    }
                    .frame(minHeight: 44)
                }

                Section("Schedule") {
                    DatePicker("Time", selection: $scheduleTime, displayedComponents: .hourAndMinute)
                        .frame(minHeight: 44)
                        .accessibilityLabel("Scheduled time")
                }

                Section("Instructions (Optional)") {
                    TextField("e.g. Take with food", text: $instructions, axis: .vertical)
                        .lineLimit(3...6)
                        .frame(minHeight: 44)
                        .accessibilityLabel("Special instructions")
                }
            }
            .navigationTitle("Add Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .frame(minWidth: 44, minHeight: 44)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveMedication() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || dosage.trimmingCharacters(in: .whitespaces).isEmpty)
                        .frame(minWidth: 44, minHeight: 44)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func saveMedication() {
        do {
            let medication = try dataService.addMedication(
                name: name.trimmingCharacters(in: .whitespaces),
                dosage: dosage.trimmingCharacters(in: .whitespaces),
                form: form,
                frequency: frequency,
                instructions: instructions.isEmpty ? nil : instructions
            )

            // Create a schedule slot for today's day of week
            let calendar = Calendar.current
            let weekday = calendar.component(.weekday, from: Date())
            if let day = DayOfWeek(rawValue: Int16(weekday - 1)) {
                ScheduleSlot.create(
                    in: dataService.viewContext,
                    medication: medication,
                    dayOfWeek: day,
                    timeOfDay: scheduleTime
                )
                try? dataService.viewContext.save()
            }

            // Generate doses for today
            dataService.generateDosesForDate(Date())
            onComplete()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

#Preview {
    AddMedicationView(
        dataService: MedicationDataService(persistence: .preview),
        onComplete: { }
    )
}
