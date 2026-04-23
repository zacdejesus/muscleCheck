//
//  ProgressPhotosView.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 23/04/2026.
//

import SwiftUI
import SwiftData

struct ProgressPhotosView: View {
    @StateObject private var viewModel = ProgressPhotoViewModel()
    @EnvironmentObject var storeManager: StoreManager
    @Environment(\.modelContext) private var context

    @State private var showingAddSheet = false
    @State private var showingCompare = false
    @State private var selectedPhoto: ProgressPhoto?

    private let columns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4)
    ]

    var body: some View {
        ProFeatureGate(lockedMessage: NSLocalizedString("progress_photos_title", comment: "")) {
            Group {
                if viewModel.photos.isEmpty {
                    emptyState
                } else {
                    photoGallery
                }
            }
            .navigationTitle("progress_photos_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        if !viewModel.photos.isEmpty {
                            Button {
                                viewModel.isCompareMode.toggle()
                                if !viewModel.isCompareMode {
                                    viewModel.clearCompareSelection()
                                }
                            } label: {
                                Image(systemName: viewModel.isCompareMode ? "rectangle.split.2x1.fill" : "rectangle.split.2x1")
                                    .foregroundColor(Color("PrimaryButtonColor"))
                            }
                        }
                        Button {
                            showingAddSheet = true
                        } label: {
                            Image(systemName: "camera.fill")
                                .foregroundColor(Color("PrimaryButtonColor"))
                        }
                    }
                }
            }
            .onAppear {
                viewModel.setup(context: context)
            }
            .sheet(isPresented: $showingAddSheet) {
                NavigationStack {
                    AddProgressPhotoView(viewModel: viewModel)
                }
            }
            .sheet(item: $selectedPhoto) { photo in
                NavigationStack {
                    PhotoDetailView(photo: photo, viewModel: viewModel)
                }
            }
            .sheet(isPresented: $showingCompare) {
                if let a = viewModel.comparePhotoA, let b = viewModel.comparePhotoB {
                    NavigationStack {
                        PhotoCompareView(photoBefore: a, photoAfter: b)
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("progress_photos_empty")
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button {
                showingAddSheet = true
            } label: {
                Label("progress_photos_add", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("PrimaryButtonColor"))
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Photo Gallery

    private var photoGallery: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                // Compare mode banner
                if viewModel.isCompareMode {
                    compareBanner
                }

                ForEach(viewModel.groupedPhotos, id: \.month) { group in
                    Section {
                        LazyVGrid(columns: columns, spacing: 4) {
                            ForEach(group.photos) { photo in
                                photoThumbnail(photo)
                            }
                        }
                    } header: {
                        Text(group.month)
                            .font(.subheadline.bold())
                            .foregroundColor(Color("PrimaryButtonColor"))
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Thumbnail

    @ViewBuilder
    private func photoThumbnail(_ photo: ProgressPhoto) -> some View {
        let isSelectedA = viewModel.comparePhotoA?.id == photo.id
        let isSelectedB = viewModel.comparePhotoB?.id == photo.id
        let isSelected = isSelectedA || isSelectedB

        Button {
            if viewModel.isCompareMode {
                viewModel.toggleCompareSelection(photo)
            } else {
                selectedPhoto = photo
            }
        } label: {
            ZStack(alignment: .bottomTrailing) {
                if let uiImage = photo.loadImage() {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(1, contentMode: .fill)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundColor(.secondary)
                        }
                }

                if viewModel.isCompareMode && isSelected {
                    Image(systemName: isSelectedA ? "1.circle.fill" : "2.circle.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color("PrimaryButtonColor"))
                        .clipShape(Circle())
                        .padding(4)
                }
            }
        }
        .overlay {
            if viewModel.isCompareMode && isSelected {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color("PrimaryButtonColor"), lineWidth: 3)
            }
        }
    }

    // MARK: - Compare Banner

    private var compareBanner: some View {
        HStack {
            Text("progress_photos_compare")
                .font(.subheadline.bold())
            Spacer()
            if viewModel.canCompare {
                Button {
                    showingCompare = true
                } label: {
                    Text("progress_photos_compare")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color("PrimaryButtonColor"))
                        .cornerRadius(8)
                }
            } else {
                Text(selectPrompt)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
    }

    private var selectPrompt: String {
        if viewModel.comparePhotoA == nil {
            return "Select first photo"
        } else {
            return "Select second photo"
        }
    }
}

// MARK: - Photo Detail View

struct PhotoDetailView: View {
    let photo: ProgressPhoto
    @ObservedObject var viewModel: ProgressPhotoViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm = false

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            if let uiImage = photo.loadImage() {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(Self.dateFormatter.string(from: photo.dateTaken))
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if !photo.note.isEmpty {
                    Text(photo.note)
                        .font(.body)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("BUTTON_CLOSE") { dismiss() }
                    .foregroundColor(Color("PrimaryButtonColor"))
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .alert("progress_photos_delete_confirm", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                viewModel.deletePhoto(photo)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
