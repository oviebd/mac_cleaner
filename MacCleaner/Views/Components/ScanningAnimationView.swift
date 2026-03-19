import SwiftUI

struct ScanningAnimationView: View {
    @State private var isAnimating = false
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [.blue.opacity(0.0), .blue.opacity(0.4), .purple.opacity(0.4), .purple.opacity(0.0)],
                            center: .center
                        ),
                        lineWidth: 3
                    )
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .opacity(isAnimating ? 0.0 : 0.8)
                    .animation(
                        .easeOut(duration: 2.0)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.6),
                        value: isAnimating
                    )
            }

            Circle()
                .fill(
                    AngularGradient(
                        colors: [.blue, .purple, .blue],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    )
                )
                .frame(width: 8, height: 8)
                .offset(y: -12)
                .rotationEffect(.degrees(rotation))

            Image(systemName: "magnifyingglass")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .onAppear {
            isAnimating = true
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}
