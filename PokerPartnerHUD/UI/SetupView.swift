import SwiftUI

struct SetupView: View {
    @EnvironmentObject var appState: AppState

    private var hasSavedProfile: Bool { CalibrationProfile.load() != nil }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                Image(systemName: "suit.spade.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.white)

                VStack(spacing: 6) {
                    Text("PokerPartner HUD")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("Aponte o iPhone para a tela do PokerStars")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }

                // Stack input
                HStack {
                    Text("Seu Stack ($):")
                        .foregroundColor(.gray)
                    Spacer()
                    TextField("100", value: $appState.stack, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 90)
                        .multilineTextAlignment(.trailing)
                }
                .padding(.horizontal, 32)

                VStack(spacing: 12) {
                    Button {
                        if hasSavedProfile {
                            appState.startRunning()
                        } else {
                            appState.startCalibration()
                        }
                    } label: {
                        Label(
                            hasSavedProfile ? "Iniciar HUD" : "Calibrar e Iniciar",
                            systemImage: hasSavedProfile ? "play.fill" : "camera.viewfinder"
                        )
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .font(.headline)
                    }

                    if hasSavedProfile {
                        Button {
                            CalibrationProfile.clear()
                            appState.startCalibration()
                        } label: {
                            Label("Recalibrar", systemImage: "arrow.clockwise")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, 32)

                Spacer()

                Text("Team ID 5EUJQUFBHT • com.costa.pokerpartner")
                    .font(.caption2)
                    .foregroundColor(.gray.opacity(0.5))
                    .padding(.bottom, 8)
            }
        }
    }
}
