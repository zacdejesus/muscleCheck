//
//  ProFeatureGate.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 18/04/2026.
//

import SwiftUI

struct ProFeatureGate<Content: View>: View {
    @EnvironmentObject var storeManager: StoreManager
    @State private var showPaywall = false
    
    let lockedMessage: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        if storeManager.isPro {
            content()
        } else {
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
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(storeManager)
            }
        }
    }
}
