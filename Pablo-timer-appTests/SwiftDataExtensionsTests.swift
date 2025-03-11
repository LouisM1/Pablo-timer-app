import XCTest
import SwiftData
@testable import Pablo_timer_app

final class SwiftDataExtensionsTests: XCTestCase {
    var persistenceController: PersistenceController!
    var modelContext: ModelContext!
    
    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(inMemory: true)
        modelContext = persistenceController.modelContext
    }
    
    override func tearDown() {
        modelContext = nil
        persistenceController = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createSampleSequences(count: Int) {
        for i in 1...count {
            let sequence = TimerSequenceModel(name: "Sequence \(i)")
            let workTimer = TimerModel(title: "Work", duration: 25 * 60)
            let breakTimer = TimerModel(title: "Break", duration: 5 * 60)
            
            sequence.addTimer(workTimer)
            sequence.addTimer(breakTimer)
            
            modelContext.insert(sequence)
        }
        
        try? modelContext.save()
    }
    
    // MARK: - ModelContext Extension Tests
    
    func testDeleteAll() throws {
        // Given
        createSampleSequences(count: 5)
        
        // When
        let deletedCount = try modelContext.deleteAll(TimerSequenceModel.self)
        
        // Then
        XCTAssertEqual(deletedCount, 5)
        
        let remainingCount = try modelContext.count(TimerSequenceModel.self)
        XCTAssertEqual(remainingCount, 0)
    }
    
    func testExists() throws {
        // Given
        let sequence = TimerSequenceModel(name: "Test Sequence")
        modelContext.insert(sequence)
        try modelContext.save()
        
        // When - Check for existing ID
        let exists = try modelContext.exists(TimerSequenceModel.self, id: sequence.id, keyPath: \.id)
        
        // Then
        XCTAssertTrue(exists)
        
        // When - Check for non-existent ID
        let nonExistentExists = try modelContext.exists(TimerSequenceModel.self, id: UUID(), keyPath: \.id)
        
        // Then
        XCTAssertFalse(nonExistentExists)
    }
    
    func testCount() throws {
        // Given
        createSampleSequences(count: 3)
        
        // When
        let count = try modelContext.count(TimerSequenceModel.self)
        
        // Then
        XCTAssertEqual(count, 3)
    }
    
    // MARK: - FetchDescriptor Extension Tests
    
    func testFetchDescriptorLimit() throws {
        // Given
        createSampleSequences(count: 10)
        
        // When
        let descriptor = FetchDescriptor<TimerSequenceModel>().limit(5)
        let sequences = try modelContext.fetch(descriptor)
        
        // Then
        XCTAssertEqual(sequences.count, 5)
    }
    
    func testFetchDescriptorOffset() throws {
        // Given
        createSampleSequences(count: 10)
        
        // Create a sorted descriptor to ensure consistent results
        let sortDescriptor = SortDescriptor<TimerSequenceModel>(\.name)
        
        // When - Fetch all with sorting
        let allDescriptor = FetchDescriptor<TimerSequenceModel>().sorted(by: [sortDescriptor])
        let allSequences = try modelContext.fetch(allDescriptor)
        
        // When - Fetch with offset
        let offsetDescriptor = FetchDescriptor<TimerSequenceModel>()
            .sorted(by: [sortDescriptor])
            .offset(5)
        let offsetSequences = try modelContext.fetch(offsetDescriptor)
        
        // Then
        XCTAssertEqual(offsetSequences.count, 5)
        
        // The first sequence in offsetSequences should be the 6th in allSequences
        XCTAssertEqual(offsetSequences.first?.id, allSequences[5].id)
    }
    
    func testFetchDescriptorSorted() throws {
        // Given
        let sequence1 = TimerSequenceModel(name: "Z Sequence")
        let sequence2 = TimerSequenceModel(name: "A Sequence")
        let sequence3 = TimerSequenceModel(name: "M Sequence")
        
        modelContext.insert(sequence1)
        modelContext.insert(sequence2)
        modelContext.insert(sequence3)
        try modelContext.save()
        
        // When - Sort ascending by name
        let ascendingDescriptor = FetchDescriptor<TimerSequenceModel>()
            .sorted(by: [SortDescriptor(\.name, order: .forward)])
        let ascendingSequences = try modelContext.fetch(ascendingDescriptor)
        
        // Then
        XCTAssertEqual(ascendingSequences.count, 3)
        XCTAssertEqual(ascendingSequences[0].name, "A Sequence")
        XCTAssertEqual(ascendingSequences[1].name, "M Sequence")
        XCTAssertEqual(ascendingSequences[2].name, "Z Sequence")
        
        // When - Sort descending by name
        let descendingDescriptor = FetchDescriptor<TimerSequenceModel>()
            .sorted(by: [SortDescriptor(\.name, order: .reverse)])
        let descendingSequences = try modelContext.fetch(descendingDescriptor)
        
        // Then
        XCTAssertEqual(descendingSequences.count, 3)
        XCTAssertEqual(descendingSequences[0].name, "Z Sequence")
        XCTAssertEqual(descendingSequences[1].name, "M Sequence")
        XCTAssertEqual(descendingSequences[2].name, "A Sequence")
    }
    
    func testCombinedFetchDescriptorExtensions() throws {
        // Given
        createSampleSequences(count: 20)
        
        // When - Use multiple extensions together
        let descriptor = FetchDescriptor<TimerSequenceModel>()
            .sorted(by: [SortDescriptor(\.name)])
            .offset(5)
            .limit(10)
        
        let sequences = try modelContext.fetch(descriptor)
        
        // Then
        XCTAssertEqual(sequences.count, 10)
        
        // Verify we got sequences 6-15 (when sorted by name)
        let allDescriptor = FetchDescriptor<TimerSequenceModel>()
            .sorted(by: [SortDescriptor(\.name)])
        let allSequences = try modelContext.fetch(allDescriptor)
        
        for i in 0..<10 {
            XCTAssertEqual(sequences[i].id, allSequences[i + 5].id)
        }
    }
} 