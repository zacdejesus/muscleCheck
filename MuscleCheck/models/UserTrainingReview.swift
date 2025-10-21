//
//  UserTrainingData.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 12/10/2025.
//

import FoundationModels

@Generable
struct UserTrainingReview: Hashable, Equatable {
  @Guide(description: "El grupo muscular principal recomendado y la razon por la cual se recomienda.")
  var musculo: String
}
