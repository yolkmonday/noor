import SwiftUI

// Noor Brand Colors - shared with the noor-expo mobile app's theme
extension Color {
    // Primary brand color - deep forest green (Colors.theme.primary in noor-expo)
    static let noorTeal = Color(red: 0x22 / 255, green: 0x57 / 255, blue: 0x51 / 255)

    // Yellow accent from logo - bright yellow with slight green tint
    static let noorYellow = Color(red: 0.94, green: 0.94, blue: 0.48)

    // backgroundGradient in noor-expo's Colors.theme
    static let noorGradient: [Color] = [
        Color(red: 0xC0 / 255, green: 0xD2 / 255, blue: 0xB1 / 255),
        Color(red: 0xA3 / 255, green: 0xBA / 255, blue: 0xA5 / 255),
        Color(red: 0x8F / 255, green: 0xA9 / 255, blue: 0x96 / 255),
    ]

    // textStrong / textBody in noor-expo's Colors.theme
    static let noorTextStrong = Color(red: 0x1A / 255, green: 0x1A / 255, blue: 0x1A / 255)
    static let noorTextBody = Color(red: 0x33 / 255, green: 0x33 / 255, blue: 0x33 / 255)
}

extension Font {
    static func outfit(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .bold, .heavy, .black:
            return .custom("Outfit-Bold", size: size)
        case .semibold, .medium:
            return .custom("Outfit-SemiBold", size: size)
        default:
            return .custom("Outfit-Regular", size: size)
        }
    }
}
