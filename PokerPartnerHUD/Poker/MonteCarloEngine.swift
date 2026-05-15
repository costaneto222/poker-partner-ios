import Foundation

struct MonteCarloEngine {

    /// Returns equity 0–100 for playerHand against one random opponent.
    static func equity(playerHand: [Card], board: [Card], simulations: Int = 500) -> Double {
        guard playerHand.count == 2 else { return 0 }

        let knownCards = Set(playerHand + board)
        var deck = Card.allCards.filter { !knownCards.contains($0) }
        let boardNeeded = 5 - board.count
        guard deck.count >= boardNeeded + 2 else { return 50 }

        var wins = 0, ties = 0

        for _ in 0..<simulations {
            deck.shuffle()
            let simBoard = board + Array(deck.prefix(boardNeeded))
            let opponent = Array(deck[boardNeeded..<(boardNeeded + 2)])

            let pResult = HandEvaluator.evaluate(playerHand + simBoard)
            let oResult = HandEvaluator.evaluate(opponent + simBoard)

            if pResult.rank > oResult.rank {
                wins += 1
            } else if pResult.rank == oResult.rank && pResult.value >= oResult.value {
                pResult.value > oResult.value ? (wins += 1) : (ties += 1)
            }
        }

        return Double(wins * 2 + ties) / Double(simulations * 2) * 100.0
    }
}
