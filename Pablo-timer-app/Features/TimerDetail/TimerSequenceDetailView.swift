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
    @State private var menuActions: [TimerAction] = [.play, .add]
    
    /// Whether to show the schedule sequence sheet
    @State private var isScheduleSequencePresented = false
    
    /// The days of the week for recurrence
    @State private var selectedDays: Set<Int> = []
    
    /// The time of day for the recurring sequence
    @State private var scheduledTime = Date()
    
    /// Custom actions for timer sequences
    enum TimerAction: Identifiable {
        case play, add, delete, duplicate, rename, `repeat`, schedule
        
        var id: Self { self }
        
        var icon: String {
            switch self {
            case .play: return "play.fill"
            case .add: return "plus.circle"
            case .delete: return "trash"
            case .duplicate: return "doc.on.doc"
            case .rename: return "pencil"
            case .repeat: return "repeat"
            case .schedule: return "calendar"
            }
        }
        
        var title: String {
            switch self {
            case .play: return "Start"
            case .add: return "Add Timer"
            case .delete: return "Delete Sequence"
            case .duplicate: return "Duplicate Sequence"
            case .rename: return "Rename Sequence"
            case .repeat: return "Repeat Sequence"
            case .schedule: return "Schedule"
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
        
        // Initialize recurrence state from the recurrence rule if it exists
        if let rule = sequence.recurrenceRule {
            if rule.frequency == .weekly {
                if let weekdays = rule.weekdays {
                    self._selectedDays = State(initialValue: Set(weekdays))
                }
            }
            if let startDate = rule.startDate {
                self._scheduledTime = State(initialValue: startDate)
            }
            self._menuActions = State(initialValue: [.play, .add, .schedule])
        } else {
            self._menuActions = State(initialValue: [.play, .add, .schedule])
        }
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
                    
                    // Display recurrence info if present
                    if let rule = sequence.recurrenceRule, sequence.repeatSequence {
                        HStack {
                            Image(systemName: "calendar")
                                .font(.caption2)
                                .foregroundColor(AppTheme.Colors.accentSecondary)
                            
                            Text(formatRecurrenceInfo(rule))
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }
                    
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
                        isScheduleSequencePresented = true
                    } label: {
                        Label("Schedule", systemImage: "calendar")
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
                    parentSequence: sequence,
                    isPresentedInSheet: true
                )
                .navigationTitle("New Timer")
                .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.large])
        }
        .sheet(isPresented: $isScheduleSequencePresented) {
            NavigationStack {
                Form {
                    Section {
                        Toggle("Schedule Recurring", isOn: $repeatSequence)
                            .onChange(of: repeatSequence) { _, isOn in
                                if !isOn {
                                    // If turned off, remove the recurrence rule
                                    sequence.recurrenceRule = nil
                                    save()
                                }
                            }
                    } header: {
                        Text("Recurrence")
                    }
                    
                    if repeatSequence {
                        Section {
                            DatePicker("Time", selection: $scheduledTime, displayedComponents: .hourAndMinute)
                        } header: {
                            Text("Time of Day")
                        }
                        
                        Section {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Repeat on")
                                    .font(AppTheme.Typography.body)
                                    .foregroundColor(AppTheme.Colors.text)
                                
                                HStack(spacing: 8) {
                                    weekdayButton(0, letter: "S")
                                    weekdayButton(1, letter: "M")
                                    weekdayButton(2, letter: "T")
                                    weekdayButton(3, letter: "W")
                                    weekdayButton(4, letter: "T")
                                    weekdayButton(5, letter: "F")
                                    weekdayButton(6, letter: "S")
                                }
                            }
                            .padding(.vertical, 4)
                        } header: {
                            Text("Days")
                        }
                    }
                }
                .navigationTitle("Schedule Sequence")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            isScheduleSequencePresented = false
                        }
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            saveRecurrenceSettings()
                            isScheduleSequencePresented = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
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
        // The timer should already be associated with the sequence via the parentSequence parameter
        
        // Make sure all timers are actually in the sequence and at the end of the list
        do {
            let descriptor = FetchDescriptor<TimerModel>(predicate: #Predicate { timer in
                timer.sequence == nil
            })
            let newTimers = try modelContext.fetch(descriptor)
            
            // Add any unassociated timers to the sequence
            if !newTimers.isEmpty {
                for timer in newTimers {
                    // First, make sure the timer isn't already in the sequence
                    if !sequence.timers.contains(where: { $0.id == timer.id }) {
                        // Add it to the end of the list
                        sequence.addTimer(timer)
                    }
                }
                save()
                
                // Refresh the UI if needed
                HapticManager.shared.successFeedback()
            }
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
                if !repeatSequence {
                    sequence.recurrenceRule = nil
                }
                save()
            }
        case .schedule:
            isScheduleSequencePresented = true
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
    
    /// Creates a weekday selection button
    private func weekdayButton(_ day: Int, letter: String) -> some View {
        let isSelected = selectedDays.contains(day)
        
        return Button {
            if selectedDays.contains(day) {
                selectedDays.remove(day)
            } else {
                selectedDays.insert(day)
            }
        } label: {
            Text(letter)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(isSelected ? AppTheme.Colors.accentSecondary : AppTheme.Colors.buttonBackground)
                )
                .foregroundColor(isSelected ? .white : AppTheme.Colors.text)
        }
    }
    
    /// Saves the recurrence settings
    private func saveRecurrenceSettings() {
        if repeatSequence {
            // Create or update recurrence rule
            let rule: RecurrenceRule
            
            if let existingRule = sequence.recurrenceRule {
                rule = existingRule
            } else {
                rule = RecurrenceRule(frequency: .weekly)
                sequence.recurrenceRule = rule
            }
            
            // Update the rule properties
            rule.frequency = .weekly
            rule.interval = 1
            
            // Set the weekdays
            rule.weekdays = Array(selectedDays)
            
            // Set the time component
            let calendar = Calendar.current
            var components = calendar.dateComponents([.hour, .minute], from: scheduledTime)
            
            // If no day is selected, default to today
            if selectedDays.isEmpty {
                let today = calendar.component(.weekday, from: Date()) - 1 // Convert 1-7 to 0-6
                selectedDays = [today]
                rule.weekdays = [today]
            }
            
            // Create a start date with today's date but the selected time
            let now = Date()
            components.year = calendar.component(.year, from: now)
            components.month = calendar.component(.month, from: now)
            components.day = calendar.component(.day, from: now)
            
            if let date = calendar.date(from: components) {
                rule.startDate = date
            }
            
            sequence.repeatSequence = true
        } else {
            sequence.recurrenceRule = nil
            sequence.repeatSequence = false
        }
        
        save()
    }
    
    /// Formats the recurrence information into a readable string
    private func formatRecurrenceInfo(_ rule: RecurrenceRule) -> String {
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.dateFormat = "EEE"
        
        var timeString = ""
        if let startDate = rule.startDate {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            timeString = timeFormatter.string(from: startDate)
        }
        
        if rule.frequency == .weekly, let weekdays = rule.weekdays, !weekdays.isEmpty {
            let calendar = Calendar.current
            var weekdayStrings: [String] = []
            
            for weekday in weekdays.sorted() {
                // Convert from our 0-6 format to Calendar's 1-7 format
                let calendarWeekday = weekday + 1
                
                // Create a date with the specified weekday
                var components = DateComponents()
                components.weekday = calendarWeekday
                if let date = calendar.nextDate(after: Date(), matching: components, matchingPolicy: .nextTime) {
                    weekdayStrings.append(weekdayFormatter.string(from: date))
                }
            }
            
            let daysString = weekdayStrings.joined(separator: ", ")
            return "Every \(daysString) at \(timeString)"
        } else {
            return "Repeats at \(timeString)"
        }
    }
}

/// A row representing a single timer in the sequence
struct TimerRow: View {
    /// The timer to display
    let timer: TimerModel
    
    /// The model context for saving changes
    let modelContext: ModelContext
    
    var body: some View {
        NavigationLink(destination: TimerDetailView(
            timer: timer, 
            modelContext: modelContext, 
            parentSequence: timer.sequence,
            isPresentedInSheet: false
        )) {
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
        
        // Add a recurrence rule
        let recurrenceRule = RecurrenceRule(
            frequency: .weekly,
            interval: 1,
            startDate: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()),
            weekdays: [1, 3, 5] // Monday, Wednesday, Friday
        )
        
        sequence.recurrenceRule = recurrenceRule
        
        context.insert(sequence)
        
        return TimerSequenceDetailView(sequence: sequence, modelContext: context)
    }
} 