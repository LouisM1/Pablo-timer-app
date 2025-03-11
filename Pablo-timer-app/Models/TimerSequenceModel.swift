import Foundation
import SwiftData

/// Represents a sequence of timers that run in order
@Model
final class TimerSequenceModel {
    /// Unique identifier for the sequence
    @Attribute(.unique) var id: UUID
    
    /// User-defined name for the sequence (e.g., "Morning Routine")
    var name: String
    
    /// The ordered list of timers in this sequence
    @Relationship(deleteRule: .cascade) var timers: [TimerModel]
    
    /// Whether the entire sequence should repeat
    var repeatSequence: Bool
    
    /// Optional recurrence rule if this sequence repeats
    @Relationship(deleteRule: .cascade, inverse: \RecurrenceRule.sequence)
    var recurrenceRule: RecurrenceRule?
    
    /// Date when this sequence was created
    var createdAt: Date
    
    /// Date when this sequence was last modified
    var updatedAt: Date
    
    /// Initialize a new timer sequence
    /// - Parameters:
    ///   - id: Unique identifier (defaults to a new UUID)
    ///   - name: User-defined name for the sequence
    ///   - timers: The ordered list of timers (defaults to empty array)
    ///   - repeatSequence: Whether the sequence repeats (defaults to false)
    ///   - recurrenceRule: Optional recurrence rule
    ///   - createdAt: Creation date (defaults to now)
    ///   - updatedAt: Last update date (defaults to now)
    init(
        id: UUID = UUID(),
        name: String,
        timers: [TimerModel] = [],
        repeatSequence: Bool = false,
        recurrenceRule: RecurrenceRule? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.timers = timers
        self.repeatSequence = repeatSequence
        self.recurrenceRule = recurrenceRule
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        
        // Set the sequence relationship on each timer
        for timer in timers {
            timer.sequence = self
        }
    }
    
    /// Adds a timer to the sequence
    /// - Parameter timer: The timer to add
    func addTimer(_ timer: TimerModel) {
        timer.sequence = self
        timers.append(timer)
        updatedAt = Date()
    }
    
    /// Removes a timer from the sequence
    /// - Parameter timer: The timer to remove
    func removeTimer(_ timer: TimerModel) {
        if let index = timers.firstIndex(where: { $0.id == timer.id }) {
            timers.remove(at: index)
            timer.sequence = nil
            updatedAt = Date()
        }
    }
    
    /// Reorders a timer in the sequence
    /// - Parameters:
    ///   - fromIndex: The current index of the timer
    ///   - toIndex: The new index for the timer
    func moveTimer(fromIndex: Int, toIndex: Int) {
        guard fromIndex != toIndex,
              fromIndex >= 0, fromIndex < timers.count,
              toIndex >= 0, toIndex < timers.count else {
            return
        }
        
        let timer = timers.remove(at: fromIndex)
        timers.insert(timer, at: toIndex)
        updatedAt = Date()
    }
    
    /// Returns the total duration of all timers in the sequence
    var totalDuration: Int {
        timers.reduce(0) { $0 + $1.duration }
    }
    
    /// Returns the total duration formatted as a string (e.g., "45:00")
    var formattedTotalDuration: String {
        let totalSeconds = totalDuration
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    /// Creates a copy of this sequence with all its timers
    func copy() -> TimerSequenceModel {
        let copiedTimers = timers.map { $0.copy() }
        
        let newSequence = TimerSequenceModel(
            name: self.name,
            timers: copiedTimers,
            repeatSequence: self.repeatSequence
        )
        
        if let rule = self.recurrenceRule {
            newSequence.recurrenceRule = RecurrenceRule(
                frequency: rule.frequency,
                interval: rule.interval,
                startDate: rule.startDate,
                endDate: rule.endDate
            )
        }
        
        return newSequence
    }
} 