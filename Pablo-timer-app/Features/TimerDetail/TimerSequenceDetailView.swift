import SwiftUI
import SwiftData

/// A view for editing a timer sequence's details and managing its timers
struct TimerSequenceDetailView: View {
    /// The timer sequence to display and edit
    @Bindable var sequence: TimerSequenceModel
    
    /// The model context for saving changes
    let modelContext: ModelContext
    
    /// Editing state for the sequence name
    @State private var editingName: String
    
    /// Whether the sequence should repeat
    @State private var repeatSequence: Bool
    
    /// Whether to show the new timer sheet
    @State private var isAddTimerPresented = false
    
    /// Whether the sequence is currently being played
    @State private var isPlaying: Bool = false
    
    /// The timer sequence to be deleted
    @State private var timerToDelete: TimerModel?
    
    /// Whether the delete confirmation dialog is presented
    @State private var isShowingDeleteConfirmation = false
    
    /// Whether the edit mode is active
    @State private var isEditMode: EditMode = .inactive
    
    /// Whether the name is currently being edited
    @State private var isEditingName = false
    
    /// Focus state for the name text field
    @FocusState private var nameFieldFocus: Bool
    
    /// List of actions available in the menu
    @State private var menuActions: [TimerAction] = [.play, .add, .repeat]
    
    /// Custom actions for timer sequences
    enum TimerAction: Identifiable {
        case play, add, delete, duplicate, rename, `repeat`
        
        var id: Self { self }
        
        var icon: String {
            switch self {
            case .play: return "play.fill"
            case .add: return "plus.circle"
            case .delete: return "trash"
            case .duplicate: return "doc.on.doc"
            case .rename: return "pencil"
            case .repeat: return "repeat"
            }
        }
        
        var title: String {
            switch self {
            case .play: return "Play Sequence"
            case .add: return "Add Timer"
            case .delete: return "Delete Sequence"
            case .duplicate: return "Duplicate Sequence"
            case .rename: return "Rename Sequence"
            case .repeat: return "Repeat Sequence"
            }
        }
        
        var color: Color {
            switch self {
            case .delete: return .red
            default: return AppTheme.Colors.accentSecondary
            }
        }
    }
    
    /// Initializes the view with a timer sequence and model context
    /// - Parameters:
    ///   - sequence: The timer sequence to display and edit
    ///   - modelContext: The SwiftData model context
    init(sequence: TimerSequenceModel, modelContext: ModelContext) {
        self.sequence = sequence
        self.modelContext = modelContext
        self._editingName = State(initialValue: sequence.name)
        self._repeatSequence = State(initialValue: sequence.repeatSequence)
    }
    
