import Foundation
import SwiftData

/// Represents a single timer within a sequence
@Model
final class TimerModel {
    /// Unique identifier for the timer
    @Attribute(.unique) var id: UUID
    
    /// Short title for the timer (e.g., "Work", "Break")
    var title: String
    
    /// Duration of the timer in seconds
    var duration: Int
    
    /// The sequence this timer belongs to
    @Relationship(inverse: \TimerSequenceModel.timers)
    var sequence: TimerSequenceModel?
    
    /// Initialize a new timer
    /// - Parameters:
    ///   - id: Unique identifier (defaults to a new UUID)
    ///   - title: Short title for the timer
    ///   - duration: Duration in seconds
    init(
        id: UUID = UUID(),
        title: String,
        duration: Int
    ) {
        self.id = id
        self.title = title
        self.duration = duration
    }
    
    /// Returns the duration formatted as a string (e.g., "30:00")
    var formattedDuration: String {
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// Returns a copy of this timer
    func copy() -> TimerModel {
        let newTimer = TimerModel(
            title: self.title,
            duration: self.duration
        )
        
        return newTimer
    }
} 