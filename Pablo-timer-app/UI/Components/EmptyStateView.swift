import SwiftUI

/// A view that displays when there are no timer sequences
struct EmptyStateView: View {
    /// Action to perform when the create button is tapped
    var onCreateTapped: () -> Void
    
    var body: some View {
        VStack(spacing: AppTheme.Layout.paddingLarge) {
            // Empty state illustration
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.accent.opacity(0.2))
                    .frame(width: 200, height: 200)
                
                Image(systemName: "timer")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .foregroundColor(AppTheme.Colors.accentSecondary)
            }
            
            // Empty state message
            VStack(spacing: AppTheme.Layout.paddingSmall) {
                Text("No Timer Sequences Yet")
                    .font(AppTheme.Typography.title)
                    .foregroundColor(AppTheme.Colors.text)
                
                Text("Create your first timer sequence to get started")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Layout.paddingLarge)
            }
            
            // Create button
            Button(action: onCreateTapped) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Timer Sequence")
                }
                .font(AppTheme.Typography.body.weight(.medium))
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: 280)
                .background(AppTheme.Colors.accentSecondary)
                .cornerRadius(AppTheme.Layout.buttonCornerRadius)
            }
            .padding(.top, AppTheme.Layout.padding)
        }
        .padding()
    }
}

#Preview {
    EmptyStateView(onCreateTapped: {})
} 