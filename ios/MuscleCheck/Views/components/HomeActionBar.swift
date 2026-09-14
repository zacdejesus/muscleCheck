//
//  HomeActionBar.swift
//  MuscleCheck
//
//  The home's bottom actions: the available AI actions side by side and "Agregar ejercicio"
//  full width below. Replaces the floating "+" and the two mismatched AI buttons. Built from
//  the array of AVAILABLE actions, so the four availability cases (both, only Coach, only
//  Scan, neither) are one layout.
//
//  iOS 26+: Liquid Glass. No background band — the list scrolls under the bar (with the
//  system's scroll edge effect) and the glass keeps the labels readable over the rows.
//  iOS 18–25: bordered buttons on an opaque inset, because their translucent fills showed
//  the rows straight through.
//

import SwiftUI

enum HomeAIAction: Identifiable {
    case suggestDay
    case scanRoutine

    var id: Self { self }

    var title: LocalizedStringKey {
        switch self {
        case .suggestDay: return "ai_coach_suggest_day_short"
        case .scanRoutine: return "scan_title"
        }
    }

    var systemImage: String {
        switch self {
        case .suggestDay: return "sparkles"
        case .scanRoutine: return "doc.viewfinder"
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .suggestDay: return "home.suggestDay"
        case .scanRoutine: return "home.scanRoutine"
        }
    }
}

struct HomeActionBar: View {
    /// Only the actions this device can run, in display order. Empty → the AI row is
    /// omitted and "Agregar" doesn't move.
    let aiActions: [HomeAIAction]
    let onAIAction: (HomeAIAction) -> Void
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            if !aiActions.isEmpty {
                // Side by side at equal widths while EVERY label fits its half; stacked full
                // width when one doesn't (longer languages, Dynamic Type XXL). Never truncated.
                ViewThatFits(in: .horizontal) {
                    EqualWidthHStack(spacing: 8) { aiButtons }
                    VStack(spacing: 8) { aiButtons }
                }
            }
            Button(action: onAdd) {
                Label("add_exercise", systemImage: "plus")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .primaryActionStyle()
            .accessibilityIdentifier("home.addFAB")
            .accessibilityLabel(Text("add_sheet_title"))
        }
        .tint(Color.brand)
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .background {
            // Only without glass: an opaque band the same colour as the screen, so the rows
            // don't show through the bordered fills. With glass the bar stays transparent.
            if !Self.usesGlass {
                Color.surface.ignoresSafeArea(edges: .bottom)
            }
        }
    }

    private static var usesGlass: Bool {
        if #available(iOS 26, *) { return true }
        return false
    }

    private var aiButtons: some View {
        ForEach(aiActions) { action in
            Button {
                onAIAction(action)
            } label: {
                // Secondary to "Agregar": a lighter control, so the pair fits side by side.
                Label(action.title, systemImage: action.systemImage)
                    .font(.appSubheadline.weight(.semibold))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, minHeight: 30)
            }
            .secondaryActionStyle()
            .accessibilityIdentifier(action.accessibilityIdentifier)
        }
    }
}

extension View {
    /// Attaches the home's bottom actions: a transparent `safeAreaBar` with Liquid Glass
    /// buttons on iOS 26+ (the list scrolls under it), a plain safe-area inset before.
    func homeActionBar(
        aiActions: [HomeAIAction],
        onAIAction: @escaping (HomeAIAction) -> Void,
        onAdd: @escaping () -> Void
    ) -> some View {
        modifier(HomeActionBarPlacement(bar: HomeActionBar(aiActions: aiActions, onAIAction: onAIAction, onAdd: onAdd)))
    }
}

private struct HomeActionBarPlacement: ViewModifier {
    let bar: HomeActionBar

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.safeAreaBar(edge: .bottom) { bar }
        } else {
            content.safeAreaInset(edge: .bottom) { bar }
        }
    }
}

private extension View {
    @ViewBuilder
    func primaryActionStyle() -> some View {
        if #available(iOS 26, *) {
            buttonStyle(.glassProminent).controlSize(.large)
        } else {
            buttonStyle(.borderedProminent).controlSize(.large)
        }
    }

    @ViewBuilder
    func secondaryActionStyle() -> some View {
        if #available(iOS 26, *) {
            buttonStyle(.glass).controlSize(.regular)
        } else {
            buttonStyle(.bordered).controlSize(.regular)
        }
    }
}

/// Children side by side at EQUAL widths. Its ideal width is "widest child × count", so in a
/// `ViewThatFits` it only wins when every label fits its share. A plain `HStack` reported a
/// fit (the labels fit in total) and then split the width evenly, truncating the longer one.
private struct EqualWidthHStack: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard !subviews.isEmpty else { return .zero }
        let gaps = spacing * CGFloat(subviews.count - 1)
        let widest = subviews.map { $0.sizeThatFits(.unspecified).width }.max() ?? 0
        let needed = widest * CGFloat(subviews.count) + gaps
        // Fill the offered width, but never report less than what the widest label needs.
        let width = max(proposal.width ?? needed, needed)
        let share = (width - gaps) / CGFloat(subviews.count)
        let height = subviews
            .map { $0.sizeThatFits(ProposedViewSize(width: share, height: proposal.height)).height }
            .max() ?? 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard !subviews.isEmpty else { return }
        let gaps = spacing * CGFloat(subviews.count - 1)
        let share = (bounds.width - gaps) / CGFloat(subviews.count)
        var x = bounds.minX
        for subview in subviews {
            subview.place(at: CGPoint(x: x, y: bounds.midY), anchor: .leading,
                          proposal: ProposedViewSize(width: share, height: bounds.height))
            x += share + spacing
        }
    }
}
