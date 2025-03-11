import XCTest
@testable import Pablo_timer_app

final class TimerModelTests: XCTestCase {
    
    func testInitialization() {
        // Test basic initialization
        let timer = TimerModel(title: "Work", duration: 1800)
        XCTAssertEqual(timer.title, "Work")
        XCTAssertEqual(timer.duration, 1800)
        XCTAssertFalse(timer.isRecurring)
        XCTAssertNil(timer.recurrenceRule)
        
        // Test initialization with recurrence
        let rule = RecurrenceRule(frequency: .daily)
        let recurringTimer = TimerModel(
            title: "Daily Workout",
            duration: 3600,
            isRecurring: true,
            recurrenceRule: rule
        )
        
        XCTAssertEqual(recurringTimer.title, "Daily Workout")
        XCTAssertEqual(recurringTimer.duration, 3600)
        XCTAssertTrue(recurringTimer.isRecurring)
        XCTAssertNotNil(recurringTimer.recurrenceRule)
        XCTAssertEqual(recurringTimer.recurrenceRule?.frequency, .daily)
    }
    
    func testFormattedDuration() {
        // Test minutes and seconds
        let timer1 = TimerModel(title: "Test", duration: 125)
        XCTAssertEqual(timer1.formattedDuration, "02:05")
        
        // Test hours worth of seconds
        let timer2 = TimerModel(title: "Test", duration: 3600)
        XCTAssertEqual(timer2.formattedDuration, "60:00")
        
        // Test zero
        let timer3 = TimerModel(title: "Test", duration: 0)
        XCTAssertEqual(timer3.formattedDuration, "00:00")
    }
    
    func testCopy() {
        // Create a timer with recurrence rule
        let rule = RecurrenceRule(frequency: .weekly, interval: 2)
        let originalTimer = TimerModel(
            title: "Original",
            duration: 1500,
            isRecurring: true,
            recurrenceRule: rule
        )
        
        // Copy the timer
        let copiedTimer = originalTimer.copy()
        
        // Verify the copy has the same properties but different ID
        XCTAssertNotEqual(originalTimer.id, copiedTimer.id)
        XCTAssertEqual(originalTimer.title, copiedTimer.title)
        XCTAssertEqual(originalTimer.duration, copiedTimer.duration)
        XCTAssertEqual(originalTimer.isRecurring, copiedTimer.isRecurring)
        
        // Verify recurrence rule was copied correctly
        XCTAssertNotNil(copiedTimer.recurrenceRule)
        XCTAssertEqual(copiedTimer.recurrenceRule?.frequency, .weekly)
        XCTAssertEqual(copiedTimer.recurrenceRule?.interval, 2)
        
        // Verify that modifying the copy doesn't affect the original
        copiedTimer.title = "Modified Copy"
        copiedTimer.duration = 2000
        
        XCTAssertEqual(originalTimer.title, "Original")
        XCTAssertEqual(originalTimer.duration, 1500)
        XCTAssertEqual(copiedTimer.title, "Modified Copy")
        XCTAssertEqual(copiedTimer.duration, 2000)
    }
} 