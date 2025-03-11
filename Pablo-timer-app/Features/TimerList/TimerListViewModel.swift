import Foundation
import SwiftUI
import SwiftData
import Combine

/// View model for the timer list screen
@Observable
@MainActor
class TimerListViewModel {
    /// The list of timer sequences
    private(set) var timerSequences: [TimerSequenceModel] = []
    
    /// Whether the app is currently loading data
    private(set) var isLoading: Bool = false
    
    /// Error message if something goes wrong
    private(set) var errorMessage: String?
    
    /// The model context for SwiftData
    private let modelContext: ModelContext
    
    /// Initializes the view model with a model context
    /// - Parameter modelContext: The SwiftData model context
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchTimerSequences()
    }
    
    /// Fetches all timer sequences from the database
    func fetchTimerSequences() {
        isLoading = true
        errorMessage = nil
        
        do {
            let descriptor = FetchDescriptor<TimerSequenceModel>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
            timerSequences = try modelContext.fetch(descriptor)
            isLoading = false
        } catch {
            errorMessage = "Failed to fetch timer sequences: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    /// Creates a new timer sequence
    /// - Parameter name: The name of the new sequence
    /// - Returns: The created timer sequence
    @discardableResult
    func createTimerSequence(name: String) -> TimerSequenceModel {
        let newSequence = TimerSequenceModel(name: name)
        modelContext.insert(newSequence)
        
        do {
            try modelContext.save()
            fetchTimerSequences()
            HapticManager.shared.successFeedback()
            return newSequence
        } catch {
            errorMessage = "Failed to save new timer sequence: \(error.localizedDescription)"
            HapticManager.shared.errorFeedback()
            return newSequence
        }
    }
    
    /// Deletes a timer sequence
    /// - Parameter sequence: The sequence to delete
    func deleteTimerSequence(_ sequence: TimerSequenceModel) {
        modelContext.delete(sequence)
        
        do {
            try modelContext.save()
            fetchTimerSequences()
            HapticManager.shared.successFeedback()
        } catch {
            errorMessage = "Failed to delete timer sequence: \(error.localizedDescription)"
            HapticManager.shared.errorFeedback()
        }
    }
    
    /// Creates a sample timer sequence for testing
    func createSampleTimerSequence() {
        let workTimer = TimerModel(title: "Work", duration: 25 * 60)
        let breakTimer = TimerModel(title: "Break", duration: 5 * 60)
        
        let sequence = TimerSequenceModel(
            name: "Pomodoro",
            timers: [workTimer, breakTimer],
            repeatSequence: true
        )
        
        modelContext.insert(sequence)
        
        do {
            try modelContext.save()
            fetchTimerSequences()
        } catch {
            errorMessage = "Failed to create sample timer sequence: \(error.localizedDescription)"
        }
    }
} 