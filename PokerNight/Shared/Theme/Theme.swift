import SwiftUI
import UIKit

extension Color {
    fileprivate init(light: String, dark: String) {
        self.init(uiColor: UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

private extension UIColor {
    convenience init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        self.init(
            red: CGFloat((value >> 16) & 0xff) / 255,
            green: CGFloat((value >> 8) & 0xff) / 255,
            blue: CGFloat(value & 0xff) / 255,
            alpha: 1
        )
    }
}

enum Theme {
    // PokerCalc uses a neutral score-sheet canvas and an ink-indigo decision color.
    // Every value is semantic and paired deliberately for light and dark appearances.
    static let background = Color(light: "F5F5F7", dark: "111118")
    static let surfacePrimary = Color(light: "FFFFFF", dark: "1B1B24")
    static let surfaceSecondary = Color(light: "ECECF1", dark: "242431")
    static let surfaceElevated = Color(light: "FFFFFF", dark: "2B2B39")

    static let textPrimary = Color(light: "17171C", dark: "F6F3EF")
    static let textSecondary = Color(light: "52525E", dark: "C6C3CE")
    static let textTertiary = Color(light: "6D6D79", dark: "9793A3")

    static let actionPrimary = Color(light: "343568", dark: "AEB2FF")
    static let onActionPrimary = Color(light: "FFFFFF", dark: "171722")
    static let actionSecondary = Color(light: "E6E6F3", dark: "303044")
    static let destructive = Color(light: "B9384E", dark: "FF7A8B")
    static let success = Color(light: "28735F", dark: "72C6AA")
    static let warning = Color(light: "9A5A12", dark: "F0B15A")

    static let cardFace = Color(light: "FFFEFB", dark: "F4F0E8")
    static let suitRed = Color(light: "B9384E", dark: "C94559")
    static let suitBlack = Color(light: "17171C", dark: "17171C")
    static let currentActorSurface = Color(light: "E8E8FA", dark: "303052")
    static let currentActorBorder = Color(light: "4B4D91", dark: "BFC2FF")
    static let disabled = Color(light: "A7A7B0", dark: "6C6976")
    static let border = Color(light: "D8D8DF", dark: "3B3948")
    static let borderStrong = Color(light: "A6A6B2", dark: "686576")
    static let focus = Color(light: "4B4D91", dark: "BFC2FF")

    // Compatibility aliases while older feature views move to the richer semantic roles.
    static let surface = surfacePrimary
    static let surfaceRaised = surfaceElevated
    static let surfaceMuted = surfaceSecondary
    static let accent = actionPrimary
    static let accentSoft = currentActorSurface

    enum Spacing {
        static let xSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let standard: CGFloat = 16
        static let large: CGFloat = 20
        static let xLarge: CGFloat = 24
        static let section: CGFloat = 32
    }

    enum Radius {
        static let compact: CGFloat = 10
        static let control: CGFloat = 14
        static let panel: CGFloat = 18
        static let hero: CGFloat = 24
    }

    enum Typography {
        static let display = Font.system(.largeTitle, design: .serif, weight: .bold)
        static let title = Font.system(.title, design: .serif, weight: .bold)
        static let actor = Font.system(.title, design: .serif, weight: .bold)
        static let metric = Font.system(.largeTitle, design: .rounded, weight: .bold).monospacedDigit()
    }
}

struct ThemedScreenModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.background.ignoresSafeArea())
            .scrollContentBackground(.hidden)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(Theme.background, for: .tabBar)
            .tint(Theme.actionPrimary)
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
        background(Theme.surfacePrimary, in: .rect(cornerRadius: Theme.Radius.panel))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.panel)
                    .stroke(Theme.border, lineWidth: 1)
            }
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
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.control)

        configuration.label
            .font(.body.weight(kind == .strong ? .semibold : .medium))
            .foregroundStyle(foreground)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .padding(.horizontal, Theme.Spacing.medium)
            .background(background, in: shape)
            .overlay {
                shape.stroke(border ?? .clear, lineWidth: border == nil ? 0 : 1.5)
            }
            .contentShape(shape)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
            .opacity(isEnabled ? (configuration.isPressed ? 0.78 : 1) : 0.45)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }

    private var foreground: Color {
        switch kind {
        case .strong:
            Theme.onActionPrimary
        case .destructive:
            Theme.destructive
        case .quiet:
            Theme.textSecondary
        case .primary, .outline:
            Theme.textPrimary
        }
    }

    private var background: Color {
        switch kind {
        case .strong:
            Theme.actionPrimary
        case .primary:
            Theme.actionSecondary
        case .outline, .destructive, .quiet:
            .clear
        }
    }

    private var border: Color? {
        switch kind {
        case .outline:
            Theme.borderStrong
        case .destructive:
            Theme.destructive
        default:
            nil
        }
    }
}
