import SwiftUI

struct SunburstChartView: View {
    let node: DiskUsageNode
    var onSelect: (DiskUsageNode) -> Void = { _ in }
    var onHover: (DiskUsageNode?) -> Void = { _ in }

    @State private var hoveredSegmentID: UUID?
    @State private var appeared = false

    private let maxRings = 4
    private let centerRadius: CGFloat = 60
    private let ringWidth: CGFloat = 50

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let maxRadius = size / 2

            Canvas { context, _ in
                drawNode(
                    context: &context,
                    node: node,
                    center: center,
                    startAngle: .zero,
                    endAngle: .degrees(360),
                    depth: 0,
                    maxRadius: maxRadius
                )
            }
            .overlay {
                sunburstInteractionLayer(center: center, maxRadius: maxRadius)
            }
            .overlay {
                centerLabel
                    .position(center)
            }
            .scaleEffect(appeared ? 1.0 : 0.5)
            .opacity(appeared ? 1.0 : 0)
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.3)) {
                appeared = true
            }
        }
    }

    // MARK: - Center Label

    private var centerLabel: some View {
        VStack(spacing: 2) {
            Text(node.name)
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(1)
            Text(node.formattedSize)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.blue)
        }
        .frame(width: centerRadius * 1.5)
    }

    // MARK: - Drawing

    private func drawNode(
        context: inout GraphicsContext,
        node: DiskUsageNode,
        center: CGPoint,
        startAngle: Angle,
        endAngle: Angle,
        depth: Int,
        maxRadius: CGFloat
    ) {
        guard depth < maxRings, node.size > 0 else { return }

        let innerR = centerRadius + CGFloat(depth) * ringWidth
        let outerR = min(centerRadius + CGFloat(depth + 1) * ringWidth, maxRadius)
        guard outerR > innerR else { return }

        let children = node.sortedChildren.filter { $0.size > 0 }
        guard !children.isEmpty else { return }

        let totalSize = Double(node.size)
        let angleSpan = endAngle - startAngle
        var currentAngle = startAngle

        // Only show children that take at least 1 degree
        let minAngle = Angle.degrees(1)

        for child in children {
            let childAngleSpan = angleSpan * (Double(child.size) / totalSize)
            guard childAngleSpan > minAngle else { continue }

            let childEndAngle = currentAngle + childAngleSpan
            let isHovered = hoveredSegmentID == child.id

            let path = arcPath(
                center: center,
                innerRadius: innerR + 1,
                outerRadius: outerR - 1,
                startAngle: currentAngle + .degrees(0.5),
                endAngle: childEndAngle - .degrees(0.5)
            )

            let baseColor = child.color
            let color = isHovered ? baseColor.opacity(1.0) : baseColor.opacity(0.7 - Double(depth) * 0.1)

            context.fill(path, with: .color(color))

            if isHovered {
                context.stroke(path, with: .color(.white), lineWidth: 2)
            }

            // Recurse into children
            if child.isDirectory && !child.children.isEmpty {
                drawNode(
                    context: &context,
                    node: child,
                    center: center,
                    startAngle: currentAngle,
                    endAngle: childEndAngle,
                    depth: depth + 1,
                    maxRadius: maxRadius
                )
            }

            currentAngle = childEndAngle
        }
    }

    private func arcPath(center: CGPoint, innerRadius: CGFloat, outerRadius: CGFloat, startAngle: Angle, endAngle: Angle) -> Path {
        var path = Path()
        path.addArc(center: center, radius: outerRadius, startAngle: startAngle - .degrees(90), endAngle: endAngle - .degrees(90), clockwise: false)
        path.addArc(center: center, radius: innerRadius, startAngle: endAngle - .degrees(90), endAngle: startAngle - .degrees(90), clockwise: true)
        path.closeSubpath()
        return path
    }

    // MARK: - Interaction Layer

    private func sunburstInteractionLayer(center: CGPoint, maxRadius: CGFloat) -> some View {
        GeometryReader { geometry in
            Color.clear
                .contentShape(Rectangle())
                .onContinuousHover { phase in
                    switch phase {
                    case .active(let location):
                        if let found = hitTest(
                            point: location,
                            center: center,
                            node: node,
                            startAngle: .zero,
                            endAngle: .degrees(360),
                            depth: 0,
                            maxRadius: maxRadius
                        ) {
                            if hoveredSegmentID != found.id {
                                hoveredSegmentID = found.id
                                onHover(found)
                            }
                        } else {
                            hoveredSegmentID = nil
                            onHover(nil)
                        }
                    case .ended:
                        hoveredSegmentID = nil
                        onHover(nil)
                    }
                }
                .onTapGesture { location in
                    if let found = hitTest(
                        point: location,
                        center: center,
                        node: node,
                        startAngle: .zero,
                        endAngle: .degrees(360),
                        depth: 0,
                        maxRadius: maxRadius
                    ), found.isDirectory {
                        onSelect(found)
                    }
                }
        }
    }

    private func hitTest(
        point: CGPoint,
        center: CGPoint,
        node: DiskUsageNode,
        startAngle: Angle,
        endAngle: Angle,
        depth: Int,
        maxRadius: CGFloat
    ) -> DiskUsageNode? {
        guard depth < maxRings, node.size > 0 else { return nil }

        let innerR = centerRadius + CGFloat(depth) * ringWidth
        let outerR = min(centerRadius + CGFloat(depth + 1) * ringWidth, maxRadius)

        let dx = point.x - center.x
        let dy = point.y - center.y
        let distance = sqrt(dx * dx + dy * dy)
        var angle = Angle(radians: atan2(Double(dy), Double(dx))) + .degrees(90)
        if angle.degrees < 0 { angle = angle + .degrees(360) }

        let children = node.sortedChildren.filter { $0.size > 0 }
        let totalSize = Double(node.size)
        let angleSpan = endAngle - startAngle
        var currentAngle = startAngle

        for child in children {
            let childAngleSpan = angleSpan * (Double(child.size) / totalSize)
            guard childAngleSpan.degrees > 1 else { continue }
            let childEndAngle = currentAngle + childAngleSpan

            // Check deeper levels first
            if child.isDirectory && !child.children.isEmpty {
                if let deeper = hitTest(
                    point: point,
                    center: center,
                    node: child,
                    startAngle: currentAngle,
                    endAngle: childEndAngle,
                    depth: depth + 1,
                    maxRadius: maxRadius
                ) {
                    return deeper
                }
            }

            // Check this level
            if distance >= innerR && distance <= outerR {
                if angle >= currentAngle && angle <= childEndAngle {
                    return child
                }
            }

            currentAngle = childEndAngle
        }

        return nil
    }
}
