import Foundation
import SwiftData
import OSLog

/// Manages SwiftData persistence operations for the app
@Observable
final class PersistenceController {
    private let logger = Logger(subsystem: "com.pablo.timer-app", category: "Persistence")
    
    /// The shared instance for app-wide use
    static let shared = PersistenceController()
    
    /// The model container for SwiftData
    let modelContainer: ModelContainer
    
    /// The main context for SwiftData operations
    var modelContext: ModelContext
    
    /// Initialize with a specific schema and configurations
    /// - Parameter inMemory: Whether to use an in-memory store (useful for testing)
    init(inMemory: Bool = false) {
        do {
            let schema = Schema([
                TimerModel.self,
                TimerSequenceModel.self,
                RecurrenceRule.self
            ])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: inMemory
            )
            
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            modelContext = ModelContainer.shared.mainContext
            
            // Check for and perform migrations if needed (skip for in-memory stores)
            if !inMemory {
                MigrationManager.shared.checkAndPerformMigration()
            }
            
            logger.debug("PersistenceController initialized successfully")
        } catch {
            logger.error("Failed to initialize PersistenceController: \(error.localizedDescription)")
            fatalError("Failed to initialize PersistenceController: \(error.localizedDescription)")
        }
    }
    
    /// Creates a test instance with in-memory storage
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        
        // Add sample data for previews
        let sequence = TimerSequenceModel(name: "Sample Pomodoro")
        
        let workTimer = TimerModel(title: "Work", duration: 25 * 60)
        let breakTimer = TimerModel(title: "Break", duration: 5 * 60)
        
        sequence.addTimer(workTimer)
        sequence.addTimer(breakTimer)
        
        controller.save(sequence)
        
        return controller
    }()
    
    // MARK: - Timer Sequence Operations
    
    /// Saves a timer sequence to the persistent store
    /// - Parameter sequence: The sequence to save
    func save(_ sequence: TimerSequenceModel) {
        modelContext.insert(sequence)
        
        do {
            try modelContext.save()
            logger.debug("Saved sequence: \(sequence.name)")
        } catch {
            logger.error("Failed to save sequence: \(error.localizedDescription)")
            modelContext.rollback()
        }
    }
    
    /// Updates an existing timer sequence
    /// - Parameter sequence: The sequence to update
    func update(_ sequence: TimerSequenceModel) {
        sequence.updatedAt = Date()
        
        do {
            try modelContext.save()
            logger.debug("Updated sequence: \(sequence.name)")
        } catch {
            logger.error("Failed to update sequence: \(error.localizedDescription)")
            modelContext.rollback()
        }
    }
    
    /// Deletes a timer sequence from the persistent store
    /// - Parameter sequence: The sequence to delete
    func delete(_ sequence: TimerSequenceModel) {
        modelContext.delete(sequence)
        
        do {
            try modelContext.save()
            logger.debug("Deleted sequence: \(sequence.name)")
        } catch {
            logger.error("Failed to delete sequence: \(error.localizedDescription)")
            modelContext.rollback()
        }
    }
    
    /// Fetches all timer sequences from the persistent store
    /// - Returns: An array of timer sequences
    func fetchAllSequences() -> [TimerSequenceModel] {
        let descriptor = FetchDescriptor<TimerSequenceModel>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        
        do {
            let sequences = try modelContext.fetch(descriptor)
            logger.debug("Fetched \(sequences.count) sequences")
            return sequences
        } catch {
            logger.error("Failed to fetch sequences: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Fetches a specific timer sequence by ID
    /// - Parameter id: The UUID of the sequence to fetch
    /// - Returns: The timer sequence if found, nil otherwise
    func fetchSequence(withID id: UUID) -> TimerSequenceModel? {
        let predicate = #Predicate<TimerSequenceModel> { sequence in
            sequence.id == id
        }
        
        let descriptor = FetchDescriptor<TimerSequenceModel>(predicate: predicate)
        
        do {
            let sequences = try modelContext.fetch(descriptor)
            return sequences.first
        } catch {
            logger.error("Failed to fetch sequence with ID \(id): \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Fetches timer sequences that match a search term
    /// - Parameter searchTerm: The term to search for in sequence names
    /// - Returns: An array of matching timer sequences
    func searchSequences(matching searchTerm: String) -> [TimerSequenceModel] {
        let predicate = #Predicate<TimerSequenceModel> { sequence in
            sequence.name.localizedStandardContains(searchTerm)
        }
        
        let descriptor = FetchDescriptor<TimerSequenceModel>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        
        do {
            let sequences = try modelContext.fetch(descriptor)
            logger.debug("Found \(sequences.count) sequences matching '\(searchTerm)'")
            return sequences
        } catch {
            logger.error("Failed to search sequences: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Creates a duplicate of a timer sequence
    /// - Parameter sequence: The sequence to duplicate
    /// - Returns: The duplicated sequence
    func duplicateSequence(_ sequence: TimerSequenceModel) -> TimerSequenceModel {
        let duplicate = sequence.copy()
        duplicate.name = "\(sequence.name) (Copy)"
        
        save(duplicate)
        return duplicate
    }
} 