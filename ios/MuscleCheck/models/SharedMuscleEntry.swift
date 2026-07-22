//
//  SharedMuscleEntry.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 21/10/2025.
//


struct SharedMuscleEntry: Codable, Hashable {
    let name: String
    let isChecked: Bool
    let icon: String

    init(name: String, isChecked: Bool, icon: String = "figure.strengthtraining.traditional") {
        self.name = name
        self.isChecked = isChecked
        self.icon = icon
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        isChecked = try container.decode(Bool.self, forKey: .isChecked)
        icon = try container.decodeIfPresent(String.self, forKey: .icon) ?? "figure.strengthtraining.traditional"
    }
}
