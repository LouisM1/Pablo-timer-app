import XCTest
@testable import Pablo_timer_app

final class TimerSequenceModelTests: XCTestCase {
    
    func testInitialization() {
        // Test basic initialization
        let sequence = TimerSequenceModel(name: "Morning Routine")
        XCTAssertEqual(sequence.name, "Morning Routine")
        XCTAssertTrue(sequence.timers.isEmpty)
        XCTAssertFalse(sequence.repeatSequence)
        XCTAssertNil(sequence.recurrenceRule)
        
        // Test initialization with timers
        let timer1 = TimerModel(title: "Work", duration: 1800)
        let timer2 = TimerModel(title: "Break", duration: 300)
        let sequenceWithTimers = TimerSequenceModel(
            name: "Work Session",
            timers: [timer1, timer2]
        )
        
        XCTAssertEqual(sequenceWithTimers.name, "Work Session")
        XCTAssertEqual(sequenceWithTimers.timers.count, 2)
        XCTAssertEqual(sequenceWithTimers.timers[0].title, "Work")
        XCTAssertEqual(sequenceWithTimers.timers[1].title, "Break")
        
        // Verify sequence relationship was set on timers
        XCTAssertNotNil(timer1.sequence)
        XCTAssertEqual(timer1.sequence?.id, sequenceWithTimers.id)
        XCTAssertNotNil(timer2.sequence)
        XCTAssertEqual(timer2.sequence?.id, sequenceWithTimers.id)
    }
    
    func testAddTimer() {
        let sequence = TimerSequenceModel(name: "Test Sequence")
        let timer = TimerModel(title: "Test Timer", duration: 600)
        
        sequence.addTimer(timer)
        
        XCTAssertEqual(sequence.timers.count, 1)
        XCTAssertEqual(sequence.timers[0].id, timer.id)
        XCTAssertNotNil(timer.sequence)
        XCTAssertEqual(timer.sequence?.id, sequence.id)
    }
    
    func testRemoveTimer() {
        let timer1 = TimerModel(title: "Timer 1", duration: 600)
        let timer2 = TimerModel(title: "Timer 2", duration: 300)
        let sequence = TimerSequenceModel(name: "Test Sequence", timers: [timer1, timer2])
        
        XCTAssertEqual(sequence.timers.count, 2)
        
        sequence.removeTimer(timer1)
        
        XCTAssertEqual(sequence.timers.count, 1)
        XCTAssertEqual(sequence.timers[0].id, timer2.id)
        XCTAssertNil(timer1.sequence)
        XCTAssertNotNil(timer2.sequence)
    }
    
    func testMoveTimer() {
        let timer1 = TimerModel(title: "Timer 1", duration: 600)
        let timer2 = TimerModel(title: "Timer 2", duration: 300)
        let timer3 = TimerModel(title: "Timer 3", duration: 900)
        let sequence = TimerSequenceModel(name: "Test Sequence", timers: [timer1, timer2, timer3])
        
        // Move timer from index 0 to index 2
        sequence.moveTimer(fromIndex: 0, toIndex: 2)
        
        XCTAssertEqual(sequence.timers[0].id, timer2.id)
        XCTAssertEqual(sequence.timers[1].id, timer3.id)
        XCTAssertEqual(sequence.timers[2].id, timer1.id)
        
        // Move timer from index 2 to index 1
        sequence.moveTimer(fromIndex: 2, toIndex: 1)
        
        XCTAssertEqual(sequence.timers[0].id, timer2.id)
        XCTAssertEqual(sequence.timers[1].id, timer1.id)
        XCTAssertEqual(sequence.timers[2].id, timer3.id)
        
        // Test invalid indices
        let originalOrder = sequence.timers.map { $0.id }
        sequence.moveTimer(fromIndex: -1, toIndex: 1)
        sequence.moveTimer(fromIndex: 0, toIndex: 5)
        sequence.moveTimer(fromIndex: 3, toIndex: 0)
        
        // Order should remain unchanged
        XCTAssertEqual(sequence.timers.map { $0.id }, originalOrder)
    }
    
