import Foundation
import UIKit

/// Utility class for managing haptic feedback throughout the app
class HapticManager {
    /// Shared instance for singleton access
    static let shared = HapticManager()
    
    /// Private initializer for singleton pattern
    private init() {}
    
    /// Triggers a success haptic feedback
    func successFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /// Triggers an error haptic feedback
    func errorFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    /// Triggers a warning haptic feedback
    func warningFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    /// Triggers a light impact haptic feedback
    func lightImpactFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /// Triggers a medium impact haptic feedback
    func mediumImpactFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// Triggers a heavy impact haptic feedback
    func heavyImpactFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    /// Triggers a selection haptic feedback
    func selectionFeedback() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
} 