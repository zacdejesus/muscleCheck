//
//  RoutineScanViewModelTests.swift
//  MuscleCheckTests — Feature: escanear rutina en papel
//
//  The whole sheet flow driven through a mock `RoutineScanning`: no device, no model.
//  This is what the protocol seam buys — the view model is tested without
//  FoundationModels existing at all.
//

import Testing
@testable import MuscleCheck
import Foundation
import UIKit

@MainActor
final class MockRoutineScanner: RoutineScanning {
    var availability: RoutineScanAvailability = .available
    var result: Result<ScannedRoutine, any Error> = .success(ScannedRoutine(items: []))
    var partials: [ScannedRoutine] = []

    func scan(
        image: CGImage,
        onPartial: ((ScannedRoutine) -> Void)?
    ) async throws -> ScannedRoutine {
        partials.forEach { onPartial?($0) }
        return try result.get()
    }
}

@MainActor
struct RoutineScanViewModelTests {

    private let photo = UIGraphicsImageRenderer(size: CGSize(width: 40, height: 60)).image { ctx in
        UIColor.white.setFill()
        ctx.fill(CGRect(x: 0, y: 0, width: 40, height: 60))
    }

    private func item(_ name: String, sets: Int? = nil, reps: String? = nil, muscle: TargetMuscle? = nil,
                      low: Bool = false) -> ScannedRoutine.Item {
        .init(name: name, sets: sets, repsText: reps, muscle: muscle, lowConfidence: low)
    }

    @Test
    func noScannerMeansUnavailable() {
        let vm = RoutineScanViewModel(scanner: nil)
        #expect(vm.availability == .unavailable)
    }

    @Test
    func availabilityComesFromTheScanner() {
        let scanner = MockRoutineScanner()
        scanner.availability = .modelNotReady
        #expect(RoutineScanViewModel(scanner: scanner).availability == .modelNotReady)
    }

    @Test
    func successfulScanGoesToReviewWithValidatedDrafts() async {
        let pecho = MuscleEntry(name: "Pecho", category: "gym")
        let scanner = MockRoutineScanner()
        scanner.result = .success(ScannedRoutine(items: [
            item("Press banca", sets: 4, reps: "8-12", muscle: .chest),
            item("Movilidad de cadera", low: true),
        ]))
        let vm = RoutineScanViewModel(scanner: scanner)

        await vm.scan(photo, groups: [pecho])

        #expect(vm.phase == .review)
        #expect(vm.drafts.count == 2)
        #expect(vm.drafts[0].group == .existing(pecho.id))
        #expect(vm.drafts[0].sets == 4)
        #expect(vm.drafts[0].reps == 8)
        #expect(vm.drafts[0].repRange == "8-12")
        // No muscle and nothing written on the sheet: the user must pick a group.
        #expect(vm.drafts[1].group == nil)
        #expect(vm.drafts[1].lowConfidence)
        #expect(!vm.canImport)
    }

    @Test
    func pickingTheMissingGroupEnablesTheImport() async {
        let pecho = MuscleEntry(name: "Pecho", category: "gym")
        let scanner = MockRoutineScanner()
        scanner.result = .success(ScannedRoutine(items: [item("Movilidad de cadera")]))
        let vm = RoutineScanViewModel(scanner: scanner)
        await vm.scan(photo, groups: [pecho])
        #expect(!vm.canImport)
        #expect(vm.missingGroupCount == 1)

        vm.drafts[0].group = .existing(pecho.id)

        #expect(vm.canImport)
        #expect(vm.missingGroupCount == 0)
    }

    @Test
    func partialSnapshotsFeedTheReadingPreview() async {
        let scanner = MockRoutineScanner()
        scanner.partials = [
            ScannedRoutine(items: [item("Sentadilla")]),
            ScannedRoutine(items: [item("Sentadilla"), item("Prensa")]),
        ]
        scanner.result = .success(ScannedRoutine(items: [item("Sentadilla"), item("Prensa")]))
        let vm = RoutineScanViewModel(scanner: scanner)

        await vm.scan(photo, groups: [])

        #expect(vm.readingPreview == ["Sentadilla", "Prensa"])
    }

