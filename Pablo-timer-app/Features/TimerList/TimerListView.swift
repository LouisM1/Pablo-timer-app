import SwiftUI
import SwiftData

/// The main view that displays a list of timer sequences
struct TimerListView: View {
    /// The view model for the timer list
    @State private var viewModel: TimerListViewModel
    
    /// Whether the create timer sheet is presented
    @State private var isCreateTimerPresented = false
    
    /// The name for a new timer sequence
    @State private var newSequenceName = ""
    
    /// The timer sequence to be deleted
    @State private var timerToDelete: TimerSequenceModel?
    
    /// Whether the delete confirmation dialog is presented
    @State private var isShowingDeleteConfirmation = false
    
    /// Initializes the view with a model context
    /// - Parameter modelContext: The SwiftData model context
    init(modelContext: ModelContext) {
        // Since TimerListViewModel is @MainActor, this is safe because
        // SwiftUI views are always created on the main thread
        self._viewModel = State(initialValue: TimerListViewModel(modelContext: modelContext))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background color
                AppTheme.Colors.background
                    .ignoresSafeArea()
                
                // Content
                VStack {
                    // Header with app title and create button
                    HStack {
                        Text("Timer Sequences")
                            .font(AppTheme.Typography.title)
                            .foregroundColor(AppTheme.Colors.text)
                        
                        Spacer()
                        
                        Button(action: {
                            isCreateTimerPresented = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(AppTheme.Colors.accentSecondary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Timer sequence list or empty state
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.5)
                            .padding()
                    } else if viewModel.timerSequences.isEmpty {
                        EmptyStateView(onCreateTapped: {
                            isCreateTimerPresented = true
                        })
                        .padding(.top, 50)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: AppTheme.Layout.padding) {
                                ForEach(viewModel.timerSequences) { sequence in
                                    TimerSequenceCard(
                                        sequence: sequence,
                                        onTap: {
                                            // Navigate to timer detail/start view
                                            print("Tapped on sequence: \(sequence.name)")
                                        },
                                        onDelete: {
                                            // Show confirmation dialog
                                            timerToDelete = sequence
                                            isShowingDeleteConfirmation = true
                                        }
                                    )
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            timerToDelete = sequence
                                            isShowingDeleteConfirmation = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .sheet(isPresented: $isCreateTimerPresented) {
                createTimerSheet
            }
            .refreshable {
                viewModel.fetchTimerSequences()
            }
            .onAppear {
                // If there are no timer sequences, create a sample one for demo purposes
                if viewModel.timerSequences.isEmpty {
                    viewModel.createSampleTimerSequence()
                }
            }
            .confirmationDialog(
                "Delete Timer",
                isPresented: $isShowingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let sequence = timerToDelete {
                        viewModel.deleteTimerSequence(sequence)
                    }
                    timerToDelete = nil
                }
                
                Button("Cancel", role: .cancel) {
                    timerToDelete = nil
                }
            } message: {
                Text("Are you sure you want to delete this timer sequence? This action cannot be undone.")
            }
        }
    }
    
    /// Sheet for creating a new timer sequence
    private var createTimerSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Sequence Name", text: $newSequenceName)
                        .font(AppTheme.Typography.body)
                } header: {
                    Text("New Timer Sequence")
                        .font(AppTheme.Typography.caption)
                }
                
                Section {
                    Button("Create") {
                        if !newSequenceName.isEmpty {
                            viewModel.createTimerSequence(name: newSequenceName)
                            newSequenceName = ""
                            isCreateTimerPresented = false
                        }
                    }
                    .font(AppTheme.Typography.body.weight(.medium))
                    .foregroundColor(AppTheme.Colors.accentSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .disabled(newSequenceName.isEmpty)
                }
            }
            .navigationTitle("Create Timer Sequence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isCreateTimerPresented = false
                        newSequenceName = ""
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TimerSequenceModel.self, TimerModel.self, RecurrenceRule.self, configurations: config)
    
    // Create a sample timer sequence for the preview
    let context = container.mainContext
    let workTimer = TimerModel(title: "Work", duration: 25 * 60)
    let breakTimer = TimerModel(title: "Break", duration: 5 * 60)
    
    let sequence = TimerSequenceModel(
        name: "Pomodoro",
        timers: [workTimer, breakTimer],
        repeatSequence: true
    )
    
    context.insert(sequence)
    
    return TimerListView(modelContext: context)
} 