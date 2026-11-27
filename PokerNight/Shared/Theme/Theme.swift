import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)

        let red = Double((value >> 16) & 0xff) / 255
        let green = Double((value >> 8) & 0xff) / 255
        let blue = Double(value & 0xff) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1)
    }
}

enum Theme {
    // PokerNight is meant to feel like a well-lit table after the cards are out:
    // calm enough to read at a glance, with one unmistakable decision color.
    static let background = Color(hex: "0A1D18")
    static let surface = Color(hex: "103126")
    static let surfaceRaised = Color(hex: "174638")
    static let surfaceMuted = Color(hex: "0D281F")
    static let cardFace = Color(hex: "F7F1E8")
    static let accent = Color(hex: "E7B75A")
    static let accentSoft = Color(hex: "3B321D")
    static let textPrimary = Color(hex: "F7F1E8")
    static let textSecondary = Color(hex: "B7C5BB")
    static let textTertiary = Color(hex: "7F9B8D")
    static let suitRed = Color(hex: "F06A62")
    static let success = Color(hex: "8ED4A5")
}

struct ThemedScreenModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.background.ignoresSafeArea())
            .scrollContentBackground(.hidden)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(Theme.background, for: .tabBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .tint(Theme.accent)
    }
}

struct ThemedSheetModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .themedScreen()
            .presentationBackground(Theme.background)
    }
}

extension View {
    func themedScreen() -> some View {
        modifier(ThemedScreenModifier())
    }

    func themedSheet() -> some View {
        modifier(ThemedSheetModifier())
    }

    func panel() -> some View {
        background(Theme.surface, in: RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Theme.textTertiary.opacity(0.25), lineWidth: 1)
            )
    }
}

enum ThemedButtonKind {
    case primary
    case strong
    case outline
    case destructive
    case quiet
}

struct ThemedButtonStyle: ButtonStyle {
    let kind: ThemedButtonKind

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 15)
        configuration.label
            .font(.system(.body, design: .rounded, weight: kind == .primary ? .semibold : .regular))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .background(background, in: shape)
            .overlay(shape.stroke(border ?? .clear, lineWidth: border == nil ? 0 : 1.5))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.72 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }

    private var foreground: Color {
        switch kind {
        case .primary:
            return Theme.textPrimary
        case .strong:
            return Theme.background
        case .outline:
            return Theme.textPrimary
        case .destructive:
            return Theme.suitRed
        case .quiet:
            return Theme.textSecondary
        }
    }

    private var background: Color {
        switch kind {
        case .primary:
            return Theme.surfaceRaised
        case .strong:
            return Theme.accent
        case .outline, .destructive, .quiet:
            return .clear
        }
    }

    private var border: Color? {
        switch kind {
        case .outline:
            return Theme.textTertiary
        case .destructive:
            return Theme.suitRed
        default:
            return nil
        }
    }
}
