import SwiftUI

struct DailyProgressView: View {
    let taken: Int
    let total: Int
    let progress: Double

    var body: some View {
        VStack(spacing: 16) {
            // Circular progress
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 12)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(progressColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progress)

                VStack(spacing: 2) {
                    Text("\(Int(progress * 100))%")
                        .font(.title2.bold())
                        .monospacedDigit()
                    Text("\(taken)/\(total)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }

            Text(statusMessage)
                .font(.headline)
                .foregroundStyle(.primary)

            Text(today)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.background, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Daily progress: \(taken) of \(total) medications taken, \(Int(progress * 100)) percent complete")
        .accessibilityIdentifier("daily_progress")
    }

    private var progressColor: Color {
        if progress >= 1.0 { return .green }
        if progress >= 0.5 { return .blue }
        return .orange
    }

    private var statusMessage: String {
        if total == 0 { return "No medications scheduled" }
        if progress >= 1.0 { return "All done for today! 🎉" }
        let remaining = total - taken
        return "\(remaining) medication\(remaining == 1 ? "" : "s") remaining"
    }

    private var today: String {
        Date().formatted(.dateTime.weekday(.wide).month(.wide).day())
    }
}

#Preview {
    VStack(spacing: 20) {
        DailyProgressView(taken: 3, total: 5, progress: 0.6)
        DailyProgressView(taken: 5, total: 5, progress: 1.0)
        DailyProgressView(taken: 0, total: 0, progress: 0)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
