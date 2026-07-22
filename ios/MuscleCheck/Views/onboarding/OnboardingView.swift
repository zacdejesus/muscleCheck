//
//  OnboardingView.swift
//  MuscleCheck
//
//  Two screens, zero permissions, zero paywall: show the mental model, personalize
//  the initial checklist, get out of the way. Everything else is taught in context
//  via TipKit (see AppTips.swift).
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var step: Step = .welcome

    private enum Step { case welcome, picker }

    var body: some View {
        ZStack {
            switch step {
            case .welcome:
                WelcomeStepView {
                    withAnimation(.easeInOut) { step = .picker }
                }
                .transition(.asymmetric(
                    insertion: .identity,
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            case .picker:
                CategoryPickerStepView(
                    viewModel: viewModel,
                    onContinue: { viewModel.completeOnboarding(context: context) },
                    onSkip: { viewModel.skipOnboarding(context: context) }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Step 1: Welcome

private struct WelcomeStepView: View {
    var onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            demoChecklist
                .padding(.bottom, 40)

            Text("onboarding_welcome_title")
                .font(.appTitle.bold())
                .multilineTextAlignment(.center)
                .padding(.bottom, 12)

            Text("onboarding_welcome_body")
                .font(.appBody)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
            Spacer()

            Button {
                onContinue()
            } label: {
                Text("onboarding_welcome_cta")
                    .fontWeight(.medium)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.brand)
            .accessibilityIdentifier("onboarding.start")
        }
        .padding(24)
    }

    /// Non-interactive mini checklist in the app's own row language: shows the core
    /// loop (activity → check) and that this isn't gym-only, without a word of copy.
    private var demoChecklist: some View {
        VStack(spacing: 14) {
            demoRow(.gym, checked: true)
            demoRow(.yoga, checked: false)
            demoRow(.running, checked: false)
        }
        .padding(16)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityHidden(true)
    }

    private func demoRow(_ category: ActivityCategory, checked: Bool) -> some View {
        HStack {
            Image(systemName: category.defaultIcon)
                .font(.appSubheadline)
                .foregroundStyle(Color.brand)
                .frame(width: 32, height: 32)
                .background(Color.brand.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                .padding(.trailing, 4)
            Text(category.displayName)
            Spacer(minLength: 24)
            Image(systemName: checked ? "checkmark.circle.fill" : "circle")
                .foregroundColor(checked ? .success : .gray)
        }
    }
}

// MARK: - Step 2: Category picker

private struct CategoryPickerStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    var onContinue: () -> Void
    var onSkip: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)

    var body: some View {
        VStack(spacing: 0) {
            Text("onboarding_picker_title")
                .font(.appTitle2.bold())
                .multilineTextAlignment(.center)
                .padding(.top, 32)
                .padding(.bottom, 8)

            Text("onboarding_picker_subtitle")
                .font(.appSubheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 20)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(viewModel.selectableCategories) { category in
                        categoryCard(category)
                    }
                }
                .padding(.vertical, 4)
            }
            .scrollBounceBehavior(.basedOnSize)

            Button {
                onContinue()
            } label: {
                Text("onboarding_picker_cta")
                    .fontWeight(.medium)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.brand)
            .disabled(!viewModel.canContinue)
            .accessibilityIdentifier("onboarding.createList")
            .padding(.top, 12)

            Button("onboarding_skip") {
                onSkip()
            }
            .font(.appSubheadline)
            .foregroundStyle(.secondary)
            .accessibilityIdentifier("onboarding.skip")
            .padding(.top, 12)
        }
        .padding(24)
    }

    private func categoryCard(_ category: ActivityCategory) -> some View {
        let isSelected = viewModel.selectedCategories.contains(category)
        return Button {
            viewModel.toggle(category)
        } label: {
            VStack(spacing: 8) {
                Image(systemName: category.defaultIcon)
                    .font(.appTitle2)
                Text(category.displayName)
                    .font(.appSubheadline)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, minHeight: 92)
            .background(
                isSelected ? Color.brand.opacity(0.15) : Color(.systemGray6),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color.brand : .clear, lineWidth: 1.5)
            )
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.brand)
                        .padding(8)
                }
            }
            .foregroundStyle(isSelected ? Color.brand : .primary)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("onboarding.category.\(category.rawValue)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    OnboardingView()
        .modelContainer(for: MuscleEntry.self, inMemory: true)
}
