import SwiftUI

/// User-overridable appearance setting that lives independently of the system
/// preference, mirroring the prototype's titlebar light/dark toggle.
enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum AccentChoice: String, CaseIterable, Identifiable {
    case system, blue, green, orange, purple, pink
    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System Accent"
        case .blue: return "Blue"
        case .green: return "Green"
        case .orange: return "Orange"
        case .purple: return "Purple"
        case .pink: return "Pink"
        }
    }

    var color: Color {
        switch self {
        case .system: return .accentColor
        case .blue: return Tint.blue
        case .green: return Tint.green
        case .orange: return Tint.orange
        case .purple: return Tint.purple
        case .pink: return Tint.pink
        }
    }
}

@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @AppStorage("FoxClean.Appearance") private var rawValue: String = AppearanceMode.system.rawValue
    @AppStorage("FoxClean.Accent") private var rawAccent: String = AccentChoice.system.rawValue

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: rawValue) ?? .system }
        set { rawValue = newValue.rawValue; objectWillChange.send() }
    }

    var accent: AccentChoice {
        get { AccentChoice(rawValue: rawAccent) ?? .system }
        set { rawAccent = newValue.rawValue; objectWillChange.send() }
    }
}

/// Centralized accent palette. Keeping these in one place lets the dashboard
/// and sidebar share semantic tints (cleanup orange, performance green, etc.)
/// instead of scattered Color literals.
enum Tint {
    static let blue   = Color(red: 0.04, green: 0.52, blue: 1.00)
    static let green  = Color(red: 0.18, green: 0.78, blue: 0.47)
    static let orange = Color(red: 1.00, green: 0.62, blue: 0.04)
    static let purple = Color(red: 0.69, green: 0.32, blue: 0.87)
    static let pink   = Color(red: 1.00, green: 0.30, blue: 0.50)
    static let cyan   = Color(red: 0.30, green: 0.80, blue: 0.95)
    static let red    = Color(red: 1.00, green: 0.27, blue: 0.23)
    static let yellow = Color(red: 1.00, green: 0.78, blue: 0.04)
}

/// Tinted square icon container used in the sidebar and on dashboard cards.
struct IconTile: View {
    let systemName: String
    var tint: Color = Tint.blue
    var size: CGFloat = 26
    var corner: CGFloat = 7

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(tint.opacity(0.16))
            Image(systemName: systemName)
                .font(.system(size: size * 0.52, weight: .semibold))
                .foregroundStyle(tint)
        }
        .frame(width: size, height: size)
    }
}

/// Card surface used on the dashboard, suggestion list, and detail pages.
struct CardSurface<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }
}
