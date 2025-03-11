//
//  Pablo_timer_appApp.swift
//  Pablo-timer-app
//
//  Created by Louis McAuliffe on 11/03/2025.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct Pablo_timer_appApp: App {
    // Use the shared persistence controller
    // Since PersistenceController is now @MainActor, we need to use @StateObject
    // which is already main-actor isolated
    @StateObject private var persistenceController = PersistenceController.shared
    
    // Access the shared timer service
    @State private var timerService = TimerService.shared
    
    // For handling notification responses
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
    init() {
        // Register custom fonts
        FontSystem.registerFonts()
        
        // The migration check is performed in the PersistenceController initialization
        // This is just for documentation purposes
        #if DEBUG
        print("App initialized with schema version: \(MigrationManager.shared.currentSchemaVersion)")
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.modelContext, persistenceController.modelContext)
                .onAppear {
                    // Setup notification actions
                    timerService.setupNotificationActions()
                    
                    // Request notification permissions if not already granted
                    if !timerService.hasNotificationPermission {
                        timerService.requestNotificationPermission()
                    }
                }
        }
        // Use the model container from our persistence controller
        .modelContainer(persistenceController.modelContainer)
    }
}

/// App delegate for handling notification responses
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Set the delegate to handle notifications
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    /// Called when a notification is received while the app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show the notification even when the app is in foreground
        completionHandler([.banner, .sound])
    }
    
    /// Called when the user responds to a notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Extract the identifier from the notification
        let identifier = response.notification.request.identifier
        let actionIdentifier = response.actionIdentifier
        
        // Handle different actions
        if actionIdentifier == "PAUSE_ACTION" {
            // Pause the timer - this will be handled in the view model when the app opens
            NotificationCenter.default.post(name: NSNotification.Name("PAUSE_TIMER"), object: identifier)
        } else if actionIdentifier == "SKIP_ACTION" {
            // Skip to the next timer
            NotificationCenter.default.post(name: NSNotification.Name("SKIP_TIMER"), object: identifier)
        } else if actionIdentifier == "STOP_ACTION" {
            // Stop the timer
            NotificationCenter.default.post(name: NSNotification.Name("STOP_TIMER"), object: identifier)
        }
        
        completionHandler()
    }
}
