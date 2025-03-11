import SwiftUI
import Foundation
import SwiftData
import UIKit

/// A card component that displays a timer sequence
struct TimerSequenceCard: View {
    /// The timer sequence to display
    let sequence: TimerSequenceModel
    
    /// The model context for saving changes
    let modelContext: ModelContext
    
    /// Action to perform when the card is tapped
    var onTap: () -> Void
    
    /// Action to perform when the delete button is tapped
    var onDelete: (() -> Void)?
    
    /// Action to perform when the play button is tapped
    var onPlay: (() -> Void)?
    
    /// Whether the sequence is currently running
    var isRunning: Bool = false
    
    /// Current progress of the sequence (0.0 to 1.0)
    var progress: Double = 0.0
    
    /// Offset for the swipe gesture
    @State private var offset: CGFloat = 0
    
    /// Whether haptic feedback has been triggered for the current swipe
    @State private var hasTriggeredHaptic = false
    
    /// Whether the card is being dragged for reordering
    @State private var isDragging = false
    
    /// Access to the edit mode state
    @Environment(\.editMode) private var editMode
    
    /// Threshold for triggering delete action
    private let deleteThreshold: CGFloat = -200
    
    /// Threshold for showing delete button
    private let deleteButtonThreshold: CGFloat = -80
    
    /// Threshold for triggering haptic feedback
    private let hapticThreshold: CGFloat = -40
    
    /// Background color based on swipe distance
    private var backgroundColor: Color {
        // Change background color to red when swiped far enough to delete
        let percentage = min(1.0, abs(offset) / abs(deleteThreshold))
        if percentage > 0.7 {
            return Color.red.opacity(percentage * 0.3)
        }
        return Color.clear
    }
    
    /// Whether the view is in edit mode
    private var isInEditMode: Bool {
        return editMode?.wrappedValue.isEditing ?? false
    }
    
    var body: some View {
        ZStack {
            // Delete background - this stays fixed
            HStack {
                Spacer()
                
                // Delete button
                VStack {
                    Button(action: {
                        withAnimation(.spring()) {
                            HapticManager.shared.mediumImpactFeedback()
                            onDelete?()
                        }
                    }) {
                        Image(systemName: "trash")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                    }
                    .frame(width: 80)
                    .frame(maxHeight: .infinity)
                    .background(Color.red)
                    .cornerRadius(AppTheme.Layout.cornerRadius, corners: [.topRight, .bottomRight])
                }
            }
            
            // Card content - this moves with the swipe
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: AppTheme.Layout.paddingSmall) {
                    // Title row with play button and total time
                    HStack {
                        if isInEditMode {
                            Image(systemName: "line.3.horizontal")
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .padding(.trailing, 4)
                        }
                        
                        Text(sequence.name)
                            .font(AppTheme.Typography.subtitle)
                            .foregroundColor(AppTheme.Colors.text)
                        
                        Spacer()
                        
                        // Only show play button when not in edit mode
                        if !isInEditMode {
                            Button(action: {
                                HapticManager.shared.mediumImpactFeedback()
                                onPlay?()
                            }) {
                                Image(systemName: isRunning ? "pause.fill" : "play.fill")
                                    .font(.title3)
                                    .foregroundColor(AppTheme.Colors.accentSecondary)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Circle()
                                            .fill(AppTheme.Colors.accentSecondary.opacity(0.1))
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.trailing, 8)
                        }
                        
                        Text(sequence.formattedTotalDuration)
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    // Timer count and info
                    Text("\(sequence.timers.count) timer\(sequence.timers.count == 1 ? "" : "s")")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    // Progress bar (only visible when sequence is running)
                    if isRunning {
                        ProgressBarView(progress: progress)
                            .frame(height: 8)
                            .padding(.vertical, 4)
                    }
                    
                    // Timer preview
                    if !sequence.timers.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AppTheme.Layout.paddingSmall) {
                                ForEach(sequence.timers) { timer in
                                    TimerChip(timer: timer, modelContext: modelContext)
                                }
                            }
                        }
                    }
                    
