//
//  PhotoCompareView.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 23/04/2026.
//

import SwiftUI

struct PhotoCompareView: View {
    let photoBefore: ProgressPhoto
    let photoAfter: ProgressPhoto
    @Environment(\.dismiss) private var dismiss

    @State private var sliderPosition: CGFloat = 0.5

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                let width = geometry.size.width
                let dividerX = width * sliderPosition

                ZStack {
                    // "After" photo — full width behind
                    if let afterImage = photoAfter.loadImage() {
                        Image(uiImage: afterImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: width, height: geometry.size.height)
                            .clipped()
                    }

                    // "Before" photo — clipped to left of divider
                    if let beforeImage = photoBefore.loadImage() {
                        Image(uiImage: beforeImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: width, height: geometry.size.height)
                            .clipped()
                            .mask(
                                HStack(spacing: 0) {
                                    Rectangle()
                                        .frame(width: dividerX)
                                    Spacer(minLength: 0)
                                }
                            )
                    }

                    // Divider line + handle
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 3)
                        .position(x: dividerX, y: geometry.size.height / 2)
                        .shadow(radius: 2)

                    Circle()
                        .fill(Color.white)
                        .frame(width: 36, height: 36)
                        .overlay {
                            Image(systemName: "arrow.left.and.right")
                                .font(.caption)
                                .foregroundColor(.black)
                        }
                        .shadow(radius: 4)
                        .position(x: dividerX, y: geometry.size.height / 2)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let newPosition = value.location.x / width
                            sliderPosition = min(max(newPosition, 0.05), 0.95)
                        }
                )
            }

            // Date labels
            HStack {
                VStack(alignment: .leading) {
                    Text("progress_photos_before")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    Text(Self.dateFormatter.string(from: photoBefore.dateTaken))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("progress_photos_after")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    Text(Self.dateFormatter.string(from: photoAfter.dateTaken))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("progress_photos_compare")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("BUTTON_CLOSE") { dismiss() }
                    .foregroundColor(Color("PrimaryButtonColor"))
            }
        }
    }
}