    @Test
    func nothingFoundReturnsToThePickerWithAMessage() async {
        let scanner = MockRoutineScanner()
        scanner.result = .failure(RoutineScanError.nothingFound)
        let vm = RoutineScanViewModel(scanner: scanner)

        await vm.scan(photo, groups: [])

        #expect(vm.phase == .pickPhoto)
        #expect(vm.errorMessage != nil)
        #expect(vm.drafts.isEmpty)
    }

    @Test
    func onlyBlankNamesCountsAsNothingFound() async {
        let scanner = MockRoutineScanner()
        scanner.result = .success(ScannedRoutine(items: [item("   ")]))
        let vm = RoutineScanViewModel(scanner: scanner)

        await vm.scan(photo, groups: [])

        #expect(vm.phase == .pickPhoto)
        #expect(vm.errorMessage != nil)
    }

    @Test(arguments: [RoutineScanError.noText, .notARoutine])
    func photosThatAreNotRoutinesGetTheirOwnMessage(error: RoutineScanError) async {
        let scanner = MockRoutineScanner()
        scanner.result = .failure(error)
        let vm = RoutineScanViewModel(scanner: scanner)

        await vm.scan(photo, groups: [])

        #expect(vm.phase == .pickPhoto)
        #expect(vm.errorMessage != nil)
        #expect(vm.errorMessage != String(localized: "scan_error_generic"))
    }

    @Test
    func modelFailureReturnsToThePickerWithAMessage() async {
        let scanner = MockRoutineScanner()
        scanner.result = .failure(RoutineScanError.failed)
        let vm = RoutineScanViewModel(scanner: scanner)

        await vm.scan(photo, groups: [])

        #expect(vm.phase == .pickPhoto)
        #expect(vm.errorMessage != nil)
    }

    @Test
    func addMissingExerciseInheritsThePreviousGroupAndDeleteRemovesRows() async {
        let pecho = MuscleEntry(name: "Pecho", category: "gym")
        let scanner = MockRoutineScanner()
        scanner.result = .success(ScannedRoutine(items: [item("Press banca", muscle: .chest)]))
        let vm = RoutineScanViewModel(scanner: scanner)
        await vm.scan(photo, groups: [pecho])

        vm.addMissingExercise()
        #expect(vm.drafts.count == 2)
        #expect(vm.drafts[1].group == .existing(pecho.id))
        // A blank added card blocks the import until named or deleted.
        #expect(!vm.canImport)
        #expect(vm.missingNameCount == 1)

        vm.deleteDraft(id: vm.drafts[1].id)
        #expect(vm.drafts.count == 1)
        #expect(vm.canImport)
    }

    @Test
    func darVueltaSwapsOnlyThatCard() async {
        let piernas = MuscleEntry(name: "Piernas", category: "gym")
        let scanner = MockRoutineScanner()
        scanner.result = .success(ScannedRoutine(items: [
            item("Prensa", sets: 14, reps: "8", muscle: .legs),
            item("Sentadilla", sets: 4, reps: "10", muscle: .legs),
        ]))
        let vm = RoutineScanViewModel(scanner: scanner)
        await vm.scan(photo, groups: [piernas])
        #expect(vm.drafts[0].suggestsSwap)

        vm.swapSetsAndReps(id: vm.drafts[0].id)

        #expect(vm.drafts[0].sets == 8)
        #expect(vm.drafts[0].reps == 14)
        #expect(!vm.drafts[0].lowConfidence)
        #expect(vm.drafts[1].sets == 4)
        #expect(vm.drafts[1].reps == 10)
    }

    @Test
    func imageIsDownscaledAndKeepsItsAspect() async throws {
        let big = UIGraphicsImageRenderer(
            size: CGSize(width: 3000, height: 4000),
            format: { let f = UIGraphicsImageRendererFormat(); f.scale = 1; return f }()
        ).image { _ in }

        let prepared = try #require(await RoutineScanImage.prepare(big))

        #expect(prepared.height == Int(RoutineScanImage.maxDimension))
        #expect(prepared.width == 1200)
    }
}
