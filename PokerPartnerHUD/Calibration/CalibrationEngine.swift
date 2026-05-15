import Foundation
import Vision
import CoreVideo

/// Scans full camera frames looking for poker UI elements (pot, call, cards).
final class CalibrationEngine: ObservableObject {

    // MARK: - Types

    enum ElementKind: CaseIterable {
        case pot, call, playerCards, board
    }

    struct DetectedElement: Identifiable {
        let id = UUID()
        var kind: ElementKind
        var box: RegionBox
        var text: String
        var confidence: Double
    }

    // MARK: - Published state

    @Published var elements: [DetectedElement] = []
    @Published var isScanning = false

    // MARK: - Private

    private let sampler = FrameSampler(fps: 1.0)
    private let queue = DispatchQueue(label: "calibration.engine", qos: .userInitiated)

    init() {
        sampler.onSampledFrame = { [weak self] buffer in
            self?.processFrame(buffer)
        }
    }

    // MARK: - Interface

    func onFrame(_ buffer: CVPixelBuffer) {
        sampler.process(buffer)
    }

    func buildProfile() -> CalibrationProfile? {
        let byKind: (ElementKind) -> RegionBox? = { kind in
            self.elements.filter { $0.kind == kind }
                         .max(by: { $0.confidence < $1.confidence })?.box
        }
        let profile = CalibrationProfile(
            pot:         byKind(.pot),
            call:        byKind(.call),
            playerCards: byKind(.playerCards),
            board:       byKind(.board),
            createdAt:   Date()
        )
        return profile.isComplete ? profile : nil
    }

    // MARK: - Frame processing

    private func processFrame(_ pixelBuffer: CVPixelBuffer) {
        guard !isScanning else { return }
        DispatchQueue.main.async { self.isScanning = true }

        queue.async { [weak self] in
            guard let self else { return }
            let request = VNRecognizeTextRequest { [weak self] req, _ in
                let observations = (req.results as? [VNRecognizedTextObservation]) ?? []
                self?.analyze(observations)
            }
            request.recognitionLevel = .fast
            request.recognitionLanguages = ["pt-BR", "en-US"]
            request.usesLanguageCorrection = false

            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            try? handler.perform([request])
        }
    }

    private func analyze(_ observations: [VNRecognizedTextObservation]) {
        var found: [DetectedElement] = []

        for obs in observations {
            guard let candidate = obs.topCandidates(1).first else { continue }
            let text  = candidate.string
            let conf  = Double(candidate.confidence)

            // Vision bounding box: origin bottom-left → flip to top-left
            let vb = obs.boundingBox
            let box = RegionBox(x: vb.minX, y: 1 - vb.maxY,
                                width: vb.width, height: vb.height,
                                confidence: conf)

            if let kind = classify(text) {
                found.append(DetectedElement(kind: kind, box: box, text: text, confidence: conf))
            }
        }

        // Keep highest-confidence detection per kind
        var best: [ElementKind: DetectedElement] = [:]
        for elem in found {
            if let existing = best[elem.kind] {
                if elem.confidence > existing.confidence { best[elem.kind] = elem }
            } else {
                best[elem.kind] = elem
            }
        }

        let merged = Array(best.values)
        DispatchQueue.main.async { [weak self] in
            if !merged.isEmpty {
                self?.elements = merged
            }
            self?.isScanning = false
        }
    }

    // MARK: - Classification

    private func classify(_ text: String) -> ElementKind? {
        let lower = text.lowercased()

        if (lower.contains("pot") || lower.contains("pote") || lower.hasPrefix("$") || lower.contains("us$"))
            && hasNumber(text) {
            return .pot
        }
        if (lower.contains("call") || lower.contains("igualar") || lower.contains("pagar"))
            && hasNumber(text) {
            return .call
        }
        let cardCount = countCards(in: text)
        if cardCount == 2 { return .playerCards }
        if cardCount >= 3 { return .board }
        return nil
    }

    private func hasNumber(_ text: String) -> Bool {
        text.range(of: #"\d"#, options: .regularExpression) != nil
    }

    private func countCards(in text: String) -> Int {
        guard let regex = try? NSRegularExpression(pattern: #"(?i)[2-9TJQKA][hdcs]"#) else { return 0 }
        return regex.numberOfMatches(in: text, range: NSRange(text.startIndex..., in: text))
    }
}
