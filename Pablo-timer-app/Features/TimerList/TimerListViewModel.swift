import Foundation
import SwiftUI
import SwiftData
import Combine
import UIKit
import OSLog

// Import models
@preconcurrency import Pablo_timer_app

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
    let modelContext: ModelContext
    
    /// Currently running timer sequence (if any)
    private(set) var runningSequence: TimerSequenceModel?
    
    /// Current progress in the running sequence (0.0 to 1.0)
    private(set) var sequenceProgress: Double = 0.0
    
    /// Current timer index in the running sequence
    private(set) var currentTimerIndex: Int = 0
    
    /// Time remaining for the current timer in seconds
    private(set) var timeRemaining: Int = 0
    
    /// Total elapsed time in the sequence in seconds
    private(set) var elapsedTime: Int = 0
    
    /// Timer publisher for updating the timer
    private var timerPublisher: AnyCancellable?
    
    /// Timer service for background execution and notifications
    private let timerService = TimerService.shared
    
    /// Notification subscribers
    private var pauseSubscription: AnyCancellable?
    private var skipSubscription: AnyCancellable?
    private var stopSubscription: AnyCancellable?
    
    /// Initializes the view model with a model context
    /// - Parameter modelContext: The SwiftData model context
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        setupNotificationHandlers()
        fetchTimerSequences()
    }
    
    /// Sets up handlers for notification responses
    private func setupNotificationHandlers() {
        // Handle pause action
        pauseSubscription = NotificationCenter.default.publisher(for: NSNotification.Name("PAUSE_TIMER"))
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.pauseSequence()
            }
        
        // Handle skip action
        skipSubscription = NotificationCenter.default.publisher(for: NSNotification.Name("SKIP_TIMER"))
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.skipToNextTimer()
            }
        
        // Handle stop action
        stopSubscription = NotificationCenter.default.publisher(for: NSNotification.Name("STOP_TIMER"))
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.stopSequence()
            }
    }
    
    /// Skips to the next timer in sequence
    func skipToNextTimer() {
        guard let sequence = runningSequence, currentTimerIndex < sequence.timers.count else {
            return
        }
        
        // Cancel current notification
        timerService.cancelNotification(identifier: "timer_\(sequence.id.uuidString)")
        
        // Move to the next timer
        currentTimerIndex += 1
        
        // Check if we've reached the end of the sequence
        if currentTimerIndex >= sequence.timers.count {
            if sequence.repeatSequence {
                // Start over from the beginning
                currentTimerIndex = 0
                timeRemaining = sequence.timers[0].duration
                HapticManager.shared.successFeedback()
                
                // Schedule notification for the new timer
                scheduleTimerNotification()
            } else {
                // End the sequence
                stopSequence()
                HapticManager.shared.successFeedback()
                return
            }
        } else {
            // Move to the next timer
            timeRemaining = sequence.timers[currentTimerIndex].duration
            HapticManager.shared.successFeedback()
            
            // Schedule notification for the new timer
            scheduleTimerNotification()
        }
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
        // Stop the sequence if it's running
        if runningSequence?.id == sequence.id {
            stopSequence()
        }
        
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
    
    /// Reorders timer sequences
    /// - Parameters:
    ///   - fromIndex: The current index of the sequence
    ///   - toIndex: The new index for the sequence
    func moveTimerSequence(fromIndex: Int, toIndex: Int) {
        guard fromIndex != toIndex,
              fromIndex >= 0, fromIndex < timerSequences.count,
              toIndex >= 0, toIndex < timerSequences.count else {
            return
        }
        
        // Update the order in the local array
        let movedSequence = timerSequences.remove(at: fromIndex)
        timerSequences.insert(movedSequence, at: toIndex)
        
        // Update the timestamps to reflect the new order
        let now = Date()
        for (index, sequence) in timerSequences.enumerated() {
            // Add a small time difference to maintain the order
            sequence.updatedAt = now.addingTimeInterval(-Double(index))
        }
        
        do {
            try modelContext.save()
            HapticManager.shared.selectionFeedback()
        } catch {
            errorMessage = "Failed to reorder timer sequences: \(error.localizedDescription)"
            HapticManager.shared.errorFeedback()
            // Revert to the original order by fetching again
            fetchTimerSequences()
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
    
    /// Starts a timer sequence
    /// - Parameter sequence: The sequence to start
    func startSequence(_ sequence: TimerSequenceModel) {
        guard !sequence.timers.isEmpty else {
            errorMessage = "Cannot start a sequence with no timers"
            HapticManager.shared.errorFeedback()
            return
        }
        
        // Stop any currently running sequence
        stopSequence()
        
        // Set the running sequence and initialize timer values
        runningSequence = sequence
        currentTimerIndex = 0
        elapsedTime = 0
        timeRemaining = sequence.timers[0].duration
        updateProgress()
        
        // Start the timer
        timerPublisher = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTimer()
            }
        
        // Start background task to keep the app running
        timerService.startBackgroundTask()
        
        // Schedule notification for the current timer
        scheduleTimerNotification()
        
        HapticManager.shared.successFeedback()
    }
    
    /// Pauses the currently running sequence
    func pauseSequence() {
        timerPublisher?.cancel()
        timerPublisher = nil
        
        // Cancel any scheduled notifications
        if let sequence = runningSequence {
            timerService.cancelNotification(identifier: "timer_\(sequence.id.uuidString)")
        }
        
        // End background task
        timerService.endBackgroundTask()
        
        HapticManager.shared.mediumImpactFeedback()
    }
    
    /// Resumes the paused sequence
    func resumeSequence() {
        guard runningSequence != nil else { return }
        
        timerPublisher = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTimer()
            }
        
        // Start background task again
        timerService.startBackgroundTask()
        
        // Schedule notification again
        scheduleTimerNotification()
        
        HapticManager.shared.mediumImpactFeedback()
    }
    
    /// Stops the currently running sequence
    func stopSequence() {
        timerPublisher?.cancel()
        timerPublisher = nil
        
        // Cancel any scheduled notifications
        if let sequence = runningSequence {
            timerService.cancelNotification(identifier: "timer_\(sequence.id.uuidString)")
        }
        
        // End background task
        timerService.endBackgroundTask()
        
        runningSequence = nil
        currentTimerIndex = 0
        timeRemaining = 0
        elapsedTime = 0
        sequenceProgress = 0.0
    }
    
    /// Updates the timer on each tick
    private func updateTimer() {
        guard let sequence = runningSequence, currentTimerIndex < sequence.timers.count else {
            stopSequence()
            return
        }
        
        // Decrement time remaining
        if timeRemaining > 0 {
            timeRemaining -= 1
            elapsedTime += 1
            updateProgress()
        } else {
            // Move to the next timer
            currentTimerIndex += 1
            
            // Check if we've reached the end of the sequence
            if currentTimerIndex >= sequence.timers.count {
                if sequence.repeatSequence {
                    // Start over from the beginning
                    currentTimerIndex = 0
                    timeRemaining = sequence.timers[0].duration
                    HapticManager.shared.successFeedback()
                    
                    // Schedule notification for the new timer
                    scheduleTimerNotification()
                } else {
                    // End the sequence
                    stopSequence()
                    HapticManager.shared.successFeedback()
                    return
                }
            } else {
                // Move to the next timer
                timeRemaining = sequence.timers[currentTimerIndex].duration
                HapticManager.shared.successFeedback()
                
                // Schedule notification for the new timer
                scheduleTimerNotification()
            }
        }
    }
    
    /// Updates the progress value based on elapsed time
    private func updateProgress() {
        guard let sequence = runningSequence else {
            sequenceProgress = 0.0
            return
        }
        
        // Calculate progress as a percentage of total duration
        if sequence.totalDuration > 0 {
            sequenceProgress = Double(elapsedTime) / Double(sequence.totalDuration)
        } else {
            sequenceProgress = 0.0
        }
    }
    
    /// Schedules a notification for the current timer
    private func scheduleTimerNotification() {
        guard let sequence = runningSequence, 
              currentTimerIndex < sequence.timers.count else {
            return
        }
        
        let currentTimer = sequence.timers[currentTimerIndex]
        let nextTimerTitle: String
        
        // Determine the title for the next timer (if any)
        if currentTimerIndex + 1 < sequence.timers.count {
            nextTimerTitle = sequence.timers[currentTimerIndex + 1].title
        } else if sequence.repeatSequence && !sequence.timers.isEmpty {
            nextTimerTitle = sequence.timers[0].title
        } else {
            nextTimerTitle = "Completed"
        }
        
        let title = "\(currentTimer.title) Timer Completed"
        let body = "Up next: \(nextTimerTitle)"
        
        timerService.scheduleTimerNotification(
            title: title,
            body: body,
            timeInterval: TimeInterval(timeRemaining),
            identifier: "timer_\(sequence.id.uuidString)"
        )
    }
    
    /// Checks if a sequence is currently running
    /// - Parameter sequence: The sequence to check
    /// - Returns: True if the sequence is running
    func isSequenceRunning(_ sequence: TimerSequenceModel) -> Bool {
        return runningSequence?.id == sequence.id && timerPublisher != nil
    }
    
    /// Gets the progress for a specific sequence
    /// - Parameter sequence: The sequence to get progress for
    /// - Returns: Progress as a value between 0.0 and 1.0
    func progressForSequence(_ sequence: TimerSequenceModel) -> Double {
        return isSequenceRunning(sequence) ? sequenceProgress : 0.0
    }
} 