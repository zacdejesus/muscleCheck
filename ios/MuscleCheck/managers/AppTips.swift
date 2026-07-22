//
//  AppTips.swift
//  MuscleCheck
//
//  Onboarding is deliberately two screens; everything about HOW the app works is
//  taught here, in context, the first time each moment happens (progressive
//  disclosure). Every tip shows at most once.
//

import TipKit

/// Anchored to the check circle of the first row right after onboarding: the one
/// interaction the whole app is built around. Invalidated on the first toggle.
struct CheckActivityTip: Tip {
    var title: Text { Text("tip_check_title") }
    var message: Text? { Text("tip_check_message") }
    var options: [any TipOption] { [MaxDisplayCount(1)] }
}

/// Taught only after the user checks a gym activity for the first time — that's when
/// "you can also log the weight" becomes relevant. Anchored to the row body, whose
/// tap opens the session log.
struct LogWeightTip: Tip {
    static let didCheckGymActivity = Tips.Event(id: "didCheckGymActivity")

    var title: Text { Text("tip_weight_title") }
    var message: Text? { Text("tip_weight_message") }
    var rules: [Rule] {
        #Rule(Self.didCheckGymActivity) { $0.donations.count >= 1 }
    }
    var options: [any TipOption] { [MaxDisplayCount(1)] }
}

/// Shown inline above the list the first time a weekly reset actually clears checks —
/// the exact moment the user sees their checkmarks disappear and needs the mental
/// model ("the list starts fresh every Monday") explained.
struct WeeklyResetTip: Tip {
    static let didResetWeek = Tips.Event(id: "didResetWeek")

    var title: Text { Text("tip_reset_title") }
    var message: Text? { Text("tip_reset_message") }
    var rules: [Rule] {
        #Rule(Self.didResetWeek) { $0.donations.count >= 1 }
    }
    var options: [any TipOption] { [MaxDisplayCount(1)] }
}
