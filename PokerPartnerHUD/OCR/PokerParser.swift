import Foundation

struct PokerParser {

    // MARK: - Amount parsing (PT-BR PokerStars format)
    // Handles: "US$ 1,62"  "$ 0,03"  "$1.62"  "1,62"  "Pote: US$ 2,40"

    static func parseAmount(_ text: String) -> Double? {
        var s = text
            .replacingOccurrences(of: "US$", with: "")
            .replacingOccurrences(of: "$",   with: "")
            .replacingOccurrences(of: "Pote:", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "Call:", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespaces)

        // PT-BR uses comma as decimal and dot as thousands separator
        if s.contains(",") {
            s = s.replacingOccurrences(of: ".", with: "")   // strip thousands dot
                 .replacingOccurrences(of: ",", with: ".")  // comma → decimal
        }

        // Extract first valid number
        let pattern = #"(\d+\.?\d*)"#
        if let range = s.range(of: pattern, options: .regularExpression),
           let value = Double(String(s[range])) {
            return value
        }
        return nil
    }

    // MARK: - Card parsing
    // Handles: "[Jd Th]"  "Jd Th"  "J♥ T♠"  "Jd10h"

    static func parseCards(_ text: String) -> [Card] {
        // Normalize suit symbols to ASCII
        let normalized = text
            .replacingOccurrences(of: "♥", with: "h")
            .replacingOccurrences(of: "♦", with: "d")
            .replacingOccurrences(of: "♣", with: "c")
            .replacingOccurrences(of: "♠", with: "s")

        let pattern = #"(?i)(10|[2-9TJQKA])([hdcs])"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(normalized.startIndex..., in: normalized)
        let matches = regex.matches(in: normalized, range: range)

        return matches.compactMap { match -> Card? in
            guard
                let rankRange = Range(match.range(at: 1), in: normalized),
                let suitRange = Range(match.range(at: 2), in: normalized)
            else { return nil }
            return Card.parse(String(normalized[rankRange]) + String(normalized[suitRange]))
        }
    }
}
