import SwiftUI

/// Defines the app's color scheme and theme
enum AppTheme {
    /// Color palette for the app
    enum Colors {
        /// Primary background color
        static let background = Color.white
        
        /// Dark background color for dark mode
        static let backgroundDark = Color.black
        
        /// Primary text color
        static let text = Color.black
        
        /// Secondary text color
        static let textSecondary = Color.gray
        
        /// Primary accent color - light purple
        static let accent = Color(red: 0.8, green: 0.7, blue: 1.0)
        
        /// Secondary accent color - darker purple
        static let accentSecondary = Color(red: 0.6, green: 0.5, blue: 0.9)
        
        /// Timer background color - light green
        static let timerBackground = Color(red: 0.7, green: 0.9, blue: 0.8)
        
        /// Button background color
        static let buttonBackground = Color.white
        
        /// Button border color
        static let buttonBorder = Color.gray.opacity(0.3)
    }
    
    /// Font styles for the app
    enum Typography {
        /// Font for large titles
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .default)
        
        /// Font for titles
        static let title = Font.system(size: 28, weight: .bold, design: .default)
        
        /// Font for subtitles
        static let subtitle = Font.system(size: 22, weight: .semibold, design: .default)
        
        /// Font for body text
        static let body = Font.system(size: 17, weight: .regular, design: .default)
        
        /// Font for captions
        static let caption = Font.system(size: 14, weight: .regular, design: .default)
        
        /// Font for timer display
        static let timer = Font.system(size: 60, weight: .thin, design: .default)
    }
    
    /// Layout constants for the app
    enum Layout {
        /// Standard padding
        static let padding: CGFloat = 16
        
        /// Small padding
        static let paddingSmall: CGFloat = 8
        
        /// Large padding
        static let paddingLarge: CGFloat = 24
        
        /// Corner radius for cards
        static let cornerRadius: CGFloat = 12
        
        /// Corner radius for buttons
        static let buttonCornerRadius: CGFloat = 8
    }
} 