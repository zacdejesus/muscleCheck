//
//  TrainingReviewGenerator.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 12/10/2025.
//

import Observation

@Observable
@MainActor
final class ItineraryGenerator {
    
    var error: Error?
    let landmark: Landmark
    private(set) var review: UserTrainingReview.PartiallyGenerated?
    let instructions = """
      Your job is to create an review for the user.
      calculate if the user if doing the correct amount and excercise for their goal in the gym.

      Always include a title, a short description, and a day-by-day plan.
      """
  
    session = LanguageModelSession(instructions: instructions)

    init(landmark: Landmark) {
        self.landmark = landmark

               
    }

    func generateItinerary(dayCount: Int = 3) async {
      let stream = session.streamResponse(to: prompt,
                                          generating: Itinerary.self)
      for try await partialResponse in stream {
          self.review = partialResponse.content
      }
         
    }

    func prewarmModel() {
        // MARK: - [CODE-ALONG] Chapter 6.1.1: Add a function to pre-warm the model
    }
}
