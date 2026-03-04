import CoreData
import SwiftUI

// MARK: - Settings View

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.openURL) private var openURL

    // Accessibility
    @AppStorage("textSizeMultiplier") private var textSizeMultiplier: Double = 1.0
    @AppStorage("highContrastEnabled") private var highContrastEnabled = false
    @AppStorage("voiceOverOptimized") private var voiceOverOptimized = false
    @AppStorage("notificationSoundName") private var notificationSoundName = "Default"
    @AppStorage("vibrationPattern") private var vibrationPattern = "Standard"
    @AppStorage("voiceAnnouncementsEnabled") private var voiceAnnouncementsEnabled = false

    // Medication
    @AppStorage("defaultReminderHour") private var defaultReminderHour = 8
    @AppStorage("defaultReminderMinute") private var defaultReminderMinute = 0
    @AppStorage("snoozeDurationMinutes") private var snoozeDurationMinutes = 10
    @AppStorage("adherenceGoalPercent") private var adherenceGoalPercent = 90
    @AppStorage("emergencyContactName") private var emergencyContactName = ""
    @AppStorage("emergencyContactPhone") private var emergencyContactPhone = ""
    @AppStorage("doctorName") private var doctorName = ""
    @AppStorage("doctorPhone") private var doctorPhone = ""
    @AppStorage("pharmacyName") private var pharmacyName = ""
    @AppStorage("pharmacyPhone") private var pharmacyPhone = ""
    @AppStorage("interactionAlertsEnabled") private var interactionAlertsEnabled = true

    // Data & Privacy
    @AppStorage("cloudKitSyncEnabled") private var cloudKitSyncEnabled = true
    @AppStorage("familySharingEnabled") private var familySharingEnabled = false

    // Theme
    @AppStorage("appTheme") private var appTheme = 0

    @State private var showResetConfirmation = false
    @State private var showExportSheet = false

    var body: some View {
        NavigationStack {
            List {
                coreSettingsSection
                accessibilitySection
                medicationSettingsSection
                dataPrivacySection
                aboutSection
            }
            .navigationTitle("Settings")
            .alert("Reset All Data", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("This will permanently delete all medications, doses, and history. This action cannot be undone.")
            }
        }
    }

    // MARK: - Core Settings

    private var coreSettingsSection: some View {
        Section {
            Picker("Theme", selection: $appTheme) {
                ForEach(AppTheme.allCases) { theme in
                    Text(theme.displayName).tag(Int(theme.rawValue))
                }
            }
            .accessibilityHint("Choose between system, light, or dark appearance")

            Toggle("Large Text", isOn: Binding(
                get: { textSizeMultiplier > 1.0 },
                set: { textSizeMultiplier = $0 ? 1.3 : 1.0 }
            ))
            .accessibilityHint("Increases text size throughout the app for easier reading")

            Toggle("High Contrast", isOn: $highContrastEnabled)
                .accessibilityHint("Increases color contrast for better visibility")
        } header: {
            Label("Appearance", systemImage: "paintbrush.fill")
        }
    }

    // MARK: - Accessibility Settings

    private var accessibilitySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Text Size")
                    .font(.subheadline)
                HStack {
                    Text("A")
                        .font(.caption)
                    Slider(value: $textSizeMultiplier, in: 0.8...2.0, step: 0.1)
                        .accessibilityLabel("Text size adjustment")
                        .accessibilityValue("\(Int(textSizeMultiplier * 100)) percent")
                    Text("A")
                        .font(.title2)
                }
            }

            Toggle("VoiceOver Optimized", isOn: $voiceOverOptimized)
                .accessibilityHint("Enables enhanced VoiceOver descriptions and pronunciation guides for medications")

            Toggle("Voice Announcements", isOn: $voiceAnnouncementsEnabled)
                .accessibilityHint("Speaks medication reminders aloud when notifications arrive")

            Picker("Notification Sound", selection: $notificationSoundName) {
                Text("Default").tag("Default")
                Text("Gentle Chime").tag("GentleChime")
                Text("Soft Bell").tag("SoftBell")
                Text("Clear Tone").tag("ClearTone")
                Text("Urgent Alert").tag("UrgentAlert")
            }
            .accessibilityHint("Choose the sound played for medication reminders")

            Picker("Vibration Pattern", selection: $vibrationPattern) {
                Text("Standard").tag("Standard")
                Text("Gentle Pulse").tag("GentlePulse")
                Text("Strong Buzz").tag("StrongBuzz")
                Text("Repeated Tap").tag("RepeatedTap")
                Text("None").tag("None")
            }
            .accessibilityHint("Choose how your device vibrates for reminders")
        } header: {
            Label("Accessibility", systemImage: "accessibility")
        } footer: {
            Text("These settings help make the app easier to use. VoiceOver optimization adds pronunciation guides and detailed descriptions.")
        }
    }

    // MARK: - Medication Settings

    private var medicationSettingsSection: some View {
        Section {
            HStack {
                Label("Default Reminder", systemImage: "clock.fill")
                Spacer()
                DatePicker(
                    "",
                    selection: Binding(
                        get: {
                            Calendar.current.date(
                                bySettingHour: defaultReminderHour,
                                minute: defaultReminderMinute,
                                second: 0,
                                of: Date()
                            ) ?? Date()
                        },
                        set: { newDate in
                            let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                            defaultReminderHour = components.hour ?? 8
                            defaultReminderMinute = components.minute ?? 0
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
            }
            .accessibilityElement(children: .combine)

            Picker("Snooze Duration", selection: $snoozeDurationMinutes) {
                Text("5 minutes").tag(5)
                Text("10 minutes").tag(10)
                Text("15 minutes").tag(15)
                Text("30 minutes").tag(30)
                Text("1 hour").tag(60)
            }
            .accessibilityHint("How long to delay a reminder when you snooze it")

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Adherence Goal")
                    Spacer()
                    Text("\(adherenceGoalPercent)%")
                        .foregroundStyle(.secondary)
                        .font(.subheadline.monospacedDigit())
                }
                Slider(
                    value: Binding(
                        get: { Double(adherenceGoalPercent) },
                        set: { adherenceGoalPercent = Int($0) }
                    ),
                    in: 50...100,
                    step: 5
                )
                .accessibilityLabel("Adherence goal")
                .accessibilityValue("\(adherenceGoalPercent) percent")
            }

            Toggle("Interaction Alerts", isOn: $interactionAlertsEnabled)
                .accessibilityHint("Warns you about potential medication interactions")

            NavigationLink {
                EmergencyContactView(
                    contactName: $emergencyContactName,
                    contactPhone: $emergencyContactPhone
                )
            } label: {
                HStack {
                    Label("Emergency Contact", systemImage: "phone.fill")
                    Spacer()
                    if !emergencyContactName.isEmpty {
                        Text(emergencyContactName)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            NavigationLink {
                MedicalContactsView(
                    doctorName: $doctorName,
                    doctorPhone: $doctorPhone,
                    pharmacyName: $pharmacyName,
                    pharmacyPhone: $pharmacyPhone
                )
            } label: {
                Label("Doctor & Pharmacy", systemImage: "stethoscope")
            }
        } header: {
            Label("Medication", systemImage: "pills.fill")
        }
    }

    // MARK: - Data & Privacy

    private var dataPrivacySection: some View {
        Section {
            Toggle("iCloud Sync", isOn: $cloudKitSyncEnabled)
                .accessibilityHint("Syncs your medication data across your Apple devices using iCloud")

            Toggle("Family Sharing", isOn: $familySharingEnabled)
                .accessibilityHint("Allows family members to view your medication adherence")

            Button {
                showExportSheet = true
            } label: {
                Label("Export Data", systemImage: "square.and.arrow.up")
            }
            .accessibilityHint("Export all your medication data as a file")

            Button(role: .destructive) {
                showResetConfirmation = true
            } label: {
                Label("Reset All Data", systemImage: "trash.fill")
                    .foregroundStyle(.red)
            }
            .accessibilityHint("Permanently deletes all medications, doses, and history")
        } header: {
            Label("Data & Privacy", systemImage: "lock.shield.fill")
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section {
            Button {
                if let url = URL(string: "https://chadnewbry.github.io/pillpal/privacy") {
                    openURL(url)
                }
            } label: {
                HStack {
                    Label("Privacy Policy", systemImage: "hand.raised.fill")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.primary)

            Button {
                if let url = URL(string: "https://chadnewbry.github.io/pillpal/terms") {
                    openURL(url)
                }
            } label: {
                HStack {
                    Label("Terms of Use", systemImage: "doc.text.fill")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.primary)

            Button {
                if let url = URL(string: "mailto:chad.newbry@gmail.com?subject=PillPal%20Support") {
                    openURL(url)
                }
            } label: {
                HStack {
                    Label("Contact Support", systemImage: "envelope.fill")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.primary)

            HStack {
                Label("Version", systemImage: "info.circle.fill")
                Spacer()
                Text(appVersion)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
        } header: {
            Label("About", systemImage: "questionmark.circle.fill")
        }
    }

    // MARK: - Helpers

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func resetAllData() {
        let entities = ["Medication", "Dose", "ScheduleSlot", "AdherenceRecord"]
        for entity in entities {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try? viewContext.execute(deleteRequest)
        }
        try? viewContext.save()

        let defaults = UserDefaults.standard
        let keys = [
            "textSizeMultiplier", "highContrastEnabled", "voiceOverOptimized",
            "notificationSoundName", "vibrationPattern", "voiceAnnouncementsEnabled",
            "defaultReminderHour", "defaultReminderMinute", "snoozeDurationMinutes",
            "adherenceGoalPercent", "emergencyContactName", "emergencyContactPhone",
            "doctorName", "doctorPhone", "pharmacyName", "pharmacyPhone",
            "interactionAlertsEnabled", "cloudKitSyncEnabled", "familySharingEnabled",
            "appTheme"
        ]
        keys.forEach { defaults.removeObject(forKey: $0) }
    }
}

// MARK: - Emergency Contact View

struct EmergencyContactView: View {
    @Binding var contactName: String
    @Binding var contactPhone: String

    var body: some View {
        Form {
            Section {
                TextField("Contact Name", text: $contactName)
                    .textContentType(.name)
                    .accessibilityLabel("Emergency contact name")

                TextField("Phone Number", text: $contactPhone)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
                    .accessibilityLabel("Emergency contact phone number")
            } header: {
                Text("Emergency Contact")
            } footer: {
                Text("This person will be notified if you miss critical medication doses after all escalation reminders.")
            }
        }
        .navigationTitle("Emergency Contact")
    }
}

// MARK: - Medical Contacts View

struct MedicalContactsView: View {
    @Binding var doctorName: String
    @Binding var doctorPhone: String
    @Binding var pharmacyName: String
    @Binding var pharmacyPhone: String

    var body: some View {
        Form {
            Section {
                TextField("Doctor's Name", text: $doctorName)
                    .textContentType(.name)
                    .accessibilityLabel("Doctor's name")

                TextField("Doctor's Phone", text: $doctorPhone)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
                    .accessibilityLabel("Doctor's phone number")
            } header: {
                Label("Doctor", systemImage: "stethoscope")
            }

            Section {
                TextField("Pharmacy Name", text: $pharmacyName)
                    .textContentType(.organizationName)
                    .accessibilityLabel("Pharmacy name")

                TextField("Pharmacy Phone", text: $pharmacyPhone)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
                    .accessibilityLabel("Pharmacy phone number")
            } header: {
                Label("Pharmacy", systemImage: "cross.fill")
            }

            if !doctorPhone.isEmpty {
                Section {
                    Button {
                        if let url = URL(string: "tel:\(doctorPhone)") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Call Doctor", systemImage: "phone.fill")
                    }
                }
            }

            if !pharmacyPhone.isEmpty {
                Section {
                    Button {
                        if let url = URL(string: "tel:\(pharmacyPhone)") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Call Pharmacy", systemImage: "phone.fill")
                    }
                }
            }
        }
        .navigationTitle("Doctor & Pharmacy")
    }
}

// MARK: - Previews

#Preview {
    SettingsView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
