import SwiftUI

struct ActionBadge: View {
    let action: PokerLogic.Action

    var body: some View {
        Text(action.rawValue.uppercased())
            .font(.system(size: 36, weight: .black))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(badgeColor)
            .foregroundColor(.white)
            .cornerRadius(14)
    }

    private var badgeColor: Color {
        switch action {
        case .raise: return Color(hex: "4CAF50")
        case .call:  return Color(hex: "FFC107")
        case .fold:  return Color(hex: "F44336")
        }
    }
}

// MARK: - Color(hex:) extension

extension Color {
    init(hex: String) {
        var hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hex.hasPrefix("#") { hex.removeFirst() }
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8)  & 0xFF) / 255
        let b = Double( value        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
