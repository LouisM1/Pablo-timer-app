//
//  ContentView.swift
//  Pablo-timer-app
//
//  Created by Louis McAuliffe on 11/03/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    /// The SwiftData model context
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        TimerListView(modelContext: modelContext)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [TimerSequenceModel.self, TimerModel.self, RecurrenceRule.self], inMemory: true)
}
