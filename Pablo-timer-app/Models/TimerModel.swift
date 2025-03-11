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
    
    /// Whether this timer repeats on some schedule
    var isRecurring: Bool
    
    /// Optional recurrence rule if this timer repeats
    @Relationship(deleteRule: .cascade, inverse: \RecurrenceRule.timer)
    var recurrenceRule: RecurrenceRule?
    
    /// The sequence this timer belongs to
    @Relationship(inverse: \TimerSequenceModel.timers)
    var sequence: TimerSequenceModel?
    
    /// Initialize a new timer
    /// - Parameters:
    ///   - id: Unique identifier (defaults to a new UUID)
    ///   - title: Short title for the timer
    ///   - duration: Duration in seconds
    ///   - isRecurring: Whether this timer repeats
    ///   - recurrenceRule: Optional recurrence rule
    init(
        id: UUID = UUID(),
        title: String,
        duration: Int,
        isRecurring: Bool = false,
        recurrenceRule: RecurrenceRule? = nil
    ) {
        self.id = id
        self.title = title
        self.duration = duration
        self.isRecurring = isRecurring
        self.recurrenceRule = recurrenceRule
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
            duration: self.duration,
            isRecurring: self.isRecurring
        )
        
        if let rule = self.recurrenceRule {
            newTimer.recurrenceRule = RecurrenceRule(
                frequency: rule.frequency,
                interval: rule.interval,
                startDate: rule.startDate,
                endDate: rule.endDate
            )
        }
        
        return newTimer
    }
} 