//
//  Pablo_timer_appApp.swift
//  Pablo-timer-app
//
//  Created by Louis McAuliffe on 11/03/2025.
//

import SwiftUI
import SwiftData

@main
struct Pablo_timer_appApp: App {
    // Use the shared persistence controller
    @StateObject private var persistenceController = PersistenceController.shared
    
    init() {
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
        }
        // Use the model container from our persistence controller
        .modelContainer(persistenceController.modelContainer)
    }
}
