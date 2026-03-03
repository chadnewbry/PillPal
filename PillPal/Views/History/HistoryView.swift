import SwiftUI
import CoreData

struct HistoryView: View {
    @StateObject private var dataService = MedicationDataService()
    @State private var selectedPeriod: TimePeriod = .week
    @State private var doseHistory: [DoseDay] = []
    @State private var adherenceRecords: [AdherenceRecord] = []

    enum TimePeriod: String, CaseIterable {
        case week = "7 Days"
        case month = "30 Days"
        case allTime = "All Time"

        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .allTime: return 365
            }
        }
    }

    var overallAdherence: Double {
        guard !adherenceRecords.isEmpty else { return 0 }
        let totalScheduled = adherenceRecords.reduce(0) { $0 + Int($1.totalScheduled) }
        let totalTaken = adherenceRecords.reduce(0) { $0 + Int($1.totalTaken) }
        guard totalScheduled > 0 else { return 0 }
        return Double(totalTaken) / Double(totalScheduled)
    }

    var body: some View {
        NavigationStack {
            List {
                adherenceSummarySection
                historyListSection
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(TimePeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 220)
                }
            }
            .onAppear { loadData() }
            .onChange(of: selectedPeriod) { _, _ in loadData() }
        }
    }

    // MARK: - Adherence Summary

    private var adherenceSummarySection: some View {
        Section {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    Circle()
                        .trim(from: 0, to: overallAdherence)
                        .stroke(adherenceColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: overallAdherence)
                    VStack(spacing: 2) {
                        Text("\(Int(overallAdherence * 100))%")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(adherenceColor)
                        Text("Adherence")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 120, height: 120)
                .padding(.top, 8)

                HStack(spacing: 24) {
                    statItem(
                        value: "\(adherenceRecords.reduce(0) { $0 + Int($1.totalTaken) })",
                        label: "Taken",
                        color: .green
                    )
                    statItem(
                        value: "\(adherenceRecords.reduce(0) { $0 + Int($1.totalScheduled) - Int($1.totalTaken) })",
                        label: "Missed",
                        color: .red
                    )
                    statItem(
                        value: "\(adherenceRecords.count)",
                        label: "Days",
                        color: .blue
                    )
                }
                .padding(.bottom, 8)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Adherence rate \(Int(overallAdherence * 100)) percent over \(selectedPeriod.rawValue)")
        } header: {
            Text("Adherence Summary")
        }
    }

    private func statItem(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var adherenceColor: Color {
        switch overallAdherence {
        case 0.8...: return .green
        case 0.5...: return .orange
        default: return .red
        }
    }

    // MARK: - History List

    private var historyListSection: some View {
        Section {
            if doseHistory.isEmpty {
                ContentUnavailableView(
                    "No History Yet",
                    systemImage: "clock",
                    description: Text("Dose history will appear here as you track your medications.")
                )
            } else {
                ForEach(doseHistory) { day in
                    dayRow(day)
                }
            }
        } header: {
            Text("Daily Log")
        }
    }

    private func dayRow(_ day: DoseDay) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(day.date, style: .date)
                    .font(.headline)
                Spacer()
                Text("\(Int(day.adherenceRate * 100))%")
                    .font(.subheadline.bold())
                    .foregroundStyle(day.adherenceRate >= 0.8 ? .green : (day.adherenceRate >= 0.5 ? .orange : .red))
            }

            ForEach(day.doses) { dose in
                HStack(spacing: 8) {
                    Image(systemName: dose.isTaken ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(dose.isTaken ? .green : .red)
                        .font(.caption)
                    Text(dose.medication?.name ?? "Unknown")
                        .font(.subheadline)
                    Spacer()
                    if let time = dose.scheduledTime {
                        Text(time, style: .time)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(dose.isTaken ? "Taken" : "Missed")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(dose.isTaken ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                        .foregroundStyle(dose.isTaken ? .green : .red)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(day.accessibilityDescription)
    }

    // MARK: - Data Loading

    private func loadData() {
        let days = selectedPeriod.days
        adherenceRecords = dataService.adherenceHistory(days: days)

        let calendar = Calendar.current
        var result: [DoseDay] = []
        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let doses = dataService.dosesForDate(date)
            guard !doses.isEmpty else { continue }
            let taken = doses.filter(\.isTaken).count
            let rate = doses.isEmpty ? 0 : Double(taken) / Double(doses.count)
            result.append(DoseDay(date: calendar.startOfDay(for: date), doses: doses, adherenceRate: rate))
        }
        doseHistory = result
    }
}

// MARK: - Supporting Types

struct DoseDay: Identifiable {
    let id = UUID()
    let date: Date
    let doses: [Dose]
    let adherenceRate: Double

    var accessibilityDescription: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let dateStr = formatter.string(from: date)
        let taken = doses.filter(\.isTaken).count
        return "\(dateStr): \(taken) of \(doses.count) doses taken, \(Int(adherenceRate * 100))% adherence"
    }
}

#Preview {
    HistoryView()
}
