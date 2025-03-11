import XCTest
@testable import Pablo_timer_app

final class RecurrenceRuleTests: XCTestCase {
    
    func testInitialization() {
        // Test default initialization
        let rule = RecurrenceRule(frequency: .daily)
        XCTAssertEqual(rule.frequency, .daily)
        XCTAssertEqual(rule.interval, 1)
        XCTAssertNil(rule.startDate)
        XCTAssertNil(rule.endDate)
        
        // Test full initialization
        let now = Date()
        let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: now)!
        let customRule = RecurrenceRule(
            frequency: .weekly,
            interval: 2,
            startDate: now,
            endDate: futureDate
        )
        
        XCTAssertEqual(customRule.frequency, .weekly)
        XCTAssertEqual(customRule.interval, 2)
        XCTAssertEqual(customRule.startDate, now)
        XCTAssertEqual(customRule.endDate, futureDate)
    }
    
    func testNextDateCalculation() {
        let now = Date()
        
        // Test daily recurrence
        let dailyRule = RecurrenceRule(frequency: .daily, interval: 1, startDate: now)
        let nextDaily = dailyRule.nextDate(from: now)
        let expectedDaily = Calendar.current.date(byAdding: .day, value: 1, to: now)
        XCTAssertEqual(nextDaily?.timeIntervalSince1970.rounded(), expectedDaily?.timeIntervalSince1970.rounded())
        
        // Test weekly recurrence
        let weeklyRule = RecurrenceRule(frequency: .weekly, interval: 1, startDate: now)
        let nextWeekly = weeklyRule.nextDate(from: now)
        let expectedWeekly = Calendar.current.date(byAdding: .day, value: 7, to: now)
        XCTAssertEqual(nextWeekly?.timeIntervalSince1970.rounded(), expectedWeekly?.timeIntervalSince1970.rounded())
        
        // Test monthly recurrence
        let monthlyRule = RecurrenceRule(frequency: .monthly, interval: 1, startDate: now)
        let nextMonthly = monthlyRule.nextDate(from: now)
        let expectedMonthly = Calendar.current.date(byAdding: .month, value: 1, to: now)
        XCTAssertEqual(nextMonthly?.timeIntervalSince1970.rounded(), expectedMonthly?.timeIntervalSince1970.rounded())
        
        // Test with end date in the past
        let pastDate = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let expiredRule = RecurrenceRule(frequency: .daily, interval: 1, startDate: now, endDate: pastDate)
        XCTAssertNil(expiredRule.nextDate(from: now))
        
        // Test with start date in the future
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: now)!
        let futureRule = RecurrenceRule(frequency: .daily, interval: 1, startDate: futureDate)
        XCTAssertEqual(futureRule.nextDate(from: now), futureDate)
    }
    
    func testCustomIntervals() {
        let now = Date()
        
        // Test daily with interval 2 (every other day)
        let biDailyRule = RecurrenceRule(frequency: .daily, interval: 2, startDate: now)
        let nextBiDaily = biDailyRule.nextDate(from: now)
        let expectedBiDaily = Calendar.current.date(byAdding: .day, value: 2, to: now)
        XCTAssertEqual(nextBiDaily?.timeIntervalSince1970.rounded(), expectedBiDaily?.timeIntervalSince1970.rounded())
        
        // Test weekly with interval 2 (every other week)
        let biWeeklyRule = RecurrenceRule(frequency: .weekly, interval: 2, startDate: now)
        let nextBiWeekly = biWeeklyRule.nextDate(from: now)
        let expectedBiWeekly = Calendar.current.date(byAdding: .day, value: 14, to: now)
        XCTAssertEqual(nextBiWeekly?.timeIntervalSince1970.rounded(), expectedBiWeekly?.timeIntervalSince1970.rounded())
    }
} 