    func testTotalDuration() {
        let timer1 = TimerModel(title: "Timer 1", duration: 600)
        let timer2 = TimerModel(title: "Timer 2", duration: 300)
        let timer3 = TimerModel(title: "Timer 3", duration: 900)
        let sequence = TimerSequenceModel(name: "Test Sequence", timers: [timer1, timer2, timer3])
        
        XCTAssertEqual(sequence.totalDuration, 1800) // 600 + 300 + 900 = 1800
        
        // Add another timer
        let timer4 = TimerModel(title: "Timer 4", duration: 1200)
        sequence.addTimer(timer4)
        
        XCTAssertEqual(sequence.totalDuration, 3000) // 1800 + 1200 = 3000
    }
    
    func testFormattedTotalDuration() {
        // Test minutes and seconds
        let timer1 = TimerModel(title: "Timer 1", duration: 125)
        let sequence1 = TimerSequenceModel(name: "Test 1", timers: [timer1])
        XCTAssertEqual(sequence1.formattedTotalDuration, "02:05")
        
        // Test hours, minutes, and seconds
        let timer2 = TimerModel(title: "Timer 2", duration: 3600)
        let timer3 = TimerModel(title: "Timer 3", duration: 1800)
        let timer4 = TimerModel(title: "Timer 4", duration: 45)
        let sequence2 = TimerSequenceModel(name: "Test 2", timers: [timer2, timer3, timer4])
        XCTAssertEqual(sequence2.formattedTotalDuration, "1:30:45")
        
        // Test zero
        let sequence3 = TimerSequenceModel(name: "Test 3")
        XCTAssertEqual(sequence3.formattedTotalDuration, "00:00")
    }
    
    func testCopy() {
        // Create a sequence with timers and recurrence rule
        let timer1 = TimerModel(title: "Work", duration: 1800)
        let timer2 = TimerModel(title: "Break", duration: 300)
        let rule = RecurrenceRule(frequency: .daily)
        
        let originalSequence = TimerSequenceModel(
            name: "Pomodoro",
            timers: [timer1, timer2],
            repeatSequence: true,
            recurrenceRule: rule
        )
        
        // Copy the sequence
        let copiedSequence = originalSequence.copy()
        
        // Verify the copy has the same properties but different ID
        XCTAssertNotEqual(originalSequence.id, copiedSequence.id)
        XCTAssertEqual(originalSequence.name, copiedSequence.name)
        XCTAssertEqual(originalSequence.repeatSequence, copiedSequence.repeatSequence)
        
        // Verify timers were copied correctly
        XCTAssertEqual(copiedSequence.timers.count, 2)
        XCTAssertEqual(copiedSequence.timers[0].title, "Work")
        XCTAssertEqual(copiedSequence.timers[1].title, "Break")
        
        // Verify timer IDs are different
        XCTAssertNotEqual(originalSequence.timers[0].id, copiedSequence.timers[0].id)
        XCTAssertNotEqual(originalSequence.timers[1].id, copiedSequence.timers[1].id)
        
        // Verify recurrence rule was copied correctly
        XCTAssertNotNil(copiedSequence.recurrenceRule)
        XCTAssertEqual(copiedSequence.recurrenceRule?.frequency, .daily)
        
        // Verify that modifying the copy doesn't affect the original
        copiedSequence.name = "Modified Copy"
        copiedSequence.timers[0].title = "Modified Timer"
        
        XCTAssertEqual(originalSequence.name, "Pomodoro")
        XCTAssertEqual(originalSequence.timers[0].title, "Work")
        XCTAssertEqual(copiedSequence.name, "Modified Copy")
        XCTAssertEqual(copiedSequence.timers[0].title, "Modified Timer")
    }
} 