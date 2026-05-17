import SwiftUI
import FoxCleanCore

enum MenuBarQuickAction {
    case smartScan
    case openApp
    case openMonitor
    case quit
}

struct MenuBarSnapshot: Identifiable {
    let id = UUID()
    let cpuLoad: Double
    let memoryUsedRatio: Double
    let healthScore: Int
    let timestamp: Date
}

@MainActor
final class MenuBarMiniModel: ObservableObject {
    @Published private(set) var current: MenuBarSnapshot?
    @Published private(set) var history: [MenuBarSnapshot] = []

    private let monitor = SystemMonitor()
    private let onAction: (MenuBarQuickAction) -> Void
    private let onSnapshot: (MenuBarSnapshot) -> Void
    private var task: Task<Void, Never>?

    init(onAction: @escaping (MenuBarQuickAction) -> Void, onSnapshot: @escaping (MenuBarSnapshot) -> Void) {
        self.onAction = onAction
        self.onSnapshot = onSnapshot
        start()
    }

    deinit {
        task?.cancel()
    }

    func perform(_ action: MenuBarQuickAction) {
        onAction(action)
    }

    private func start() {
        task = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                let snapshot = await monitor.snapshot()
                let item = MenuBarSnapshot(
                    cpuLoad: snapshot.cpuLoad,
                    memoryUsedRatio: snapshot.memoryUsedRatio,
                    healthScore: snapshot.healthScore,
                    timestamp: snapshot.timestamp
                )
                current = item
                history.append(item)
                if history.count > 60 {
                    history.removeFirst(history.count - 60)
                }
                onSnapshot(item)
                try? await Task.sleep(for: .seconds(5))
            }
        }
    }
}

struct MenuBarMiniView: View {
    @ObservedObject var model: MenuBarMiniModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            MiniChart(samples: model.history.map(\.cpuLoad))
                .frame(height: 56)
                .accessibilityLabel("CPU history")
            metrics
            Divider()
            quickActions
        }
        .padding(14)
        .frame(width: 280)
    }

    private var header: some View {
        HStack {
            Image(systemName: "pawprint.fill")
                .font(.title2)
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("FoxClean")
                    .font(.headline)
                Text("System snapshot")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(scoreText)
                .font(.title3.monospacedDigit().bold())
                .foregroundStyle(scoreColor)
        }
    }

    private var metrics: some View {
        Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 6) {
            GridRow {
                metric("CPU", value: percent(model.current?.cpuLoad))
                metric("Memory", value: percent(model.current?.memoryUsedRatio))
            }
        }
        .font(.caption)
    }

    private var quickActions: some View {
        Grid(horizontalSpacing: 8, verticalSpacing: 8) {
            GridRow {
                actionButton("Smart Scan", systemImage: "sparkles", action: .smartScan)
                actionButton("Monitor", systemImage: "waveform.path.ecg", action: .openMonitor)
            }
            GridRow {
                actionButton("Open", systemImage: "macwindow", action: .openApp)
                actionButton("Quit", systemImage: "power", action: .quit)
            }
        }
    }

    private func actionButton(_ title: String, systemImage: String, action: MenuBarQuickAction) -> some View {
        Button {
            model.perform(action)
        } label: {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .accessibilityLabel(title)
    }

    private func metric(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body.monospacedDigit())
        }
    }

    private var scoreText: String {
        guard let score = model.current?.healthScore else { return "--" }
        return "\(score)"
    }

    private var scoreColor: Color {
        guard let score = model.current?.healthScore else { return .secondary }
        if score >= 80 { return .green }
        if score >= 55 { return .orange }
        return .red
    }

    private func percent(_ value: Double?) -> String {
        guard let value else { return "--%" }
        return "\(Int((value * 100).rounded()))%"
    }
}

private struct MiniChart: View {
    let samples: [Double]

    var body: some View {
        Canvas { context, size in
            guard samples.count > 1 else { return }
            let maxValue = max(samples.max() ?? 1, 0.01)
            var path = Path()
            for (index, sample) in samples.enumerated() {
                let x = size.width * CGFloat(index) / CGFloat(samples.count - 1)
                let y = size.height - (size.height * CGFloat(sample / maxValue))
                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            context.stroke(path, with: .color(.orange), lineWidth: 2)
        }
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
    }
}
