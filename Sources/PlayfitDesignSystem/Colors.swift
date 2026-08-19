import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension Color {
    public static let playfitBackground = dynamicColor(lightHex: "#f8fafc", darkHex: "#070a12")
    public static let playfitForeground = dynamicColor(lightHex: "#0f172a", darkHex: "#f8fafc")
    public static let playfitAccent = dynamicColor(lightHex: "#0f766e", darkHex: "#ff6a3d")
    public static let playfitAccentForeground = dynamicColor(lightHex: "#ffffff", darkHex: "#0f172a")
    public static let playfitInk = dynamicColor(lightHex: "#0d9488", darkHex: "#38bdf8")
    
    public static let playfitPositive = dynamicColor(lightHex: "#047857", darkHex: "#34d399")
    public static let playfitWarning = dynamicColor(lightHex: "#b45309", darkHex: "#fbbf24")
    public static let playfitNegative = dynamicColor(lightHex: "#be123c", darkHex: "#fb7185")
    public static let playfitNegativeForeground = dynamicColor(lightHex: "#ffffff", darkHex: "#0f172a")
    public static let playfitToneAccent = dynamicColor(lightHex: "#0369a1", darkHex: "#7dd3fc")
    public static let playfitIndigo = dynamicColor(lightHex: "#4f46e5", darkHex: "#4f46e5")

    /// Fixed dark navy (not scheme-dependent) for text on top of playfitInk,
    /// which is light-to-mid toned in both light and dark mode.
    public static let playfitInkForeground = dynamicColor(lightHex: "#0f172a", darkHex: "#0f172a")
}

extension Color {
    private static func parseHex(_ hex: String) -> (red: CGFloat, green: CGFloat, blue: CGFloat) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (r, g, b) = (int >> 16, int >> 8 & 0xff, int & 0xff)
        default:
            (r, g, b) = (0, 0, 0)
        }
        return (CGFloat(r) / 255.0, CGFloat(g) / 255.0, CGFloat(b) / 255.0)
    }

    private static func dynamicColor(lightHex: String, darkHex: String) -> Color {
        let light = parseHex(lightHex)
        let dark = parseHex(darkHex)
        
        #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
        return Color(uiColor: UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: dark.red, green: dark.green, blue: dark.blue, alpha: 1.0)
            } else {
                return UIColor(red: light.red, green: light.green, blue: light.blue, alpha: 1.0)
            }
        })
        #elseif os(macOS)
        return Color(nsColor: NSColor(name: nil) { appearance in
            if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                return NSColor(red: dark.red, green: dark.green, blue: dark.blue, alpha: 1.0)
            } else {
                return NSColor(red: light.red, green: light.green, blue: light.blue, alpha: 1.0)
            }
        })
        #else
        return Color(red: light.red, green: light.green, blue: light.blue)
        #endif
    }
}
