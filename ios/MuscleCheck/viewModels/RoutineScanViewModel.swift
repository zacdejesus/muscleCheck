//
//  RoutineScanViewModel.swift
//  MuscleCheck — Feature: escanear rutina en papel
//
//  Drives the scan sheet: pick a photo → read it → review/correct → load.
//  Targets iOS 18 and never imports FoundationModels: the model is reached through the
//  injected `RoutineScanning` (nil where the feature can't run). Persistence isn't here
//  either — the sheet hands the confirmed drafts to ContentViewModel, which already owns
//  the store and the home refresh.
//

import Foundation
import UIKit

@MainActor
final class RoutineScanViewModel: ObservableObject {

    enum Phase: Equatable {
        case pickPhoto
        case reading
        case review
        case done(RoutineImport.Result)
    }

    @Published private(set) var phase: Phase = .pickPhoto
    /// The editable result. Only meaningful in `.review`.
    @Published var drafts: [ScannedExerciseDraft] = []
    /// Names streamed in while reading, so the wait shows progress instead of a bare spinner.
    @Published private(set) var readingPreview: [String] = []
    @Published private(set) var errorMessage: String?

    private let scanner: (any RoutineScanning)?
    private var scanTask: Task<Void, Never>?

    init(scanner: (any RoutineScanning)?) {
        self.scanner = scanner
    }

    var availability: RoutineScanAvailability {
        scanner?.availability ?? .unavailable
    }

    /// Every card must be loadable: an invalid one gets fixed or deleted, never silently
    /// dropped — nothing lands in the store unreviewed.
    var canImport: Bool {
        !drafts.isEmpty && drafts.allSatisfy(\.isImportable)
    }

    // MARK: - Reading

    /// Starts reading `image`. An unstructured Task on purpose: it's kicked off by a
    /// picker callback, not tied to a view modifier's lifetime — so it's kept here to be
    /// cancelled if the sheet closes mid-read.
    func startScan(_ image: UIImage, groups: [MuscleEntry]) {
        scanTask?.cancel()
        scanTask = Task { await scan(image, groups: groups) }
    }

    func cancelScan() {
        scanTask?.cancel()
        scanTask = nil
    }

    /// - Parameter groups: the gym groups the review offers; each card's group is chosen among
    ///   them in code (`RoutineImport.groupChoice`), never by the model.
    func scan(_ image: UIImage, groups: [MuscleEntry]) async {
        guard let scanner else { return }
        errorMessage = nil
        readingPreview = []
        phase = .reading

        guard let cgImage = await RoutineScanImage.prepare(image) else {
            fail("scan_error_generic")
            return
        }

        do {
            let routine = try await scanner.scan(image: cgImage) { [weak self] partial in
                self?.readingPreview = partial.items.map(\.name)
            }
            let drafts = RoutineImport.drafts(from: routine, groups: groups)
            guard !drafts.isEmpty else {
                fail("scan_error_nothing_found")
                return
            }
            self.drafts = drafts
            phase = .review
        } catch is CancellationError {
            phase = .pickPhoto
        } catch RoutineScanError.nothingFound {
            fail("scan_error_nothing_found")
        } catch {
            fail("scan_error_generic")
        }
    }

    /// The picked library item couldn't be loaded as an image (e.g. an iCloud asset
    /// that failed to download).
    func reportUnreadablePhoto() {
        fail("scan_error_generic")
    }

    // MARK: - Review

    /// Cards without a group — they block the import and the caption under the CTA says so.
    var missingGroupCount: Int { drafts.filter { !$0.hasValidGroup }.count }
    var missingNameCount: Int { drafts.filter { $0.trimmedName.isEmpty }.count }

    func addMissingExercise() {
        // Inherit the previous card's group: a missed exercise usually sits next to it.
        drafts.append(ScannedExerciseDraft(name: "", group: drafts.last?.group))
    }

    func deleteDraft(id: UUID) {
        drafts.removeAll { $0.id == id }
    }

    /// "Dar vuelta" on a card whose sets × reps look backwards.
    func swapSetsAndReps(id: UUID) {
        guard let index = drafts.firstIndex(where: { $0.id == id }) else { return }
        drafts[index].swapSetsAndReps()
    }

    func didImport(_ result: RoutineImport.Result) {
        phase = .done(result)
    }

    private func fail(_ message: String.LocalizationValue) {
        errorMessage = String(localized: message)
        phase = .pickPhoto
    }
}

/// Image prep before the model sees the photo.
enum RoutineScanImage {

    /// Long side, in pixels. A 12 MP photo is ~4000 px: far more than needed to read a
    /// sheet, and decoding/sending it costs memory and latency.
    static let maxDimension: CGFloat = 1600

    /// Downscales and bakes the orientation in a single render. `Attachment` takes a
    /// `CGImage` (there's no `UIImage` init) and a CGImage carries no orientation, so a
    /// portrait camera photo would reach the model sideways. Redrawing through
    /// `UIGraphicsImageRenderer` produces `.up` pixels — no orientation mapping needed.
    ///
    /// `@concurrent`: this target has Approachable Concurrency on, so a plain
    /// `nonisolated async` func would run on the CALLER's actor — the main actor here —
    /// and rendering a large photo would freeze the reading screen's first frames.
    @concurrent
    nonisolated static func prepare(_ image: UIImage) async -> CGImage? {
        let pixelWidth = image.size.width * image.scale
        let pixelHeight = image.size.height * image.scale
        guard pixelWidth > 0, pixelHeight > 0 else { return nil }

        let scale = min(1, maxDimension / max(pixelWidth, pixelHeight))
        let target = CGSize(width: (pixelWidth * scale).rounded(), height: (pixelHeight * scale).rounded())

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let rendered = UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return rendered.cgImage
    }
}
