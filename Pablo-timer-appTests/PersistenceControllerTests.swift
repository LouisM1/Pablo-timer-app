import XCTest
import SwiftData
@testable import Pablo_timer_app

final class PersistenceControllerTests: XCTestCase {
    var persistenceController: PersistenceController!
    
    override func setUp() {
        super.setUp()
        // Create an in-memory persistence controller for testing
        persistenceController = PersistenceController(inMemory: true)
    }
    
    override func tearDown() {
        persistenceController = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createSampleSequence(name: String = "Test Sequence") -> TimerSequenceModel {
        let sequence = TimerSequenceModel(name: name)
        let workTimer = TimerModel(title: "Work", duration: 25 * 60)
        let breakTimer = TimerModel(title: "Break", duration: 5 * 60)
        
        sequence.addTimer(workTimer)
        sequence.addTimer(breakTimer)
        
        return sequence
    }
    
    // MARK: - Tests
    
    func testSaveSequence() {
        // Given
        let sequence = createSampleSequence()
        
        // When
        persistenceController.save(sequence)
        
        // Then
        let fetchedSequences = persistenceController.fetchAllSequences()
        XCTAssertEqual(fetchedSequences.count, 1)
        XCTAssertEqual(fetchedSequences.first?.name, "Test Sequence")
        XCTAssertEqual(fetchedSequences.first?.timers.count, 2)
    }
    
    func testUpdateSequence() {
        // Given
        let sequence = createSampleSequence()
        persistenceController.save(sequence)
        
        // When
        let originalDate = sequence.updatedAt
        // Wait a moment to ensure the updatedAt timestamp will be different
        Thread.sleep(forTimeInterval: 0.1)
        
        sequence.name = "Updated Sequence"
        persistenceController.update(sequence)
        
        // Then
        let fetchedSequence = persistenceController.fetchSequence(withID: sequence.id)
        XCTAssertEqual(fetchedSequence?.name, "Updated Sequence")
        XCTAssertGreaterThan(fetchedSequence!.updatedAt, originalDate)
    }
    
    func testDeleteSequence() {
        // Given
        let sequence = createSampleSequence()
        persistenceController.save(sequence)
        
        // When
        persistenceController.delete(sequence)
        
        // Then
        let fetchedSequences = persistenceController.fetchAllSequences()
        XCTAssertEqual(fetchedSequences.count, 0)
    }
    
    func testFetchAllSequences() {
        // Given
        let sequence1 = createSampleSequence(name: "Sequence 1")
        let sequence2 = createSampleSequence(name: "Sequence 2")
        let sequence3 = createSampleSequence(name: "Sequence 3")
        
        persistenceController.save(sequence1)
        persistenceController.save(sequence2)
        persistenceController.save(sequence3)
        
        // When
        let fetchedSequences = persistenceController.fetchAllSequences()
        
        // Then
        XCTAssertEqual(fetchedSequences.count, 3)
        
        // Verify they're sorted by updatedAt in reverse order
        // Since we just created them in order, sequence3 should be first
        XCTAssertEqual(fetchedSequences[0].name, "Sequence 3")
        XCTAssertEqual(fetchedSequences[1].name, "Sequence 2")
        XCTAssertEqual(fetchedSequences[2].name, "Sequence 1")
    }
    
    func testFetchSequenceByID() {
        // Given
        let sequence = createSampleSequence()
        persistenceController.save(sequence)
        
        // When
        let fetchedSequence = persistenceController.fetchSequence(withID: sequence.id)
        
        // Then
        XCTAssertNotNil(fetchedSequence)
        XCTAssertEqual(fetchedSequence?.id, sequence.id)
        XCTAssertEqual(fetchedSequence?.name, sequence.name)
    }
    
    func testFetchNonExistentSequence() {
        // Given
        let nonExistentID = UUID()
        
        // When
        let fetchedSequence = persistenceController.fetchSequence(withID: nonExistentID)
        
        // Then
        XCTAssertNil(fetchedSequence)
    }
    
    func testSearchSequences() {
        // Given
        let sequence1 = createSampleSequence(name: "Work Pomodoro")
        let sequence2 = createSampleSequence(name: "Study Session")
        let sequence3 = createSampleSequence(name: "Workout Routine")
        
        persistenceController.save(sequence1)
        persistenceController.save(sequence2)
        persistenceController.save(sequence3)
        
        // When - Search for sequences containing "work"
        let workSequences = persistenceController.searchSequences(matching: "work")
        
        // Then
        XCTAssertEqual(workSequences.count, 2) // Should find "Work Pomodoro" and "Workout Routine"
        XCTAssertTrue(workSequences.contains(where: { $0.name == "Work Pomodoro" }))
        XCTAssertTrue(workSequences.contains(where: { $0.name == "Workout Routine" }))
        XCTAssertFalse(workSequences.contains(where: { $0.name == "Study Session" }))
    }
    
    func testDuplicateSequence() {
        // Given
        let originalSequence = createSampleSequence(name: "Original Sequence")
        persistenceController.save(originalSequence)
        
        // When
        let duplicatedSequence = persistenceController.duplicateSequence(originalSequence)
        
        // Then
        XCTAssertEqual(duplicatedSequence.name, "Original Sequence (Copy)")
        XCTAssertEqual(duplicatedSequence.timers.count, originalSequence.timers.count)
        
        // Verify the duplicate is saved
        let fetchedSequences = persistenceController.fetchAllSequences()
        XCTAssertEqual(fetchedSequences.count, 2)
    }
    
    func testRelationshipIntegrity() {
        // Given
        let sequence = createSampleSequence()
        persistenceController.save(sequence)
        
        // When
        let fetchedSequence = persistenceController.fetchSequence(withID: sequence.id)
        
        // Then
        XCTAssertNotNil(fetchedSequence)
        XCTAssertEqual(fetchedSequence?.timers.count, 2)
        
        // Verify the bidirectional relationship
        for timer in fetchedSequence!.timers {
            XCTAssertEqual(timer.sequence?.id, fetchedSequence?.id)
        }
    }
    
    func testCascadeDeletion() {
        // Given
        let sequence = createSampleSequence()
        persistenceController.save(sequence)
        
        // Capture timer IDs for later verification
        let timerIDs = sequence.timers.map { $0.id }
        
        // When
        persistenceController.delete(sequence)
        
        // Then
        // Verify the sequence is deleted
        let fetchedSequence = persistenceController.fetchSequence(withID: sequence.id)
        XCTAssertNil(fetchedSequence)
        
        // Verify the timers are also deleted (cascade)
        // This requires a direct fetch from the context since we don't have a timer fetch method
        for timerID in timerIDs {
            let predicate = #Predicate<TimerModel> { timer in
                timer.id == timerID
            }
            let descriptor = FetchDescriptor<TimerModel>(predicate: predicate)
            
            do {
                let timers = try persistenceController.modelContext.fetch(descriptor)
                XCTAssertEqual(timers.count, 0, "Timer should be deleted due to cascade rule")
            } catch {
                XCTFail("Failed to fetch timer: \(error.localizedDescription)")
            }
        }
    }
} 