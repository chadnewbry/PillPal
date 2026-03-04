import CoreData
import SwiftUI

// MARK: - Week View Tab

struct WeekViewTab: View {
    @StateObject private var dataService = MedicationDataService()
    @State private var weekOffset: Int = 0
    @State private var selectedDay: DayOfWeek?
    @State private var medications: [Medication] = []

    private let calendar = Calendar.current

    private var weekDates: [Date] {
        let today = Date()
        guard let shifted = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: today),
              let monday = calendar.date(from: mondayComponents(for: shifted))
        else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: monday) }
    }

    private func mondayComponents(for date: Date) -> DateComponents {
        var comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        comps.weekday = 2 // Monday
        return comps
    }

    private var weekRangeText: String {
        guard let first = weekDates.first, let last = weekDates.last else { return "" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return "\(fmt.string(from: first)) – \(fmt.string(from: last))"
    }

    private var weeklyAdherenceRate: Double {
        let dates = weekDates
        guard !dates.isEmpty else { return 0 }
        var totalScheduled = 0
        var totalTaken = 0
        for date in dates {
            let doses = dataService.dosesForDate(date)
            totalScheduled += doses.count
            totalTaken += doses.filter(\.isTaken).count
        }
        guard totalScheduled > 0 else { return 0 }
        return Double(totalTaken) / Double(totalScheduled)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    weekNavigationHeader
                    weeklySummaryCard
                    weekGrid
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Week")
            .onAppear { refreshData() }
            .onChange(of: weekOffset) { refreshData() }
            .sheet(item: $selectedDay) { day in
                DayDetailSheet(
                    day: day,
                    date: dateFor(day: day),
                    dataService: dataService
                )
            }
        }
    }

    // MARK: - Week Navigation

    private var weekNavigationHeader: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) { weekOffset -= 1 }
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
            }
            .accessibilityLabel("Previous week")
            .frame(minWidth: 44, minHeight: 44)

            Spacer()

            VStack(spacing: 2) {
                Text(weekRangeText)
                    .font(.headline)
                if weekOffset == 0 {
                    Text("This Week")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Week of \(weekRangeText)\(weekOffset == 0 ? ", current week" : "")")

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.25)) { weekOffset += 1 }
            } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
            }
            .accessibilityLabel("Next week")
            .frame(minWidth: 44, minHeight: 44)
        }
        .padding(.top, 8)
    }

    // MARK: - Weekly Summary

    private var weeklySummaryCard: some View {
        let rate = weeklyAdherenceRate
        return HStack(spacing: 16) {
            CircularProgressView(progress: rate, size: 56)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("Weekly Adherence")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(Int(rate * 100))%")
                    .font(.title.bold())
                    .foregroundStyle(adherenceColor(for: rate))
            }

            Spacer()

            if weekOffset != 0 {
                Button("Today") {
                    withAnimation { weekOffset = 0 }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityLabel("Jump to current week")
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Weekly adherence: \(Int(rate * 100)) percent")
    }

    // MARK: - Week Grid

    private var weekGrid: some View {
        let mondayFirst: [DayOfWeek] = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
        return LazyVStack(spacing: 12) {
            ForEach(mondayFirst) { day in
                DayRowView(
                    day: day,
                    date: dateFor(day: day),
                    doses: dataService.dosesForDate(dateFor(day: day)),
                    slots: dataService.scheduleSlots(for: day),
                    isToday: isToday(day),
                    onTap: { selectedDay = day }
                )
            }
        }
    }

    // MARK: - Helpers

    private func dateFor(day: DayOfWeek) -> Date {
        let mondayFirstIndex: Int
        switch day {
        case .monday: mondayFirstIndex = 0
        case .tuesday: mondayFirstIndex = 1
        case .wednesday: mondayFirstIndex = 2
        case .thursday: mondayFirstIndex = 3
        case .friday: mondayFirstIndex = 4
        case .saturday: mondayFirstIndex = 5
        case .sunday: mondayFirstIndex = 6
        }
        return weekDates.indices.contains(mondayFirstIndex) ? weekDates[mondayFirstIndex] : Date()
    }

    private func isToday(_ day: DayOfWeek) -> Bool {
        calendar.isDateInToday(dateFor(day: day))
    }

    private func refreshData() {
        medications = dataService.fetchActiveMedications()
    }

    private func adherenceColor(for rate: Double) -> Color {
        if rate >= 0.9 { return .green }
        if rate >= 0.7 { return .orange }
        return .red
    }
}

// MARK: - Circular Progress View

struct CircularProgressView: View {
    let progress: Double
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray4), lineWidth: 6)
            Circle()
                .trim(from: 0, to: max(0, min(progress, 1)))
                .stroke(progressColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.4), value: progress)
        }
        .frame(width: size, height: size)
    }

    private var progressColor: Color {
        if progress >= 0.9 { return .green }
        if progress >= 0.7 { return .orange }
        return .red
    }
}

