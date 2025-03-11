import SwiftUI
import SwiftData

/// A view for displaying and editing the details of a timer
struct TimerDetailView: View {
    /// The timer to display and edit
    @Bindable var timer: TimerModel
    
    /// The model context for saving changes
    let modelContext: ModelContext
    
    /// The parent sequence this timer belongs to (if any)
    var parentSequence: TimerSequenceModel?
    
    /// Whether the view is being presented
    @Environment(\.dismiss) private var dismiss
    
    /// State for the timer title
    @State private var title: String
    
    /// State for the timer duration in minutes
    @State private var durationMinutes: Int
    
    /// State for the timer duration in seconds
    @State private var durationSeconds: Int
    
    /// State for whether the timer is recurring
    @State private var isRecurring: Bool
    
    /// State for the recurrence frequency
    @State private var recurrenceFrequency: RecurrenceFrequency
    
    /// State for the recurrence interval
    @State private var recurrenceInterval: Int
    
    /// Whether changes have been made
    @State private var hasChanges: Bool = false
    
    /// Whether to show the discard changes alert
    @State private var showingDiscardAlert = false
    
    /// Whether this view is presented in a sheet (don't include NavigationStack)
    var isPresentedInSheet: Bool = false
    
    /// Initialize the view with a timer and model context
    /// - Parameters:
    ///   - timer: The timer to display and edit
    ///   - modelContext: The SwiftData model context
    ///   - parentSequence: The parent sequence this timer belongs to
    ///   - isPresentedInSheet: Whether this view is presented in a sheet
    init(timer: TimerModel, modelContext: ModelContext, parentSequence: TimerSequenceModel? = nil, isPresentedInSheet: Bool = false) {
        self.timer = timer
        self.modelContext = modelContext
        self.parentSequence = parentSequence
        self.isPresentedInSheet = isPresentedInSheet
        
        // Initialize state variables with timer values
        self._title = State(initialValue: timer.title)
        self._durationMinutes = State(initialValue: timer.duration / 60)
        self._durationSeconds = State(initialValue: timer.duration % 60)
        self._isRecurring = State(initialValue: timer.isRecurring)
        
        // Initialize recurrence properties
        if let rule = timer.recurrenceRule {
            self._recurrenceFrequency = State(initialValue: rule.frequency)
            self._recurrenceInterval = State(initialValue: rule.interval)
        } else {
            self._recurrenceFrequency = State(initialValue: .daily)
            self._recurrenceInterval = State(initialValue: 1)
        }
    }
    
