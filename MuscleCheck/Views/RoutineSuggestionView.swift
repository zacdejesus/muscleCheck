//
//  RoutineSuggestionView.swift
//  MuscleCheck
//
//  AI Coach day-suggestion modal (Feature 12). Read-only guidance: it never checks
//  anything — the user marks groups in the main list as always. Free, on-device.
//

import SwiftUI

struct RoutineSuggestionView: View {

    @ObservedObject var viewModel: ContentViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if let suggestion = viewModel.routineSuggestion {
                    suggestionContent(suggestion)
                } else if let error = viewModel.routineError {
                    errorState(error)
                } else {
                    loadingState
                }
            }
            .navigationTitle("ai_coach_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("BUTTON_CLOSE") { dismiss() }
                }
            }
        }
    }

    // MARK: - States

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("ai_coach_generating")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            anotherButton
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func suggestionContent(_ suggestion: RoutineSuggestion) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if !suggestion.focus.isEmpty {
                    Text(suggestion.focus)
                        .font(.largeTitle.bold())
                }
                if !suggestion.rationale.isEmpty {
                    Text(suggestion.rationale)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                ForEach(Array(suggestion.blocks.enumerated()), id: \.offset) { _, block in
                    blockView(block)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .safeAreaInset(edge: .bottom) {
            anotherButton
                .padding(.horizontal)
                .padding(.bottom, 8)
                .background(.bar)
        }
    }

    private func blockView(_ block: RoutineSuggestion.Block) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(block.groupName)
                .font(.headline)
                .foregroundColor(Color("PrimaryButtonColor"))
            ForEach(block.exercises, id: \.self) { exercise in
                Label(exercise, systemImage: "circle.fill")
                    .labelStyle(BulletLabelStyle())
                    .font(.body)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var anotherButton: some View {
        Button {
            Task { await viewModel.generateRoutine(regenerate: true) }
        } label: {
            HStack {
                if viewModel.isGeneratingRoutine {
                    ProgressView()
                } else {
                    Image(systemName: "sparkles")
                }
                Text("ai_coach_another").fontWeight(.medium)
            }
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color("PrimaryButtonColor"))
        .disabled(viewModel.isGeneratingRoutine)
    }
}

/// Small bullet for exercise lists (tiny dot + text).
private struct BulletLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            configuration.icon
                .font(.system(size: 5))
                .foregroundStyle(.secondary)
            configuration.title
        }
    }
}