// MARK: - Day Row View

struct DayRowView: View {
    let day: DayOfWeek
    let date: Date
    let doses: [Dose]
    let slots: [ScheduleSlot]
    let isToday: Bool
    let onTap: () -> Void

    private var adherenceRate: Double {
        guard !doses.isEmpty else { return 0 }
        return Double(doses.filter(\.isTaken).count) / Double(doses.count)
    }

    private var isFutureDay: Bool {
        date > Date() && !Calendar.current.isDateInToday(date)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                dayHeader
                medicationList
                Spacer(minLength: 8)
                adherenceIndicator
            }
            .padding(14)
            .background(cardBackground, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isToday ? Color.accentColor : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("Double tap to view details for \(day.displayName)")
        .accessibilityAddTraits(.isButton)
    }

    private var dayHeader: some View {
        VStack(spacing: 2) {
            Text(day.shortName.uppercased())
                .font(.caption.bold())
                .foregroundStyle(isToday ? Color.accentColor : .secondary)
            Text(dayNumber)
                .font(.title2.bold())
                .foregroundStyle(isToday ? Color.accentColor : .primary)
        }
        .frame(width: 48)
        .accessibilityHidden(true)
    }

    private var dayNumber: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "d"
        return fmt.string(from: date)
    }

    private var medicationList: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !doses.isEmpty {
                ForEach(Array(doses.prefix(3)), id: \.objectID) { dose in
                    DosePillView(dose: dose)
                }
                if doses.count > 3 {
                    Text("+\(doses.count - 3) more")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if !slots.isEmpty {
                ForEach(Array(slots.prefix(3)), id: \.objectID) { slot in
                    SlotPillView(slot: slot, isFuture: isFutureDay)
                }
                if slots.count > 3 {
                    Text("+\(slots.count - 3) more")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("No medications")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    @ViewBuilder
    private var adherenceIndicator: some View {
        if doses.isEmpty && slots.isEmpty {
            EmptyView()
        } else if isFutureDay {
            Image(systemName: "clock")
                .foregroundStyle(.secondary)
                .font(.title3)
        } else if !doses.isEmpty {
            CircularProgressView(progress: adherenceRate, size: 36)
        }
    }

    private var cardBackground: some ShapeStyle {
        isToday ? AnyShapeStyle(Color.accentColor.opacity(0.08)) : AnyShapeStyle(Color(.secondarySystemGroupedBackground))
    }

    private var accessibilityDescription: String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        let dateStr = fmt.string(from: date)
        let doseCount = doses.count
        let takenCount = doses.filter(\.isTaken).count

        if doseCount > 0 {
            return "\(day.displayName), \(dateStr). \(takenCount) of \(doseCount) doses taken."
        } else if !slots.isEmpty {
            return "\(day.displayName), \(dateStr). \(slots.count) scheduled medications."
        } else {
            return "\(day.displayName), \(dateStr). No medications scheduled."
        }
    }
}

// MARK: - Dose Pill View

struct DosePillView: View {
    let dose: Dose

    private var medication: Medication? { dose.medication }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: medication?.formEnum.symbolName ?? "pills.fill")
                .font(.caption)
                .foregroundStyle(statusColor)
                .frame(width: 20)

            Text(medication?.name ?? "Unknown")
                .font(.subheadline)
                .lineLimit(1)

            if let time = dose.scheduledTime {
                Text(timeString(time))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            statusIcon
        }
    }

    private var statusColor: Color {
        if dose.isTaken { return .green }
        if dose.isOverdue { return .red }
        return .accentColor
    }

    @ViewBuilder
    private var statusIcon: some View {
        if dose.isTaken {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.caption)
        } else if dose.isOverdue {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.red)
                .font(.caption)
        }
    }

    private func timeString(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.timeStyle = .short
        return fmt.string(from: date)
    }
}

// MARK: - Schedule Slot Pill View

struct SlotPillView: View {
    let slot: ScheduleSlot
    let isFuture: Bool

    private var medication: Medication? { slot.medication }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: medication?.formEnum.symbolName ?? "pills.fill")
                .font(.caption)
                .foregroundStyle(isFuture ? .secondary : Color.accentColor)
                .frame(width: 20)

            Text(medication?.name ?? "Unknown")
                .font(.subheadline)
                .lineLimit(1)

            Text(slot.timeString)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Day Detail Sheet

