import SwiftUI

/// Font system for the app, providing access to custom fonts
enum FontSystem {
    /// Available font weights for Poppins
    enum Weight {
        case regular
        case medium
        case semiBold
        case bold
        case light
        case thin
        
        var value: String {
            switch self {
            case .regular:
                return "Regular"
            case .medium:
                return "Medium"
            case .semiBold:
                return "SemiBold"
            case .bold:
                return "Bold"
            case .light:
                return "Light"
            case .thin:
                return "Thin"
            }
        }
        
        var fontWeight: Font.Weight {
            switch self {
            case .regular:
                return .regular
            case .medium:
                return .medium
            case .semiBold:
                return .semibold
            case .bold:
                return .bold
            case .light:
                return .light
            case .thin:
                return .thin
            }
        }
    }
    
    /// Register all custom fonts
    static func registerFonts() {
        // Note: In a real app, you would dynamically register all fonts in the bundle
        // This is a placeholder for demonstration purposes
        print("Registering custom fonts...")
    }
    
    /// Get Poppins font with given size and weight
    /// - Parameters:
    ///   - size: Font size
    ///   - weight: Font weight
    /// - Returns: Font instance
    static func poppins(size: CGFloat, weight: Weight = .regular) -> Font {
        // In a real implementation with actual font files registered in the Info.plist,
        // we would use Font.custom("Poppins-\(weight.value)", size: size)
        // For now, we'll fall back to system font with the specified weight to avoid crashes
        return Font.system(size: size, weight: weight.fontWeight, design: .default)
    }
}

// Extension to SwiftUI Font for easier access to Poppins fonts
extension Font {
    /// Poppins font with regular weight
    static func poppinsRegular(size: CGFloat) -> Font {
        return FontSystem.poppins(size: size, weight: .regular)
    }
    
    /// Poppins font with medium weight
    static func poppinsMedium(size: CGFloat) -> Font {
        return FontSystem.poppins(size: size, weight: .medium)
    }
    
    /// Poppins font with semi-bold weight
    static func poppinsSemiBold(size: CGFloat) -> Font {
        return FontSystem.poppins(size: size, weight: .semiBold)
    }
    
    /// Poppins font with bold weight
    static func poppinsBold(size: CGFloat) -> Font {
        return FontSystem.poppins(size: size, weight: .bold)
    }
    
    /// Poppins font with light weight
    static func poppinsLight(size: CGFloat) -> Font {
        return FontSystem.poppins(size: size, weight: .light)
    }
    
    /// Poppins font with thin weight
    static func poppinsThin(size: CGFloat) -> Font {
        return FontSystem.poppins(size: size, weight: .thin)
    }
} 