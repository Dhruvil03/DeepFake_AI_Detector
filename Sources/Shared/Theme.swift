import SwiftUI

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&rgb)
        let r = Double((rgb & 0xFF0000) >> 16) / 255
        let g = Double((rgb & 0x00FF00) >> 8) / 255
        let b = Double(rgb & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

/// Palette pulled from the original Proofy browser-extension UI (popup.css) —
/// the Android app itself ships no brand colors (its icon is a plain white
/// mark). This is a dark "neon glass" theme.
enum ProofyPalette {
    static let background = Color(hex: "020202")
    static let surface = Color.white.opacity(0.03)
    static let neonGreen = Color(hex: "00FF88")
    static let neonBlue = Color(hex: "00D1FF")
    static let alertRed = Color(hex: "FF3366")
    /// Not in the original palette (it only defines green/blue/red) — added
    /// for the "inconclusive" verdict so it stays in the same neon family.
    static let neonAmber = Color(hex: "FFD23F")
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.8)
    static let textTertiary = Color.white.opacity(0.4)
    static let glassBorder = Color.white.opacity(0.1)
}

struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 20
    func body(content: Content) -> some View {
        content
            .padding()
            .background(ProofyPalette.surface, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius).stroke(ProofyPalette.glassBorder))
    }
}
extension View {
    func glassCard(cornerRadius: CGFloat = 20) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }
}

/// Mirrors .primary-btn / .intel-btn from popup.css: tinted glass, glow border.
struct NeonButtonStyle: ButtonStyle {
    var color: Color = ProofyPalette.neonGreen
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .heavy))
            .foregroundStyle(color)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(color.opacity(configuration.isPressed ? 0.18 : 0.1))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(color.opacity(0.3)))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Mirrors .secondary-btn from popup.css: faint white glass.
struct NeonSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(ProofyPalette.textPrimary)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(configuration.isPressed ? 0.06 : 0.03))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(ProofyPalette.glassBorder))
            .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

/// Applies the dark neon-glass background to a screen.
struct ProofyBackground: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            ProofyPalette.background.ignoresSafeArea()
            content
        }
        .preferredColorScheme(.dark)
    }
}
extension View {
    func proofyBackground() -> some View { modifier(ProofyBackground()) }
}
