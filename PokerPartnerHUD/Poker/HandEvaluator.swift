import Foundation

struct HandEvaluator {

    enum HandRank: Int, Comparable {
        case highCard = 0, onePair, twoPair, threeOfAKind
        case straight, flush, fullHouse, fourOfAKind
        case straightFlush, royalFlush

        static func < (lhs: HandRank, rhs: HandRank) -> Bool { lhs.rawValue < rhs.rawValue }

        var displayName: String {
            switch self {
            case .highCard:      return "High Card"
            case .onePair:       return "One Pair"
            case .twoPair:       return "Two Pair"
            case .threeOfAKind:  return "Three of a Kind"
            case .straight:      return "Straight"
            case .flush:         return "Flush"
            case .fullHouse:     return "Full House"
            case .fourOfAKind:   return "Four of a Kind"
            case .straightFlush: return "Straight Flush"
            case .royalFlush:    return "Royal Flush"
            }
        }
    }

    // Returns best hand from 2–7 cards
    static func evaluate(_ cards: [Card]) -> (rank: HandRank, value: Int) {
        guard cards.count >= 5 else {
            return evaluatePartial(cards)
        }
        return bestFiveCardHand(from: cards)
    }

    private static func evaluatePartial(_ cards: [Card]) -> (rank: HandRank, value: Int) {
        guard cards.count == 2 else { return (.highCard, 0) }
        if cards[0].rank == cards[1].rank {
            return (.onePair, cards[0].rank.rawValue * 100)
        }
        return (.highCard, max(cards[0].rank.rawValue, cards[1].rank.rawValue))
    }

    static func bestFiveCardHand(from cards: [Card]) -> (rank: HandRank, value: Int) {
        var best: (rank: HandRank, value: Int) = (.highCard, 0)
        for combo in combinations(of: cards, size: 5) {
            let result = evaluateFive(combo)
            if result.rank > best.rank || (result.rank == best.rank && result.value > best.value) {
                best = result
            }
        }
        return best
    }

    private static func combinations(of cards: [Card], size: Int) -> [[Card]] {
        guard size > 0, cards.count >= size else { return size == 0 ? [[]] : [] }
        if size == cards.count { return [cards] }
        var result: [[Card]] = []
        for i in 0...(cards.count - size) {
            for combo in combinations(of: Array(cards[(i + 1)...]), size: size - 1) {
                result.append([cards[i]] + combo)
            }
        }
        return result
    }

    private static func evaluateFive(_ cards: [Card]) -> (rank: HandRank, value: Int) {
        let ranks = cards.map(\.rank.rawValue).sorted(by: >)
        let suits = Set(cards.map(\.suit))
        let isFlush = suits.count == 1
        let isStraight = isStraightSeq(ranks)
        let isAceLow = isAceLowStraight(ranks)

        let groups = Dictionary(grouping: ranks, by: { $0 })
        let counts = groups.values.map(\.count).sorted(by: >)
        let highCard = ranks[0]

        if isFlush && (isStraight || isAceLow) {
            return ranks[0] == 14 && isStraight ? (.royalFlush, 9000) : (.straightFlush, 8000 + highCard)
        }
        if counts[0] == 4 { return (.fourOfAKind,   7000 + highCard) }
        if counts[0] == 3 && counts[1] == 2 { return (.fullHouse, 6000 + highCard) }
        if isFlush         { return (.flush,         5000 + highCard) }
        if isStraight || isAceLow { return (.straight, 4000 + (isAceLow ? 5 : highCard)) }
        if counts[0] == 3  { return (.threeOfAKind,  3000 + highCard) }
        if counts[0] == 2 && counts[1] == 2 { return (.twoPair, 2000 + highCard) }
        if counts[0] == 2  { return (.onePair,       1000 + highCard) }
        return (.highCard, highCard)
    }

    private static func isStraightSeq(_ sorted: [Int]) -> Bool {
        sorted.count == 5 && sorted[0] - sorted[4] == 4 && Set(sorted).count == 5
    }

    private static func isAceLowStraight(_ sorted: [Int]) -> Bool {
        Set(sorted) == Set([14, 2, 3, 4, 5])
    }
}
