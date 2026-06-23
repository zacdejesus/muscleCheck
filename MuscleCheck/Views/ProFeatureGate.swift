//
//  ProFeatureGate.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 18/04/2026.
//

import SwiftUI

/// How the locked (non-Pro) state is rendered.
enum ProFeatureGateStyle {
    /// Compact bordered button — for inline use inside list rows (e.g. Settings).
    case inline
    /// Centered upsell card with icon, value prop and CTA — for full-screen gates.
    case card
}

struct ProFeatureGate<Content: View>: View {
    @EnvironmentObject var storeManager: StoreManager
    @State private var showPaywall = false

    let lockedMessage: String
    /// Optional value-prop line, shown under the title in `.card` style.
    var description: String? = nil
    /// Header symbol for `.card` style.
    var icon: String = "crown.fill"
    var style: ProFeatureGateStyle = .inline
    @ViewBuilder let content: () -> Content

    var body: some View {
        if storeManager.isPro {
            content()
        } else {
            lockedView
                .sheet(isPresented: $showPaywall) {
                    PaywallView()
                        .environmentObject(storeManager)
                }
        }
    }

    @ViewBuilder
    private var lockedView: some View {
        switch style {
        case .inline: inlineButton
        case .card: cardView
        }
    }

    // MARK: - Inline (list rows)

    private var inlineButton: some View {
        Button {
            showPaywall = true
        } label: {
            HStack {
                Image(systemName: "lock.fill")
                Text(lockedMessage)
                    .fontWeight(.medium)
            }
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.gray)
    }

    // MARK: - Card (full-screen upsell)

    private var cardView: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundColor(Color("PrimaryButtonColor"))

            Text(lockedMessage)
                .font(.appTitle2.bold())
                .multilineTextAlignment(.center)

            if let description {
                Text(description)
                    .font(.appSubheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showPaywall = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "crown.fill")
                    Text("pro_unlock_button")
                        .fontWeight(.semibold)
                }
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("PrimaryButtonColor"))
            .padding(.top, 4)
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}
