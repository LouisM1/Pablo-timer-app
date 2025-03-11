import Foundation
import SwiftData

/// Defines the frequency at which a timer or sequence recurs
enum RecurrenceFrequency: String, Codable, Hashable, CaseIterable {
    case daily
    case weekly
    case monthly
    case custom
    
    /// A human-readable description of the frequency
    var description: String {
        switch self {
        case .daily:
            return "Day(s)"
        case .weekly:
            return "Week(s)"
        case .monthly:
            return "Month(s)"
        case .custom:
            return "Custom"
        }
    }
}

/// Defines the recurrence pattern for timers or sequences
@Model
final class RecurrenceRule {
    /// The frequency of recurrence (daily, weekly, monthly, custom)
    var frequency: RecurrenceFrequency
    
    /// How many units of the frequency to skip before repeating
    /// For example, every 1 day, every 2 weeks, etc.
    var interval: Int
    
    /// Optional start date for the recurrence
    var startDate: Date?
    
    /// Optional end date for the recurrence
    var endDate: Date?
    
    /// The timer this rule belongs to
    @Relationship var timer: TimerModel?
    
    /// The sequence this rule belongs to
    @Relationship var sequence: TimerSequenceModel?
    
    /// Initialize a new recurrence rule
    /// - Parameters:
    ///   - frequency: The frequency of recurrence
    ///   - interval: How many units to skip before repeating
    ///   - startDate: Optional start date
    ///   - endDate: Optional end date
    init(frequency: RecurrenceFrequency, interval: Int = 1, startDate: Date? = nil, endDate: Date? = nil) {
        self.frequency = frequency
        self.interval = interval
        self.startDate = startDate
        self.endDate = endDate
    }
    
    /// Calculates the next occurrence date based on a given date
    /// - Parameter fromDate: The reference date to calculate from
    /// - Returns: The next date when this recurrence should occur
    func nextDate(from fromDate: Date = Date()) -> Date? {
        guard let startDate = startDate, fromDate >= startDate else {
            return startDate
        }
        
        if let endDate = endDate, fromDate > endDate {
            return nil
        }
        
        var dateComponents = DateComponents()
        
        switch frequency {
        case .daily:
            dateComponents.day = interval
        case .weekly:
            dateComponents.day = interval * 7
        case .monthly:
            dateComponents.month = interval
        case .custom:
            // For custom frequency, we'll just default to daily
            // In a real app, this would be more sophisticated
            dateComponents.day = interval
        }
        
        return Calendar.current.date(byAdding: dateComponents, to: fromDate)
    }
} 