    var body: some View {
        Group {
            if isPresentedInSheet {
                content
                    .navigationTitle("Edit Timer")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                if hasChanges {
                                    showingDiscardAlert = true
                                } else {
                                    dismiss()
                                }
                            }
                        }
                        
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                saveChanges()
                                dismiss()
                            }
                        }
                    }
            } else {
                NavigationStack {
                    content
                        .navigationTitle("Edit Timer")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") {
                                    if hasChanges {
                                        showingDiscardAlert = true
                                    } else {
                                        dismiss()
                                    }
                                }
                            }
                            
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Save") {
                                    saveChanges()
                                    dismiss()
                                }
                            }
                        }
                }
            }
        }
        .alert("Discard Changes?", isPresented: $showingDiscardAlert) {
            Button("Discard", role: .destructive) {
                dismiss()
            }
            Button("Keep Editing", role: .cancel) {
                showingDiscardAlert = false
            }
        } message: {
            Text("You have unsaved changes. Are you sure you want to discard them?")
        }
    }
    
    /// The main content of the view
    private var content: some View {
        Form {
            // Basic timer information
            Section {
                TextField("Title", text: $title)
                    .onChange(of: title) { _, _ in hasChanges = true }
                
                HStack {
                    Text("Duration")
                    Spacer()
                    
                    // Minutes picker
                    Picker("Minutes", selection: $durationMinutes) {
                        ForEach(0..<60) { minute in
                            Text("\(minute)").tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 60)
                    .clipped()
                    .onChange(of: durationMinutes) { _, _ in hasChanges = true }
                    
                    Text("min")
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    // Seconds picker
                    Picker("Seconds", selection: $durationSeconds) {
                        ForEach(0..<60) { second in
                            Text("\(second)").tag(second)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 60)
                    .clipped()
                    .onChange(of: durationSeconds) { _, _ in hasChanges = true }
                    
                    Text("sec")
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .padding(.vertical, 8)
            } header: {
                Text("Timer Details")
            }
            
            // Recurrence settings
            Section {
                Toggle("Recurring Timer", isOn: $isRecurring)
                    .onChange(of: isRecurring) { _, _ in hasChanges = true }
                
                if isRecurring {
                    HStack {
                        Text("Repeat every")
                        
                        Picker("Interval", selection: $recurrenceInterval) {
                            ForEach(1..<31) { interval in
                                Text("\(interval)").tag(interval)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 60)
                        .clipped()
                        .onChange(of: recurrenceInterval) { _, _ in hasChanges = true }
                        
                        Picker("Frequency", selection: $recurrenceFrequency) {
                            ForEach(RecurrenceFrequency.allCases, id: \.self) { frequency in
                                Text(frequency.description).tag(frequency)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: recurrenceFrequency) { _, _ in hasChanges = true }
                    }
                }
            } header: {
                Text("Recurrence")
            }
            
            // Preview section
            Section {
                VStack(alignment: .center, spacing: 8) {
                    Text("Preview")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    // Use a local preview component instead of TimerChip
                    TimerPreviewChip(timer: previewTimer)
                        .scaleEffect(1.5)
                        .padding(.vertical, 8)
                }
                .frame(maxWidth: .infinity)
            }
            .listRowBackground(Color.clear)
        }
    }
    
    /// A preview timer with the current values
    private var previewTimer: TimerModel {
        let previewTimer = TimerModel(
            title: title,
            duration: durationMinutes * 60 + durationSeconds,
            isRecurring: isRecurring
        )
        
        if isRecurring {
            previewTimer.recurrenceRule = RecurrenceRule(
                frequency: recurrenceFrequency,
                interval: recurrenceInterval
            )
        }
        
        return previewTimer
    }
    
    /// Save changes to the timer
    private func saveChanges() {
        // Update timer properties
        timer.title = title
        timer.duration = durationMinutes * 60 + durationSeconds
        timer.isRecurring = isRecurring
        
        // Update or create recurrence rule
        if isRecurring {
            if let rule = timer.recurrenceRule {
                rule.frequency = recurrenceFrequency
                rule.interval = recurrenceInterval
            } else {
                timer.recurrenceRule = RecurrenceRule(
                    frequency: recurrenceFrequency,
                    interval: recurrenceInterval
                )
            }
        } else {
            timer.recurrenceRule = nil
        }
        
        // If a parent sequence is provided and the timer isn't already in a sequence,
        // associate it with the parent sequence
        if let parentSequence = parentSequence, timer.sequence == nil {
            parentSequence.addTimer(timer)
        }
        
        // Save changes to the database
        try? modelContext.save()
    }
}

/// A simple preview chip for the timer
private struct TimerPreviewChip: View {
    let timer: TimerModel
    
    var body: some View {
        VStack(spacing: 2) {
            Text(timer.title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(AppTheme.Colors.text)
            
            Text(timer.formattedDuration)
                .font(.caption2)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(AppTheme.Colors.accent.opacity(0.2))
        .cornerRadius(8) // Use a fixed value instead of AppTheme.Layout.buttonCornerRadius
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TimerModel.self, RecurrenceRule.self, configurations: config)
    
    let context = container.mainContext
    let timer = TimerModel(title: "Work", duration: 25 * 60, isRecurring: true)
    timer.recurrenceRule = RecurrenceRule(frequency: .daily, interval: 1)
    
    context.insert(timer)
    
    return TimerDetailView(timer: timer, modelContext: context)
} 