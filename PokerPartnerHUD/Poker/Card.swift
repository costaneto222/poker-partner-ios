import Foundation

struct Card: Equatable, Hashable {

    enum Rank: Int, CaseIterable, Comparable {
        case two = 2, three, four, five, six, seven, eight, nine, ten
        case jack = 11, queen = 12, king = 13, ace = 14

        static func < (lhs: Rank, rhs: Rank) -> Bool { lhs.rawValue < rhs.rawValue }

        static func from(_ string: String) -> Rank? {
            switch string.uppercased() {
            case "2": return .two
            case "3": return .three
            case "4": return .four
            case "5": return .five
            case "6": return .six
            case "7": return .seven
            case "8": return .eight
            case "9": return .nine
            case "T", "10": return .ten
            case "J": return .jack
            case "Q": return .queen
            case "K": return .king
            case "A": return .ace
            default: return nil
            }
        }

        var shortName: String {
            switch self {
            case .ten: return "T"
            case .jack: return "J"
            case .queen: return "Q"
            case .king: return "K"
            case .ace: return "A"
            default: return "\(rawValue)"
            }
        }
    }

    enum Suit: String, CaseIterable {
        case hearts = "h", diamonds = "d", clubs = "c", spades = "s"

        var symbol: String {
            switch self {
            case .hearts: return "♥"
            case .diamonds: return "♦"
            case .clubs: return "♣"
            case .spades: return "♠"
            }
        }

        static func from(_ char: Character) -> Suit? {
            Suit(rawValue: String(char).lowercased())
        }
    }

    let rank: Rank
    let suit: Suit

    var displayString: String { "\(rank.shortName)\(suit.symbol)" }

    static func parse(_ string: String) -> Card? {
        let s = string.trimmingCharacters(in: .whitespaces)
        guard s.count >= 2 else { return nil }
        let suitChar = s[s.index(before: s.endIndex)]
        let rankStr = String(s.dropLast())
        guard let rank = Rank.from(rankStr), let suit = Suit.from(suitChar) else { return nil }
        return Card(rank: rank, suit: suit)
    }

    static var allCards: [Card] {
        Rank.allCases.flatMap { rank in Suit.allCases.map { Card(rank: rank, suit: $0) } }
    }
}
