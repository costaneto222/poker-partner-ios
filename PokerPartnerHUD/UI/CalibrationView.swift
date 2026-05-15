import SwiftUI

struct CalibrationView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var camera = CameraController()
    @StateObject private var engine = CalibrationEngine()

    var body: some View {
        ZStack {
            // Camera preview fills screen
            CameraPreviewView(session: camera.session)
                .ignoresSafeArea()

            // Colored overlay boxes for detected elements
            GeometryReader { geo in
                ForEach(engine.elements) { element in
                    overlayBox(element, size: geo.size)
                }
            }

            // Top instruction banner
            VStack {
                Text(engine.elements.isEmpty
                     ? "🔍 Jogue uma mão — detectando elementos..."
                     : "✅ \(engine.elements.count) elemento(s) detectado(s)")
                    .font(.callout)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.75))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.top, 60)
                Spacer()
            }

            // Detected element labels
            VStack {
                Spacer()
                VStack(spacing: 4) {
                    ForEach(engine.elements) { elem in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(colorFor(elem.kind))
                                .frame(width: 8, height: 8)
                            Text(labelFor(elem))
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(6)
                    }
                }
                .padding(.bottom, 12)

                // Action buttons
                HStack(spacing: 12) {
                    Button("Cancelar") {
                        appState.backToSetup()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .font(.headline)

                    Button("Confirmar") {
                        if let profile = engine.buildProfile() {
                            profile.save()
                            appState.startRunning()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(engine.elements.isEmpty ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .font(.headline)
                    .disabled(engine.elements.isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 36)
            }
        }
        .onAppear {
            camera.onFrame = { [weak engine] buffer in engine?.onFrame(buffer) }
            camera.start()
        }
        .onDisappear {
            camera.stop()
        }
    }

    // MARK: - Overlay box

    @ViewBuilder
    private func overlayBox(_ element: CalibrationEngine.DetectedElement, size: CGSize) -> some View {
        let x = element.box.x * size.width
        let y = element.box.y * size.height
        let w = element.box.width  * size.width
        let h = element.box.height * size.height

        ZStack(alignment: .topLeading) {
            Rectangle()
                .stroke(colorFor(element.kind), lineWidth: 2)
                .frame(width: w, height: h)
                .position(x: x + w / 2, y: y + h / 2)

            Text(kindShortLabel(element.kind))
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.black)
                .padding(.horizontal, 3)
                .background(colorFor(element.kind))
                .cornerRadius(2)
                .position(x: x + 20, y: y - 6)
        }
    }

    // MARK: - Helpers

    private func colorFor(_ kind: CalibrationEngine.ElementKind) -> Color {
        switch kind {
        case .pot:         return .yellow
        case .call:        return .cyan
        case .playerCards: return .green
        case .board:       return .orange
        }
    }

    private func kindShortLabel(_ kind: CalibrationEngine.ElementKind) -> String {
        switch kind {
        case .pot:         return "POT"
        case .call:        return "CALL"
        case .playerCards: return "CARDS"
        case .board:       return "BOARD"
        }
    }

    private func labelFor(_ elem: CalibrationEngine.DetectedElement) -> String {
        "\(kindShortLabel(elem.kind)): \(elem.text)"
    }
}
