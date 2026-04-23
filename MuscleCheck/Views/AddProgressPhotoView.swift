//
//  AddProgressPhotoView.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 23/04/2026.
//

import SwiftUI
import PhotosUI

struct AddProgressPhotoView: View {
    @ObservedObject var viewModel: ProgressPhotoViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var note: String = ""
    @State private var isLoading = false

    var body: some View {
        Form {
            // Photo selection
            Section {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .frame(maxWidth: .infinity)
                }

                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images
                ) {
                    Label(
                        selectedImage == nil ? "progress_photos_add" : "Change Photo",
                        systemImage: "photo.on.rectangle"
                    )
                    .foregroundColor(Color("PrimaryButtonColor"))
                }
            }

            // Note
            Section {
                TextField("progress_photos_note_placeholder", text: $note)
            }
        }
        .navigationTitle("progress_photos_add")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
                    .foregroundColor(Color("PrimaryButtonColor"))
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    save()
                }
                .foregroundColor(Color("PrimaryButtonColor"))
                .fontWeight(.semibold)
                .disabled(selectedImage == nil || isLoading)
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem else { return }
            isLoading = true
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    selectedImage = uiImage
                }
                isLoading = false
            }
        }
        .overlay {
            if isLoading {
                ProgressView()
            }
        }
    }

    private func save() {
        guard let image = selectedImage else { return }
        viewModel.addPhoto(image: image, note: note.trimmingCharacters(in: .whitespacesAndNewlines))
        dismiss()
    }
}