    var body: some View {
        ZStack {
            // Background color
            AppTheme.Colors.background
                .ignoresSafeArea()
                .onTapGesture {
                    if isEditingName {
                        saveNameChange()
                    }
                }
            
            VStack(spacing: 0) {
                // Header with sequence name and edit button
                VStack(spacing: 10) {
                    if isEditMode == .inactive && !isEditingName {
                        Text(sequence.name)
                            .font(AppTheme.Typography.title)
                            .foregroundColor(AppTheme.Colors.text)
                            .padding(.top)
                            .onTapGesture {
                                editingName = sequence.name
                                isEditingName = true
                                nameFieldFocus = true
                            }
                    } else {
                        TextField("Sequence Name", text: $editingName, onCommit: {
                            saveNameChange()
                        })
                        .font(AppTheme.Typography.title)
                        .foregroundColor(AppTheme.Colors.text)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.top)
                        .focused($nameFieldFocus)
                        .submitLabel(.done)
                        .onSubmit {
                            saveNameChange()
                        }
                    }
                    
                    // Display total duration
                    Text("Duration: \(sequence.formattedTotalDuration)")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    // Action buttons
                    HStack(spacing: 20) {
                        ForEach(menuActions) { action in
                            Button {
                                handleAction(action)
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: action.icon)
                                        .font(.title3)
                                        .foregroundColor(action.color)
                                        .frame(width: 40, height: 40)
                                        .background(
                                            Circle()
                                                .fill(action.color.opacity(0.1))
                                        )
                                    
                                    Text(action.title)
                                        .font(AppTheme.Typography.caption)
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                }
                .padding(.horizontal)
                .background(AppTheme.Colors.buttonBackground)
                
                // Timer list
                List {
                    Section {
                        ForEach(sequence.timers) { timer in
                            TimerRow(timer: timer, modelContext: modelContext)
                                .contentShape(Rectangle())
                                .contextMenu {
                                    Button {
                                        // Edit timer
                                        editTimer(timer)
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    
                                    Button(role: .destructive) {
                                        // Delete timer
                                        timerToDelete = timer
                                        isShowingDeleteConfirmation = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        timerToDelete = timer
                                        isShowingDeleteConfirmation = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        editTimer(timer)
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(AppTheme.Colors.accentSecondary)
                                }
                        }
                        .onMove { indices, destination in
                            // Handle reordering
                            guard let first = indices.first else { return }
                            sequence.moveTimer(fromIndex: first, toIndex: destination > first ? destination - 1 : destination)
                            save()
                        }
                    } header: {
                        HStack {
                            Text("Timers")
                                .font(AppTheme.Typography.subtitle)
                                .foregroundColor(AppTheme.Colors.text)
                            
                            Spacer()
                            
                            Text("\(sequence.timers.count) timer\(sequence.timers.count == 1 ? "" : "s")")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .environment(\.editMode, $isEditMode)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        isAddTimerPresented = true
                    } label: {
                        Label("Add Timer", systemImage: "plus")
                    }
                    
                    Button {
                        withAnimation {
                            isEditMode = isEditMode == .active ? .inactive : .active
                        }
                    } label: {
                        Label(
                            isEditMode == .active ? "Done Reordering" : "Reorder Timers", 
                            systemImage: isEditMode == .active ? "checkmark" : "arrow.up.arrow.down"
                        )
                    }
                    
                    Button {
                        withAnimation {
                            repeatSequence.toggle()
                            sequence.repeatSequence = repeatSequence
                            save()
                        }
                    } label: {
                        Label(
                            sequence.repeatSequence ? "Disable Repeat" : "Enable Repeat", 
                            systemImage: "repeat"
                        )
                    }
                    
                    Button(role: .destructive) {
                        timerToDelete = nil
                        isShowingDeleteConfirmation = true
                    } label: {
                        Label("Delete Sequence", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(AppTheme.Colors.accentSecondary)
                }
            }
        }
        .sheet(isPresented: $isAddTimerPresented, onDismiss: {
            // When the sheet is dismissed, save the new timer to the sequence
            saveNewTimer()
        }) {
            NavigationStack {
                TimerDetailView(
                    timer: createNewTimer(), 
                    modelContext: modelContext, 
                    isPresentedInSheet: true
                )
                .navigationTitle("New Timer")
                .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.large])
        }
        .confirmationDialog(
            "Delete Timer",
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            if timerToDelete != nil {
                Button("Delete", role: .destructive) {
                    if let timer = timerToDelete {
                        deleteTimer(timer)
                    }
                    timerToDelete = nil
                }
            } else {
                Button("Delete Sequence", role: .destructive) {
                    // The sequence will be deleted in parent view
                    isShowingDeleteConfirmation = false
                }
            }
            
            Button("Cancel", role: .cancel) {
                timerToDelete = nil
            }
        } message: {
            if timerToDelete != nil {
                Text("Are you sure you want to delete this timer? This action cannot be undone.")
            } else {
                Text("Are you sure you want to delete this sequence? This action cannot be undone.")
            }
        }
        .onChange(of: isEditMode) { newValue, oldValue in
            if oldValue == .active && newValue == .inactive {
                if editingName != sequence.name {
                    sequence.name = editingName
                    save()
                }
                isEditingName = false
            }
        }
        .onChange(of: nameFieldFocus) { isFocused in
            // If focus is lost, save the name
            if !isFocused && isEditingName {
                saveNameChange()
            }
        }
    }
    
    /// Creates a new timer
    /// - Returns: A new timer model
    private func createNewTimer() -> TimerModel {
        let timer = TimerModel(title: "", duration: 60)
        // Don't add the timer to the sequence yet - this will be done in saveNewTimer
        return timer
    }
    
    /// Saves the new timer to the sequence
    private func saveNewTimer() {
        // Find the timer that isn't in the sequence yet
        do {
            let descriptor = FetchDescriptor<TimerModel>(predicate: #Predicate { timer in
                timer.sequence == nil
            })
            let newTimers = try modelContext.fetch(descriptor)
            
            // Add new timer to the sequence
            for timer in newTimers {
                sequence.addTimer(timer)
            }
            
            save()
        } catch {
            print("Error fetching new timer: \(error)")
            HapticManager.shared.errorFeedback()
        }
    }
    
    /// Edits an existing timer
    /// - Parameter timer: The timer to edit
    private func editTimer(_ timer: TimerModel) {
        // Since we're using NavigationLink in the TimerRow,
        // we don't need to manually handle navigation here
    }
    
    /// Deletes a timer from the sequence
    /// - Parameter timer: The timer to delete
    private func deleteTimer(_ timer: TimerModel) {
        sequence.removeTimer(timer)
        modelContext.delete(timer)
        save()
    }
    
    /// Handles the action selected from the menu
    /// - Parameter action: The selected action
    private func handleAction(_ action: TimerAction) {
        switch action {
        case .play:
            isPlaying.toggle()
        case .add:
            isAddTimerPresented = true
        case .delete:
            timerToDelete = nil
            isShowingDeleteConfirmation = true
        case .duplicate:
            // Duplicate the sequence
            break
        case .rename:
            withAnimation {
                isEditMode = .active
            }
        case .repeat:
            withAnimation {
                repeatSequence.toggle()
                sequence.repeatSequence = repeatSequence
                save()
            }
        }
    }
    
    /// Saves changes to the model context
    private func save() {
        do {
            try modelContext.save()
            HapticManager.shared.successFeedback()
        } catch {
            HapticManager.shared.errorFeedback()
            print("Error saving changes: \(error)")
        }
    }
    
    /// Saves the name change to the sequence
    private func saveNameChange() {
        if !editingName.isEmpty {
            sequence.name = editingName
            save()
        } else {
            // If name is empty, revert to original name
            editingName = sequence.name
        }
        isEditingName = false
        nameFieldFocus = false
    }
}

/// A row representing a single timer in the sequence
struct TimerRow: View {
    /// The timer to display
    let timer: TimerModel
    
    /// The model context for saving changes
    let modelContext: ModelContext
    
    var body: some View {
        NavigationLink(destination: TimerDetailView(timer: timer, modelContext: modelContext, isPresentedInSheet: false)) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(timer.title)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.text)
                    
                    HStack(spacing: 8) {
                        Label {
                            Text(timer.formattedDuration)
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        } icon: {
                            Image(systemName: "clock")
                                .font(.caption2)
                                .foregroundColor(AppTheme.Colors.accentSecondary)
                        }
                        
                        if timer.isRecurring, let rule = timer.recurrenceRule {
                            Label {
                                let intervalText = rule.interval == 1 ? "" : "\(rule.interval) "
                                Text("Every \(intervalText)\(rule.frequency.description)")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                            } icon: {
                                Image(systemName: "repeat")
                                    .font(.caption2)
                                    .foregroundColor(AppTheme.Colors.accentSecondary)
                            }
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    NavigationStack {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: TimerSequenceModel.self, TimerModel.self, RecurrenceRule.self, configurations: config)
        
        let context = container.mainContext
        let workTimer = TimerModel(title: "Work", duration: 25 * 60)
        let breakTimer = TimerModel(title: "Break", duration: 5 * 60)
        
        let sequence = TimerSequenceModel(
            name: "Pomodoro",
            timers: [workTimer, breakTimer],
            repeatSequence: true
        )
        
        context.insert(sequence)
        
        return TimerSequenceDetailView(sequence: sequence, modelContext: context)
    }
} 