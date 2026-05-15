import SwiftUI

struct RunningView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var hud = HUDController()

    private let positions = ["BTN", "CO", "HJ", "MP", "UTG", "BB", "SB"]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {

                    // Header
                    HStack {
                        Button {
                            hud.stop()
                            appState.backToSetup()
                        } label: {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Text("PokerPartner HUD")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                        Circle()
                            .fill(hud.isRunning ? Color.green : Color.red)
                            .frame(width: 10, height: 10)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    // Action badge
                    ActionBadge(action: hud.suggestedAction)
                        .padding(.horizontal, 16)

                    // Data grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCell(label: "Cartas",    value: cardsText(hud.playerCards))
                        StatCell(label: "Board",     value: cardsText(hud.boardCards))
                        StatCell(label: "Equity",    value: pct(hud.equity),    color: equityColor)
                        StatCell(label: "Pot Odds",  value: pct(hud.potOdds))
                        StatCell(label: "Pote",      value: dollar(hud.pot))
                        StatCell(label: "Call",      value: dollar(hud.callAmount))
                        StatCell(label: "SPR",       value: String(format: "%.1f", hud.spr), color: sprColor)
                        StatCell(label: "Mão",       value: hud.handStrength)
                    }
                    .padding(.horizontal, 16)

                    // Draw odds row
                    HStack(spacing: 12) {
                        StatCell(label: "Flush Draw",    value: pct(hud.flushDraw))
                        StatCell(label: "Straight Draw", value: pct(hud.straightDraw))
                    }
                    .padding(.horizontal, 16)

                    // Position picker
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Posição")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Picker("Posição", selection: Binding(
                            get: { hud.position },
                            set: { hud.position = $0 }
                        )) {
                            ForEach(positions, id: \.self) { pos in
                                Text(pos).tag(pos)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.horizontal, 16)

                    // Stack input
                    HStack {
                        Text("Stack ($):")
                            .foregroundColor(.gray)
                        Spacer()
                        TextField("100", value: $appState.stack, format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 90)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: appState.stack) { hud.updateStack($0) }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
        }
        .onAppear {
            if let profile = CalibrationProfile.load() {
                hud.start(profile: profile, stack: appState.stack)
            }
        }
        .onDisappear {
            hud.stop()
        }
    }

    // MARK: - Helpers

    private var equityColor: Color {
        hud.equity >= 60 ? .green : hud.equity >= 40 ? .yellow : .red
    }

    private var sprColor: Color {
        hud.spr <= 3 ? .red : hud.spr <= 13 ? .orange : .green
    }

    private func pct(_ v: Double) -> String   { String(format: "%.1f%%", v) }
    private func dollar(_ v: Double) -> String { String(format: "$%.2f", v) }
    private func cardsText(_ cards: [Card]) -> String {
        cards.isEmpty ? "—" : cards.map { $0.displayString }.joined(separator: " ")
    }
}

// MARK: - Stat cell

private struct StatCell: View {
    let label: String
    let value: String
    var color: Color = .white

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value.isEmpty ? "—" : value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.07))
        .cornerRadius(10)
    }
}