struct DayDetailSheet: View {
    let day: DayOfWeek
    let date: Date
    @ObservedObject var dataService: MedicationDataService
    @Environment(\.dismiss) private var dismiss

    private var doses: [Dose] {
        dataService.dosesForDate(date)
    }

    private var slots: [ScheduleSlot] {
        dataService.scheduleSlots(for: day)
    }

    private var isFutureDay: Bool {
        date > Date() && !Calendar.current.isDateInToday(date)
    }

    private var adherenceRate: Double {
        guard !doses.isEmpty else { return 0 }
        return Double(doses.filter(\.isTaken).count) / Double(doses.count)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    daySummaryHeader

                    if !doses.isEmpty {
                        dosesList
                    } else if !slots.isEmpty {
                        scheduledSlotsList
                    } else {
                        emptyState
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(day.displayName)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .frame(minWidth: 44, minHeight: 44)
                }
            }
        }
    }

    private var daySummaryHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(formattedDate)
                    .font(.title2.bold())

                if !doses.isEmpty {
                    Text("\(doses.filter(\.isTaken).count) of \(doses.count) taken")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else if !slots.isEmpty {
                    Text("\(slots.count) scheduled")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if !doses.isEmpty {
                CircularProgressView(progress: adherenceRate, size: 56)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(daySummaryAccessibility)
    }

    private var formattedDate: String {
        let fmt = DateFormatter()
        fmt.dateStyle = .long
        return fmt.string(from: date)
    }

    private var daySummaryAccessibility: String {
        if !doses.isEmpty {
            return "\(formattedDate). \(doses.filter(\.isTaken).count) of \(doses.count) doses taken. \(Int(adherenceRate * 100)) percent adherence."
        } else if !slots.isEmpty {
            return "\(formattedDate). \(slots.count) medications scheduled."
        }
        return "\(formattedDate). No medications."
    }

    private var dosesList: some View {
        let grouped = Dictionary(grouping: doses) { dose -> String in
            guard let time = dose.scheduledTime else { return "Morning" }
            return TimeOfDay.from(date: time).rawValue
        }

        return VStack(spacing: 12) {
            ForEach([TimeOfDay.morning, .afternoon, .evening], id: \.self) { timeOfDay in
                if let dayDoses = grouped[timeOfDay.rawValue], !dayDoses.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(timeOfDay.rawValue, systemImage: timeOfDay.symbolName)
                            .font(.headline)
                            .foregroundStyle(timeOfDay.color)
                            .padding(.leading, 4)

                        ForEach(dayDoses, id: \.objectID) { dose in
                            DetailDoseCard(dose: dose)
                        }
                    }
                }
            }
        }
    }

    private var scheduledSlotsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Scheduled")
                .font(.headline)
                .padding(.leading, 4)

            ForEach(slots, id: \.objectID) { slot in
                HStack(spacing: 14) {
                    Image(systemName: slot.medication?.formEnum.symbolName ?? "pills.fill")
                        .font(.title3)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 40, height: 40)
                        .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(slot.medication?.name ?? "Unknown")
                            .font(.body.bold())
                        Text(slot.timeString)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "clock")
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                .accessibilityElement(children: .combine)
                .accessibilityLabel(slot.accessibilityDescription)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text("No Medications Scheduled")
                .font(.title3.bold())

            Text("No medications are scheduled for this day.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Detail Dose Card

struct DetailDoseCard: View {
    let dose: Dose

    private var medication: Medication? { dose.medication }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: medication?.formEnum.symbolName ?? "pills.fill")
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(statusColor, in: RoundedRectangle(cornerRadius: 12))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(medication?.name ?? "Unknown")
                    .font(.body.bold())
                HStack(spacing: 6) {
                    Text(medication?.dosage ?? "")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let time = dose.scheduledTime {
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text(timeString(time))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            statusView
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(dose.accessibilityDescription)
    }

    @ViewBuilder
    private var statusView: some View {
        if dose.isTaken {
            Label("Taken", systemImage: "checkmark.circle.fill")
                .font(.subheadline.bold())
                .foregroundStyle(.green)
        } else if dose.isOverdue {
            Label("Missed", systemImage: "exclamationmark.circle.fill")
                .font(.subheadline.bold())
                .foregroundStyle(.red)
        } else {
            Label("Upcoming", systemImage: "clock")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
        }
    }

    private var statusColor: Color {
        if dose.isTaken { return .green }
        if dose.isOverdue { return .red }
        return .accentColor
    }

    private func timeString(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.timeStyle = .short
        return fmt.string(from: date)
    }
}

// MARK: - DayOfWeek Identifiable for Sheet

extension DayOfWeek: Hashable {}

// MARK: - Preview

#Preview {
    WeekViewTab()
}
