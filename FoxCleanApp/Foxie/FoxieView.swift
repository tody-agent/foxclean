import SwiftUI

enum FoxieMood: String, CaseIterable {
    case idle
    case scanning
    case cleaning
    case success
    case error
    case sleeping
    case curious
    case dancing
}

struct FoxieView: View {
    var mood: FoxieMood = .idle
    var size: CGFloat = 64
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage("FoxClean.ReduceFoxieAnimations") private var reduceFoxieAnimations = false
    @State private var animate = false

    var body: some View {
        ZStack {
            Circle()
                .fill(background)
            Image(systemName: symbol)
                .font(.system(size: size * 0.44, weight: .bold))
                .foregroundStyle(.white)
                .rotationEffect(.degrees(rotation))
                .scaleEffect(scale)
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Foxie \(mood.rawValue)")
        .onAppear { animate = !reduceMotion }
        .onChange(of: reduceMotion) { reduced in
            animate = !reduced
        }
    }

    private var reduceMotion: Bool {
        systemReduceMotion || reduceFoxieAnimations
    }

    private var symbol: String {
        switch mood {
        case .idle: return "pawprint.fill"
        case .scanning: return "magnifyingglass"
        case .cleaning: return "sparkles"
        case .success: return "checkmark"
        case .error: return "exclamationmark.triangle.fill"
        case .sleeping: return "moon.zzz.fill"
        case .curious: return "questionmark"
        case .dancing: return "music.note"
        }
    }

    private var background: LinearGradient {
        let colors: [Color]
        switch mood {
        case .success: colors = [.green, .mint]
        case .error: colors = [.red, .orange]
        case .sleeping: colors = [.indigo, .blue]
        case .scanning, .cleaning: colors = [.blue, .cyan]
        default: colors = [.orange, .pink]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var rotation: Double {
        guard !reduceMotion else { return 0 }
        switch mood {
        case .idle: return animate ? 4 : -4
        case .dancing: return animate ? 12 : -12
        default: return 0
        }
    }

    private var scale: CGFloat {
        guard !reduceMotion else { return 1 }
        return mood == .dancing && animate ? 1.08 : 1
    }
}
