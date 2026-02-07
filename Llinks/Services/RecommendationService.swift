//
//  RecommendationService.swift
//  Llinks
//

import Foundation

enum RecommendationService {

    static func calculateMatchScore(
        myLearn: [String], myTeach: [String], myLocation: String,
        other: UserSummary
    ) -> Int {
        let myLearnSet = Set(myLearn.map { $0.lowercased() })
        let myTeachSet = Set(myTeach.map { $0.lowercased() })
        let theirTeachSet = Set(other.teachSkills.map { $0.lowercased() })
        let theirLearnSet = Set(other.learnSkills.map { $0.lowercased() })

        let teachOverlap = myLearnSet.intersection(theirTeachSet).count
        let learnOverlap = myTeachSet.intersection(theirLearnSet).count

        var score = min(teachOverlap, 3) * 17  // max 51 from 3 skills
        score += min(learnOverlap, 3) * 10      // max 30 from 3 skills
        if locationMatches(myLocation, other.location) { score += 10 }
        if !other.bio.isEmpty && !other.teachSkills.isEmpty { score += 5 }
        // bonus for bidirectional match
        if teachOverlap > 0 && learnOverlap > 0 { score += 4 }

        return min(score, 100)
    }

    static func buildReasons(
        myLearn: [String], myTeach: [String], myLocation: String,
        other: UserSummary
    ) -> [String] {
        var result: [String] = []

        let myLearnSet = Set(myLearn.map { $0.lowercased() })
        let theirTeachSet = Set(other.teachSkills.map { $0.lowercased() })
        let teachMatch = other.teachSkills.filter { myLearnSet.contains($0.lowercased()) }
        if !teachMatch.isEmpty {
            result.append("Учит \(teachMatch.prefix(2).joined(separator: ", ")) — вам нужно")
        }

        let myTeachSet = Set(myTeach.map { $0.lowercased() })
        let theirLearnSet = Set(other.learnSkills.map { $0.lowercased() })
        let learnMatch = other.learnSkills.filter { myTeachSet.contains($0.lowercased()) }
        if !learnMatch.isEmpty {
            result.append("Ищет \(learnMatch.prefix(2).joined(separator: ", ")) — вы умеете")
        }

        if locationMatches(myLocation, other.location) {
            result.append("Рядом с вами: \(other.location)")
        }

        return Array(result.prefix(3))
    }

    private static func locationMatches(_ a: String, _ b: String) -> Bool {
        guard !a.isEmpty, !b.isEmpty else { return false }
        let la = a.lowercased(), lb = b.lowercased()
        return la.contains(lb) || lb.contains(la)
    }
}
