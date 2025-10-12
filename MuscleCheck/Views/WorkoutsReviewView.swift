//
//  ItineraryView.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 12/10/2025.
//


import FoundationModels
import SwiftUI
import MapKit

struct WorkoutsReviewView: View {
    let landmark: Landmark
    let trainingReview: UserTrainingReview.PartiallyGenerated

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading) {
                if let title = itinerary.title {
                    Text(title)
                        .contentTransition(.opacity)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                if let description = itinerary.description {
                    Text(description)
                        .contentTransition(.opacity)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            HStack(alignment: .top) {
                Image(systemName: "sparkles")
                if let rationale = itinerary.rationale {
                    Text(rationale)
                        .contentTransition(.opacity)
                        .rationaleStyle()
                }
            }
            
            if let days = itinerary.days {
                ForEach(days, id: \.title) { plan in
                    DayView(
                        landmark: landmark,
                        plan: plan
                    )
                }
            }
        }
        .animation(.easeOut, value: itinerary)
        .itineraryStyle()
    }
}

private struct DayView: View {
    let landmark: Landmark
    let plan: DayPlan.PartiallyGenerated

    @State private var mapItem: MKMapItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack(alignment: .bottom) {
                LandmarkDetailMapView(
                    landmark: landmark,
                    landmarkMapItem: mapItem
                )
                
                .task(id: plan.destination) {
                    guard let destination = plan.destination, !destination.isEmpty else { return }
                    
                    
                    if let fetchedItem = await LocationLookup().mapItem(atLocation: destination) {
                        self.mapItem = fetchedItem
                    }
                }
                
                VStack(alignment: .leading) {
                    
                    if let title = plan.title {
                        Text(title)
                            .contentTransition(.opacity)
                            .font(.headline)
                    }
                    if let subtitle = plan.subtitle {
                        Text(subtitle)
                            .contentTransition(.opacity)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .blurredBackground()
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .padding([.horizontal, .top], 4)
            
            ActivityList(activities: plan.activities ?? [])
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
        }
        .padding(.bottom)
        .geometryGroup()
        .card()
        .animation(.easeInOut, value: plan)
    }
    
    
}

private struct ActivityList: View {
    let activities: [Activity].PartiallyGenerated
    
    var body: some View {
        ForEach(activities) { activity in
            HStack(alignment: .top, spacing: 12) {
                if let title = activity.title {
                    ActivityIcon(symbolName: activity.type?.symbolName)
                    VStack(alignment: .leading) {
                        Text(title)
                            .contentTransition(.opacity)
                            .font(.headline)
                        if let description = activity.description {
                            Text(description)
                                .contentTransition(.opacity)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}
