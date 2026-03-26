import SwiftUI

struct UIAnimationConfig {
    static let defaultDuration: Double = 0.3
    static let springResponse: Double = 0.5
    static let springDamping: Double = 0.7
    
    static let quickDuration: Double = 0.15
    static let standardDuration: Double = 0.25
    static let slowDuration: Double = 0.5
}

extension Animation {
    static let woofTalkSpring = Animation.spring(response: UIAnimationConfig.springResponse, dampingFraction: UIAnimationConfig.springDamping)
    static let woofTalkQuick = Animation.easeOut(duration: UIAnimationConfig.quickDuration)
    static let woofTalkStandard = Animation.easeInOut(duration: UIAnimationConfig.standardDuration)
    static let woofTalkSlow = Animation.easeInOut(duration: UIAnimationConfig.slowDuration)
}

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
            y: 0))
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(icon: String, title: String, message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .padding(.top, 8)
            }
        }
        .padding()
    }
}

struct LoadingStateView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct ErrorStateView: View {
    let title: String
    let message: String
    let retryAction: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text(title)
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            if let retryAction = retryAction {
                Button("Retry", action: retryAction)
                    .padding(.top, 8)
            }
        }
        .padding()
    }
}

struct MicroInteraction {
    static func pulse(_ view: some View) -> some View {
        view.modifier(PulseModifier())
    }
    
    static func highlight(_ view: some View) -> some View {
        view.modifier(HighlightModifier())
    }
}

struct PulseModifier: ViewModifier {
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.1 : 1.0)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}

struct HighlightModifier: ViewModifier {
    @State private var isHighlighted = false
    
    func body(content: Content) -> some View {
        content
            .background(isHighlighted ? Color.yellow.opacity(0.3) : Color.clear)
            .onAppear {
                withAnimation(Animation.easeIn(duration: 0.2)) {
                    isHighlighted = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(Animation.easeOut(duration: 0.3)) {
                        isHighlighted = false
                    }
                }
            }
    }
}