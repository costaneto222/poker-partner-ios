import Foundation
import Vision
import CoreVideo

final class OCREngine {

    struct RecognitionResult {
        var pot: Double?
        var call: Double?
        var playerCards: [Card]
        var boardCards: [Card]
    }

    /// Synchronous — must be called from a background queue.
    func recognize(pixelBuffer: CVPixelBuffer, profile: CalibrationProfile) -> RecognitionResult {
        var result = RecognitionResult(playerCards: [], boardCards: [])

        if let region = profile.pot {
            let text = recognizeText(in: pixelBuffer, uiRegion: region.cgRect)
            result.pot = PokerParser.parseAmount(text)
        }
        if let region = profile.call {
            let text = recognizeText(in: pixelBuffer, uiRegion: region.cgRect)
            result.call = PokerParser.parseAmount(text)
        }
        if let region = profile.playerCards {
            let text = recognizeText(in: pixelBuffer, uiRegion: region.cgRect)
            result.playerCards = PokerParser.parseCards(text)
        }
        if let region = profile.board {
            let text = recognizeText(in: pixelBuffer, uiRegion: region.cgRect)
            result.boardCards = PokerParser.parseCards(text)
        }
        return result
    }

    // MARK: - Private

    /// regionOfInterest in Vision uses bottom-left origin; our profiles use top-left.
    private func recognizeText(in pixelBuffer: CVPixelBuffer, uiRegion: CGRect) -> String {
        // Flip Y: Vision origin is bottom-left
        let visionRegion = CGRect(
            x: uiRegion.minX,
            y: 1.0 - uiRegion.maxY,
            width: uiRegion.width,
            height: uiRegion.height
        )

        var recognized = ""

        let request = VNRecognizeTextRequest { req, _ in
            recognized = (req.results as? [VNRecognizedTextObservation])?
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: " ") ?? ""
        }
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["pt-BR", "en-US"]
        request.usesLanguageCorrection = false
        request.regionOfInterest = visionRegion

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])

        return recognized
    }
}
