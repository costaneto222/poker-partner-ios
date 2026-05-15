import Foundation

struct PokerLogic {

    enum Action: String {
        case raise = "RAISE"
        case call  = "CALL"
        case fold  = "FOLD"
    }

    static func potOdds(pot: Double, call: Double) -> Double {
        guard call > 0 else { return 0 }
        return (call / (pot + call)) * 100
    }

    static func spr(stack: Double, pot: Double) -> Double {
        guard pot > 0 else { return 0 }
        return stack / pot
    }

    static func suggestAction(equity: Double, potOdds: Double, isPreflop: Bool, position: String) -> Action {
        let posBonus: Double
        switch position {
        case "BTN": posBonus =  8
        case "CO":  posBonus =  5
        case "HJ":  posBonus =  3
        case "BB":  posBonus = -3
        case "SB", "UTG": posBonus = -5
        default:    posBonus =  0
        }
        let adj = equity + posBonus

        if isPreflop {
            if adj >= 62 { return .raise }
            if adj >= 40 { return .call  }
            return .fold
        }
        if adj >= potOdds + 15 { return .raise }
        if adj >= potOdds       { return .call  }
        return .fold
    }

    static func drawOdds(playerHand: [Card], board: [Card]) -> (flush: Double, straight: Double) {
        guard board.count >= 3 else { return (0, 0) }
        let all = playerHand + board
        let suitCounts = Dictionary(grouping: all.map(\.suit), by: { $0 }).mapValues(\.count)
        let flushDraw = suitCounts.values.contains(4) ? 35.0 : 0.0

        let ranks = Set(all.map(\.rank.rawValue)).sorted()
        var maxRun = 1, run = 1
        for i in 1..<ranks.count {
            run = ranks[i] - ranks[i - 1] == 1 ? run + 1 : 1
            maxRun = max(maxRun, run)
        }
        let straightDraw = maxRun >= 4 ? 32.0 : 0.0
        return (flushDraw, straightDraw)
    }
}
