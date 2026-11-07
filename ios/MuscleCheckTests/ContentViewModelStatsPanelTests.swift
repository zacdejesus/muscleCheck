//
//  ContentViewModelStatsPanelTests.swift
//  MuscleCheck
//

import Testing
@testable import MuscleCheck
import Foundation

@MainActor
struct ContentViewModelStatsPanelTests {

    @Test
    func showsPanelOnIPhoneDuoOpenInLandscape() {
        #expect(ContentViewModel.showsStatsPanel(windowSize: CGSize(width: 951, height: 669), isRegularWidth: true))
    }

    @Test
    func hidesPanelOnIPhoneDuoOpenInPortrait() {
        #expect(!ContentViewModel.showsStatsPanel(windowSize: CGSize(width: 669, height: 951), isRegularWidth: true))
    }

    @Test
    func hidesPanelInCompactWidthEvenWhenWideEnough() {
        // e.g. a Pro Max iPhone in landscape: wide, but compact horizontal size class.
        #expect(!ContentViewModel.showsStatsPanel(windowSize: CGSize(width: 956, height: 440), isRegularWidth: false))
    }

    @Test
    func hidesPanelInPortraitRegularWindowWiderThanThreshold() {
        // iPad in portrait: regular and wider than the threshold, but not landscape.
        #expect(!ContentViewModel.showsStatsPanel(windowSize: CGSize(width: 1032, height: 1376), isRegularWidth: true))
    }

    @Test
    func hidesPanelInLandscapeWindowNarrowerThanThreshold() {
        #expect(!ContentViewModel.showsStatsPanel(windowSize: CGSize(width: 700, height: 500), isRegularWidth: true))
    }

    @Test
    func thresholdIsInclusive() {
        let width = ContentViewModel.statsPanelMinWidth
        #expect(ContentViewModel.showsStatsPanel(windowSize: CGSize(width: width, height: width - 1), isRegularWidth: true))
    }

    @Test
    func hidesPanelBeforeFirstLayout() {
        #expect(!ContentViewModel.showsStatsPanel(windowSize: .zero, isRegularWidth: true))
    }
}
