import XCTest
@testable import Pablo_timer_app

final class TimerModelTests: XCTestCase {
    
    func testInitialization() {
        // Test basic initialization
        let timer = TimerModel(title: "Work", duration: 1800)
        XCTAssertEqual(timer.title, "Work")
        XCTAssertEqual(timer.duration, 1800)
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
        // Create a timer
        let originalTimer = TimerModel(
            title: "Original",
            duration: 1500
        )
        
        // Copy the timer
        let copiedTimer = originalTimer.copy()
        
        // Verify the copy has the same properties but different ID
        XCTAssertNotEqual(originalTimer.id, copiedTimer.id)
        XCTAssertEqual(originalTimer.title, copiedTimer.title)
        XCTAssertEqual(originalTimer.duration, copiedTimer.duration)
        
        // Verify that modifying the copy doesn't affect the original
        copiedTimer.title = "Modified Copy"
        copiedTimer.duration = 2000
        
        XCTAssertEqual(originalTimer.title, "Original")
        XCTAssertEqual(originalTimer.duration, 1500)
        XCTAssertEqual(copiedTimer.title, "Modified Copy")
        XCTAssertEqual(copiedTimer.duration, 2000)
    }
} 