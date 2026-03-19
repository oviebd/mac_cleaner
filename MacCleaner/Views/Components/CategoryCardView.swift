import SwiftUI

struct CategoryCardView: View {
    let category: CleanupCategory
    let onToggle: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(category.color.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: category.systemImage)
                        .font(.system(size: 20))
                        .foregroundStyle(category.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(category.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    Text(category.description)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    if category.isScanned {
                        HStack(spacing: 8) {
                            Text(category.formattedSize)
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundStyle(category.totalSize > 0 ? category.color : .secondary)
                            if category.fileCount > 0 {
                                Text("\(category.fileCount) files")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        ProgressView()
                            .controlSize(.mini)
                    }
                }

                Spacer()

                Image(systemName: category.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(category.isSelected ? category.color : Color.secondary.opacity(0.3))
                    .animation(.spring(duration: 0.3), value: category.isSelected)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(category.isSelected ? category.color.opacity(0.06) : Color(.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        category.isSelected ? category.color.opacity(0.3) : Color.gray.opacity(isHovering ? 0.2 : 0.1),
                        lineWidth: category.isSelected ? 1.5 : 1
                    )
            )
            .scaleEffect(isHovering ? 1.01 : 1.0)
            .animation(.easeOut(duration: 0.15), value: isHovering)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
