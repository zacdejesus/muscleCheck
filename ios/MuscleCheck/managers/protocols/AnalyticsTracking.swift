//
//  AnalyticsTracking.swift
//  MuscleCheck
//
//  Seam de analítica (docs/analytics-plan.md §11). Firebase es UNA implementación: los
//  tests inyectan un spy y los UI tests una NoOp, así el dato real nunca se ensucia.
//

import Foundation

protocol AnalyticsTracking: Sendable {
    func track(_ event: AnalyticsEvent)
}
