//
//  FlowLayout.swift
//  MuscleCheck
//
//  Wrapping HStack: lays children left-to-right, wrapping to a new line when the
//  row runs out of width. Used for the add picker's category chips so every
//  category is visible at once — a horizontal scroll hides options the user can't
//  know exist, which defeats a selector's whole job.
//

import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = arrange(subviews: subviews, maxWidth: maxWidth)
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(0, rows.count - 1))
        return CGSize(width: maxWidth == .infinity ? rows.map(\.width).max() ?? 0 : maxWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let rows = arrange(subviews: subviews, maxWidth: bounds.width)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for item in row.items {
                let size = subviews[item.index].sizeThatFits(.unspecified)
                subviews[item.index].place(
                    at: CGPoint(x: x, y: y + (row.height - size.height) / 2),
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    // MARK: - Row packing

    private struct Row {
        var items: [(index: Int, width: CGFloat)] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = []
        var current = Row()

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needed = current.items.isEmpty ? size.width : current.width + spacing + size.width
            if needed > maxWidth && !current.items.isEmpty {
                rows.append(current)
                current = Row()
            }
            current.width = current.items.isEmpty ? size.width : current.width + spacing + size.width
            current.height = max(current.height, size.height)
            current.items.append((index: index, width: size.width))
        }
        if !current.items.isEmpty { rows.append(current) }
        return rows
    }
}
