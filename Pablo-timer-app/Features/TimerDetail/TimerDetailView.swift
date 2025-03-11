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
    
    /// Environment value to detect when user is going back
    @Environment(\.presentationMode) private var presentationMode
    
    /// State for the timer title
    @State private var title: String
    
    /// State for the timer duration in minutes
    @State private var durationMinutes: Int
    
    /// State for the timer duration in seconds
    @State private var durationSeconds: Int
    
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
    }
    
    var body: some View {
        Group {
            if isPresentedInSheet {
                content
                    .navigationTitle("Edit Timer")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                saveChanges()
                                dismiss()
                            }
                        }
                    }
                    .interactiveDismissDisabled(hasChanges)
            } else {
                content
                    .navigationTitle("Edit Timer")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                saveChanges()
                                dismiss()
                            }
                        }
                    }
                    .interactiveDismissDisabled(hasChanges)
                    .onDisappear {
                        // If we're navigating away, save changes automatically
                        if hasChanges {
                            saveChanges()
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
        TimerModel(
            title: title,
            duration: durationMinutes * 60 + durationSeconds
        )
    }
    
    /// Save changes to the timer
    private func saveChanges() {
        // Update timer properties
        timer.title = title
        timer.duration = durationMinutes * 60 + durationSeconds
        
        // If a parent sequence is provided and the timer isn't already in a sequence,
        // associate it with the parent sequence at the end of the list
        if let parentSequence = parentSequence {
            // Only add the timer if it's not already in the sequence
            if timer.sequence == nil {
                // This will add the timer to the end of the list
                parentSequence.addTimer(timer)
            } else if timer.sequence?.id != parentSequence.id {
                // If the timer exists but is in a different sequence, move it
                timer.sequence?.removeTimer(timer)
                parentSequence.addTimer(timer)
            }
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
                .font(Font.poppinsMedium(size: 11)) // Using caption2 size (~11pt) with Poppins
                .foregroundColor(AppTheme.Colors.text)
            
            Text(timer.formattedDuration)
                .font(Font.poppinsRegular(size: 11)) // Using caption2 size (~11pt) with Poppins
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(AppTheme.Colors.accent.opacity(0.2))
        .cornerRadius(8) // Use a fixed value instead of AppTheme.Layout.buttonCornerRadius
    }
}

struct TimerDetailPreview: View {
    var body: some View {
        let container = try! ModelContainer(for: TimerModel.self, TimerSequenceModel.self, RecurrenceRule.self)
        let timer = TimerModel(title: "Work", duration: 25 * 60)
        TimerDetailView(timer: timer, modelContext: ModelContext(container), isPresentedInSheet: true)
    }
}

#Preview {
    TimerDetailPreview()
} 