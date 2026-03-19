import SwiftUI

struct DeleteConfirmationView: View {
    let title: String
    let message: String
    let size: Int64
    let onConfirm: () -> Void
    let onCancel: () -> Void

    @State private var confirmText = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.yellow)

            Text(title)
                .font(.title2)
                .fontWeight(.bold)

            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            sizeDisplay

            HStack(spacing: 16) {
                Button("Cancel") {
                    onCancel()
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button {
                    onConfirm()
                    dismiss()
                } label: {
                    Label("Clean Now", systemImage: "trash.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(32)
        .frame(width: 420)
    }

    private var sizeDisplay: some View {
        VStack(spacing: 4) {
            Text("Space to free up")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(FileSizeFormatter.format(size))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 24)
        .background(.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}
