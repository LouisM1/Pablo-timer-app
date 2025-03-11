import SwiftUI

/// A card component that displays a timer sequence
struct TimerSequenceCard: View {
    /// The timer sequence to display
    let sequence: TimerSequenceModel
    
    /// Action to perform when the card is tapped
    var onTap: () -> Void
    
    var body: some View {
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
            .background(AppTheme.Colors.buttonBackground)
            .cornerRadius(AppTheme.Layout.cornerRadius)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadius)
                    .stroke(AppTheme.Colors.buttonBorder, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
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
            onTap: {}
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
            onTap: {}
        )
        .padding()
    }
    .background(Color.gray.opacity(0.1))
} 