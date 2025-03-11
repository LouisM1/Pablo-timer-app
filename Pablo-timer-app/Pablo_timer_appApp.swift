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
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [TimerModel.self, TimerSequenceModel.self, RecurrenceRule.self])
    }
}
