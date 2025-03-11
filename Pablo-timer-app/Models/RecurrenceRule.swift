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
    
    /// Array of weekdays for weekly recurrence (0 = Sunday, 6 = Saturday)
    var weekdays: [Int]?
    
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
    ///   - weekdays: Optional array of weekdays for weekly recurrence
    init(frequency: RecurrenceFrequency, interval: Int = 1, startDate: Date? = nil, endDate: Date? = nil, weekdays: [Int]? = nil) {
        self.frequency = frequency
        self.interval = interval
        self.startDate = startDate
        self.endDate = endDate
        self.weekdays = weekdays
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
        
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        
        switch frequency {
        case .daily:
            dateComponents.day = interval
            return calendar.date(byAdding: dateComponents, to: fromDate)
            
        case .weekly:
            // If weekdays are specified, find the next occurrence based on the day of the week
            if let weekdays = weekdays, !weekdays.isEmpty {
                // Get the current weekday (0 = Sunday, 6 = Saturday)
                let currentWeekday = calendar.component(.weekday, from: fromDate) - 1
                
                // Sort weekdays to find the next one
                let sortedWeekdays = weekdays.sorted()
                
                // Find the next weekday
                if let nextWeekday = sortedWeekdays.first(where: { $0 > currentWeekday }) {
                    // Next weekday is later this week
                    let daysToAdd = nextWeekday - currentWeekday
                    dateComponents.day = daysToAdd
                } else {
                    // Next weekday is in the next week
                    let daysToAdd = (7 - currentWeekday) + sortedWeekdays.first!
                    dateComponents.day = daysToAdd
                }
                
                // Create the next date at the specified time
                var nextDate = calendar.date(byAdding: dateComponents, to: fromDate)!
                
                // Set the time component from the start date
                let startDateComponents = calendar.dateComponents([.hour, .minute, .second], from: startDate)
                var nextDateComponents = calendar.dateComponents([.year, .month, .day], from: nextDate)
                nextDateComponents.hour = startDateComponents.hour
                nextDateComponents.minute = startDateComponents.minute
                nextDateComponents.second = startDateComponents.second
                
                return calendar.date(from: nextDateComponents)
            } else {
                // If no weekdays are specified, just add weeks based on the interval
                dateComponents.day = interval * 7
                return calendar.date(byAdding: dateComponents, to: fromDate)
            }
            
        case .monthly:
            dateComponents.month = interval
            return calendar.date(byAdding: dateComponents, to: fromDate)
            
        case .custom:
            // For custom frequency, we'll just default to daily
            // In a real app, this would be more sophisticated
            dateComponents.day = interval
            return calendar.date(byAdding: dateComponents, to: fromDate)
        }
    }
} 