                    // Repeat indicator if sequence repeats
                    if sequence.repeatSequence {
                        HStack(spacing: 4) {
                            Image(systemName: "repeat")
                                .font(.caption)
                                .foregroundColor(AppTheme.Colors.accentSecondary)
                            
                            Text("Repeats")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.accentSecondary)
                        }
                    }
                }
                .padding(AppTheme.Layout.padding)
                .frame(maxWidth: .infinity)
                .background(AppTheme.Colors.buttonBackground)
                .cornerRadius(AppTheme.Layout.cornerRadius)
                .shadow(color: isDragging ? Color.black.opacity(0.15) : Color.black.opacity(0.05), 
                        radius: isDragging ? 10 : 5, 
                        x: 0, 
                        y: isDragging ? 5 : 2)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadius)
                        .stroke(isDragging ? AppTheme.Colors.accentSecondary : AppTheme.Colors.buttonBorder, 
                                lineWidth: isDragging ? 2 : 1)
                )
                .background(
                    // Visual indicator for delete action
                    RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadius)
                        .fill(backgroundColor)
                )
                .overlay(
                    // Show delete icon when swiped far enough
                    Group {
                        if offset < deleteThreshold * 0.7 {
                            HStack {
                                Spacer()
                                Image(systemName: "trash")
                                    .font(.title)
                                    .foregroundColor(.red)
                                    .padding(.trailing)
                                    .transition(.opacity)
                            }
                        }
                    }
                )
                .scaleEffect(isDragging ? 1.02 : 1.0)
            }
            .buttonStyle(PlainButtonStyle())
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        // Only allow left swipe (negative values) when not in edit mode
                        if !isInEditMode {
                            let newOffset = min(0, gesture.translation.width)
                            offset = newOffset
                            
                            // Provide haptic feedback when crossing threshold
                            if offset < hapticThreshold && !hasTriggeredHaptic {
                                HapticManager.shared.lightImpactFeedback()
                                hasTriggeredHaptic = true
                            } else if offset > hapticThreshold && hasTriggeredHaptic {
                                hasTriggeredHaptic = false
                            }
                            
                            // Additional haptic feedback when approaching delete threshold
                            if offset < deleteThreshold * 0.7 && offset > deleteThreshold * 0.8 {
                                HapticManager.shared.selectionFeedback()
                            }
                        }
                    }
                    .onEnded { gesture in
                        // Only process swipe gestures when not in edit mode
                        if !isInEditMode {
                            // If swiped past threshold, delete the timer
                            if offset < deleteThreshold {
                                withAnimation(.spring()) {
                                    HapticManager.shared.heavyImpactFeedback()
                                    // Delete immediately when swiped far enough
                                    onDelete?()
                                }
                            } else if offset < deleteButtonThreshold {
                                // Show delete button
                                withAnimation(.spring()) {
                                    offset = deleteButtonThreshold
                                    HapticManager.shared.selectionFeedback()
                                }
                            } else {
                                // Reset position
                                withAnimation(.spring()) {
                                    offset = 0
                                }
                            }
                            
                            // Reset haptic trigger state
                            hasTriggeredHaptic = false
                        }
                    }
            )
            // Add a tap gesture to reset the card position when tapped outside the delete button
            .contentShape(Rectangle())
            .onTapGesture {
                if offset < 0 && !isInEditMode {
                    withAnimation(.spring()) {
                        offset = 0
                    }
                }
            }
        }
        .onAppear {
            // Reset offset when view appears
            offset = 0
        }
        .onChange(of: isInEditMode) { newValue, oldValue in
            // Reset offset when edit mode changes
            if newValue != oldValue {
                withAnimation(.spring()) {
                    offset = 0
                }
            }
        }
        // Add drag state for visual feedback during reordering
        .onDrag {
            // Set dragging state to true
            isDragging = true
            HapticManager.shared.lightImpactFeedback()
            
            // Return a provider with the sequence ID
            return NSItemProvider(object: sequence.id.uuidString as NSString)
        }
    }
}

/// A custom progress bar view
struct ProgressBarView: View {
    /// Progress value (0.0 to 1.0)
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppTheme.Colors.buttonBorder)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                
                // Progress fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppTheme.Colors.accentSecondary)
                    .frame(width: geometry.size.width * CGFloat(progress), height: geometry.size.height)
                    .animation(.linear(duration: 0.2), value: progress)
            }
        }
    }
}

/// A small chip that represents a timer in a sequence
struct TimerChip: View {
    /// The timer to display
    let timer: TimerModel
    
    /// The model context for saving changes
    let modelContext: ModelContext
    
    /// Whether the timer detail sheet is presented
    @State private var isTimerDetailPresented = false
    
    var body: some View {
        Button {
            isTimerDetailPresented = true
        } label: {
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
            .cornerRadius(AppTheme.Layout.buttonCornerRadius)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $isTimerDetailPresented) {
            // Create the TimerDetailView directly
            TimerDetailView(
                timer: timer,
                modelContext: modelContext
            )
        }
    }
}

// Extension to create rounded corners for specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// Custom shape for rounded corners
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    VStack {
        TimerSequenceCard(
            sequence: TimerSequenceModel(
                name: "Morning Routine",
                timers: [
                    TimerModel(title: "Meditation", duration: 10 * 60),
                    TimerModel(title: "Stretching", duration: 5 * 60),
                    TimerModel(title: "Reading", duration: 15 * 60)
                ],
                repeatSequence: true
            ),
            modelContext: ModelContext(ModelContainer.sample),
            onTap: {},
            onDelete: {}
        )
        .padding()
        
        TimerSequenceCard(
            sequence: TimerSequenceModel(
                name: "Workout",
                timers: [
                    TimerModel(title: "Warmup", duration: 5 * 60),
                    TimerModel(title: "Exercise", duration: 30 * 60),
                    TimerModel(title: "Cooldown", duration: 5 * 60)
                ]
            ),
            modelContext: ModelContext(ModelContainer.sample),
            onTap: {},
            onDelete: {}
        )
        .padding()
    }
    .background(Color.gray.opacity(0.1))
}

// Preview for TimerChip
#Preview("TimerChip") {
    let timer = createPreviewTimer()
    
    TimerChip(timer: timer, modelContext: ModelContext(ModelContainer.sample))
        .padding()
}

// Helper function to create a timer for previews
private func createPreviewTimer() -> TimerModel {
    let timer = TimerModel(title: "Work", duration: 1500)
    timer.recurrenceRule = RecurrenceRule(frequency: .daily, interval: 1)
    return timer
}

// Extension to provide a sample ModelContainer for previews
extension ModelContainer {
    static var sample: ModelContainer {
        do {
            let container = try ModelContainer(for: TimerModel.self, RecurrenceRule.self, TimerSequenceModel.self)
            return container
        } catch {
            fatalError("Failed to create sample ModelContainer: \(error)")
        }
    }
} 