import SwiftUI

// Import the HapticManager utility
import Foundation

/// A card component that displays a timer sequence
struct TimerSequenceCard: View {
    /// The timer sequence to display
    let sequence: TimerSequenceModel
    
    /// Action to perform when the card is tapped
    var onTap: () -> Void
    
    /// Action to perform when the delete button is tapped
    var onDelete: (() -> Void)?
    
    /// Offset for the swipe gesture
    @State private var offset: CGFloat = 0
    
    /// Whether haptic feedback has been triggered for the current swipe
    @State private var hasTriggeredHaptic = false
    
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
                    // Title and duration
                    HStack {
                        Text(sequence.name)
                            .font(AppTheme.Typography.subtitle)
                            .foregroundColor(AppTheme.Colors.text)
                        
                        Spacer()
                        
                        Text(sequence.formattedTotalDuration)
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    // Timer count
                    Text("\(sequence.timers.count) timer\(sequence.timers.count == 1 ? "" : "s")")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    // Timer preview
                    if !sequence.timers.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AppTheme.Layout.paddingSmall) {
                                ForEach(sequence.timers) { timer in
                                    TimerChip(timer: timer)
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
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadius)
                        .stroke(AppTheme.Colors.buttonBorder, lineWidth: 1)
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
            }
            .buttonStyle(PlainButtonStyle())
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        // Only allow left swipe (negative values)
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
                    .onEnded { gesture in
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
            )
            // Add a tap gesture to reset the card position when tapped outside the delete button
            .contentShape(Rectangle())
            .onTapGesture {
                if offset < 0 {
                    withAnimation(.spring()) {
                        offset = 0
                    }
                }
            }
        }
    }
}

/// A small chip that represents a timer in a sequence
struct TimerChip: View {
    /// The timer to display
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
        .cornerRadius(AppTheme.Layout.buttonCornerRadius)
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
            onTap: {},
            onDelete: {}
        )
        .padding()
    }
    .background(Color.gray.opacity(0.1))
} 