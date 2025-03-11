import Foundation
import UserNotifications
import UIKit
import OSLog

/// A service that manages timer notifications and background execution
@Observable
public final class TimerService {
    /// Shared instance of the timer service
    public static let shared = TimerService()
    
    /// Logger for debugging
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.pablo-timer-app", category: "TimerService")
    
    /// Whether the app has permission to send notifications
    private(set) public var hasNotificationPermission = false
    
    /// The current background task identifier
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    /// Initialize the timer service
    private init() {
        // Check notification authorization status
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.hasNotificationPermission = settings.authorizationStatus == .authorized
            }
        }
    }
    
    /// Request notification permission from the user
    public func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.hasNotificationPermission = granted
                if let error = error {
                    self.logger.error("Error requesting notification permission: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Schedule a notification for when a timer ends
    /// - Parameters:
    ///   - title: The notification title
    ///   - body: The notification body
    ///   - timeInterval: Time until the notification is shown
    ///   - identifier: A unique identifier for the notification
    public func scheduleTimerNotification(title: String, body: String, timeInterval: TimeInterval, identifier: String) {
        guard hasNotificationPermission else {
            requestNotificationPermission()
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "TIMER_NOTIFICATION"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                self.logger.error("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    /// Cancel a previously scheduled notification
    /// - Parameter identifier: The notification identifier
    public func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    /// Start a background task to keep the app running
    public func startBackgroundTask() {
        if backgroundTask != .invalid {
            endBackgroundTask()
        }
        
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }
    
    /// End the current background task
    public func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
}

// MARK: - Notification Action Setup
extension TimerService {
    /// Set up notification categories and actions
    public func setupNotificationActions() {
        let pauseAction = UNNotificationAction(
            identifier: "PAUSE_ACTION",
            title: "Pause",
            options: [.foreground]
        )
        
        let skipAction = UNNotificationAction(
            identifier: "SKIP_ACTION",
            title: "Skip",
            options: [.foreground]
        )
        
        let stopAction = UNNotificationAction(
            identifier: "STOP_ACTION",
            title: "Stop",
            options: [.foreground, .destructive]
        )
        
        let timerCategory = UNNotificationCategory(
            identifier: "TIMER_NOTIFICATION",
            actions: [pauseAction, skipAction, stopAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([timerCategory])
    }
} 