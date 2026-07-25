import SwiftUI
import UIKit

// Warm "省钱搭子" palette (same meaning-based colors as the web app).
extension Color {
    init(hex: UInt) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255.0,
                  green: Double((hex >> 8) & 0xFF) / 255.0,
                  blue: Double(hex & 0xFF) / 255.0,
                  opacity: 1.0)
    }
    static let bbBg      = Color(hex: 0xFAF7F0)
    static let bbSurface = Color(hex: 0xFFFDF8)
    static let bbInk     = Color(hex: 0x1F1F1F)
    static let bbInk2    = Color(hex: 0x6F6A60)
    static let bbLine    = Color(hex: 0xE8E0D2)
    static let bbGreen   = Color(hex: 0x3E5F4D)
    static let bbBlue    = Color(hex: 0xE5EEF7)
    static let bbRed     = Color(hex: 0xD98272)
}

// Duolingo-style chunky surface: flat fill + a darker 4px bottom edge (the "pressable" look).
let duoEdge = Color(hex: 0xE0D7C5)
let duoGreenEdge = Color(hex: 0x2C4537)

extension View {
    /// Cap a phone-designed content column on big screens (iPad) so it stays a
    /// centered, readable column instead of stretching edge-to-edge. No-op on iPhone.
    func bbPageWidth(_ maxWidth: CGFloat = 640) -> some View {
        frame(maxWidth: maxWidth).frame(maxWidth: .infinity)
    }

    func duo(_ fill: Color, _ edge: Color, radius: CGFloat = 16) -> some View {
        background(
            ZStack {
                RoundedRectangle(cornerRadius: radius).fill(edge)
                RoundedRectangle(cornerRadius: radius).fill(fill).padding(.bottom, 4)
            }
        )
    }
    // primary green CTA
    func duoPrimary(_ radius: CGFloat = 16) -> some View { duo(.bbGreen, duoGreenEdge, radius: radius) }
}


/// Dismiss the on-screen keyboard from anywhere.
func bbHideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}
