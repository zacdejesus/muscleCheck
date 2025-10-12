//
//  UserTrainingData.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 12/10/2025.
//

import FoundationModels

@Generable
struct UserTrainingReview: Identifiable, Hashable, Equatable {
  @Guide(description: "An exciting name for the review.")
  let title: String
  
  let description: String
  let review: String
  let goodPoints: String
  
  @Guide(description: "An explanation of how the itinerary meets the user's special requests.")
  let rationale: String
}
