//
//  IconGridPicker.swift
//  MuscleCheck
//
//  The icon selection grid shared by the add-exercise screen and category
//  management (previously duplicated in both).
//

import SwiftUI

struct IconGridPicker: View {
    @Binding var selectedIcon: String

    private let columns = Array(repeating: GridItem(.flexible()), count: 6)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(ActivityCategory.availableIcons, id: \.self) { icon in
                Button {
                    selectedIcon = icon
                } label: {
                    Image(systemName: icon)
                        .font(.appTitle3)
                        .frame(width: 40, height: 40)
                        .background(selectedIcon == icon ? Color.brand.opacity(0.2) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .foregroundColor(selectedIcon == icon ? Color.brand : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}
