import SwiftUI

struct StorageBarView: View {
    let used: Int64
    let total: Int64
    var animate: Bool = true

    @State private var animatedProgress: CGFloat = 0

    private var progress: CGFloat {
        guard total > 0 else { return 0 }
        return CGFloat(used) / CGFloat(total)
    }

    private var barColor: Color {
        if progress > 0.9 { return .red }
        if progress > 0.75 { return .orange }
        return .blue
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.15))

                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [barColor, barColor.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * animatedProgress)
            }
        }
        .onAppear {
            if animate {
                withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                    animatedProgress = progress
                }
            } else {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedProgress = newValue
            }
        }
    }
}
