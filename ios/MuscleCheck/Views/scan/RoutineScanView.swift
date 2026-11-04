//
//  RoutineScanView.swift
//  MuscleCheck — Feature: escanear rutina en papel
//
//  The scan sheet. Four states on one NavigationStack, switched by the view model's
//  phase: pick a photo → reading (on-device) → review → done. The review is the key
//  screen: every exercise the model read is an editable draft, doubtful fields are
//  highlighted, and nothing is stored until the user confirms.
//

import SwiftUI
import PhotosUI
import UIKit

struct RoutineScanView: View {

    @StateObject private var viewModel: RoutineScanViewModel
    /// The numbered list the model picks from AND the group picker's options — one array,
    /// so a model index and a picker row always mean the same group.
    let gymGroups: [MuscleEntry]
    /// Persists the confirmed drafts; nil if the store write failed.
    let onImport: ([ScannedExerciseDraft]) -> RoutineImport.Result?

    @Environment(\.dismiss) private var dismiss
    @State private var photoItem: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var importFailed = false
    /// Bumped on every "Dar vuelta" — drives the light haptic.
    @State private var swapCount = 0

    init(
        scanner: (any RoutineScanning)?,
        gymGroups: [MuscleEntry],
        onImport: @escaping ([ScannedExerciseDraft]) -> RoutineImport.Result?
    ) {
        // `StateObject(wrappedValue:)` is an autoclosure evaluated once per view identity:
        // the parent re-rendering the sheet doesn't rebuild the view model mid-scan.
        _viewModel = StateObject(wrappedValue: RoutineScanViewModel(scanner: scanner))
        self.gymGroups = gymGroups
        self.onImport = onImport
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("scan_title")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbar }
        }
        .tint(Color.brand)
        // A swipe-down must not throw away the user's corrections.
        .interactiveDismissDisabled(viewModel.phase == .review)
        .onDisappear { viewModel.cancelScan() }
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            photoItem = nil
            Task {
                guard let data = try? await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else {
                    viewModel.reportUnreadablePhoto()
                    return
                }
                viewModel.startScan(image, groups: gymGroups)
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraPicker { image in
                viewModel.startScan(image, groups: gymGroups)
            }
            .ignoresSafeArea()
        }
        .alert("scan_import_failed", isPresented: $importFailed) {
            Button("add_done", role: .cancel) {}
        }
        .sensoryFeedback(.impact(weight: .light), trigger: swapCount)
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        if case .done = viewModel.phase {
            ToolbarItem(placement: .confirmationAction) {
                Button("add_done") { dismiss() }
            }
        } else {
            ToolbarItem(placement: .cancellationAction) {
                Button("cancel") { dismiss() }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .pickPhoto:
            pickPhotoView
        case .reading:
            readingView
        case .review:
            reviewView
        case .done(let result):
            doneView(result)
        }
    }

    // MARK: - 1. Pick a photo

    private var pickPhotoView: some View {
        let downloading = viewModel.availability == .modelNotReady
        return ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "doc.viewfinder")
                    .font(.appLargeTitle)
                    .imageScale(.large)
                    .foregroundStyle(Color.brand)
                    .padding(.top, 24)

                Text("scan_pick_title")
                    .font(.appTitle2.bold())
                    .multilineTextAlignment(.center)
                Text("scan_pick_subtitle")
                    .font(.appBody)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if downloading {
                    Label("scan_model_downloading", systemImage: "arrow.down.circle")
                        .font(.appSubheadline)
                        .foregroundStyle(.secondary)
                }
                if let error = viewModel.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.appSubheadline)
                        .foregroundStyle(.orange)
                }

                VStack(spacing: 12) {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        Button {
                            showingCamera = true
                        } label: {
                            Label("scan_take_photo", systemImage: "camera")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .accessibilityIdentifier("scan.camera")
                    }
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label("scan_choose_photo", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .accessibilityIdentifier("scan.library")
                }
                .disabled(downloading)
            }
            .padding()
        }
    }

    // MARK: - 2. Reading

    private var readingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("scan_reading")
                .font(.appHeadline)
            Text("scan_reading_on_device")
                .font(.appSubheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if !viewModel.readingPreview.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(viewModel.readingPreview.enumerated()), id: \.offset) { _, name in
                        Label(name, systemImage: "checkmark")
                            .font(.appSubheadline)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.default, value: viewModel.readingPreview)
    }

    // MARK: - 3. Review

    private var reviewView: some View {
        List {
            VStack(alignment: .leading, spacing: 6) {
                Text("scan_review_header")
                    .font(.appTitle.bold())
                    .tracking(-0.4)
                Text("scan_review_subtitle")
                    .font(.appSubheadline)
                    .foregroundStyle(.secondary)
            }
            .reviewListRow(top: 4, bottom: 6)

            ForEach($viewModel.drafts) { $draft in
                ScannedExerciseRow(draft: $draft, groups: gymGroups) {
                    withAnimation(.snappy) { viewModel.swapSetsAndReps(id: draft.id) }
                    swapCount += 1
                }
                .reviewListRow(top: 6, bottom: 6)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        withAnimation(.snappy) { viewModel.deleteDraft(id: draft.id) }
                    } label: {
                        Label("scan_delete_row", systemImage: "trash")
                    }
                }
            }

            Button {
                withAnimation(.snappy) { viewModel.addMissingExercise() }
            } label: {
                Label("scan_add_missing", systemImage: "plus")
                    .font(.appCallout)
                    .foregroundStyle(Color.brand)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }
            .reviewListRow(top: 2, bottom: 8)
            .accessibilityIdentifier("scan.addMissing")
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background(Color.surface)
        .toolbar {
            // Number pads have no return key: give the keyboard a way out.
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("add_done") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 6) {
                Button {
                    confirmImport()
                } label: {
                    Text("scan_import_button \(viewModel.drafts.count)")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!viewModel.canImport)
                .accessibilityIdentifier("scan.import")

                if let caption = blockingCaption {
                    caption
                        .font(.appCaption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 8)
            // Opaque, same colour as the list: no material band, no shadow.
            .background(Color.surface)
        }
    }

    /// Names what still blocks the import, so a disabled button is never a mystery.
    private var blockingCaption: Text? {
        if viewModel.missingGroupCount > 0 {
            return Text("scan_missing_group \(viewModel.missingGroupCount)")
        }
        if viewModel.missingNameCount > 0 {
            return Text("scan_missing_name \(viewModel.missingNameCount)")
        }
        return nil
    }

    private func confirmImport() {
        guard let result = onImport(viewModel.drafts) else {
            importFailed = true
            return
        }
        viewModel.didImport(result)
    }

    // MARK: - 4. Done

    private func doneView(_ result: RoutineImport.Result) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.appLargeTitle)
                .imageScale(.large)
                .foregroundStyle(.green)
            Text("scan_done_title")
                .font(.appTitle2.bold())
            Text("scan_done_added \(result.added)")
                .font(.appBody)
            if result.createdGroups > 0 {
                Text("scan_done_groups \(result.createdGroups)")
                    .font(.appSubheadline)
                    .foregroundStyle(.secondary)
            }
            if result.skippedDuplicates > 0 {
                Text("scan_done_skipped \(result.skippedDuplicates)")
                    .font(.appSubheadline)
                    .foregroundStyle(.secondary)
            }
            Text("scan_done_hint")
                .font(.appSubheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private extension View {
    /// Cards float on the screen background: no row chrome, 16 pt margins, 12 pt between cards.
    func reviewListRow(top: CGFloat, bottom: CGFloat) -> some View {
        listRowInsets(EdgeInsets(top: top, leading: 16, bottom: bottom, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}
