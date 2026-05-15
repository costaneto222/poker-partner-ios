import Foundation

/// Wires CameraController → FrameSampler → OCREngine → Poker calculations.
/// Lives as a @StateObject inside RunningView.
final class HUDController: ObservableObject {

    // MARK: - Published state (consumed by RunningView)

    @Published var pot:           Double = 0
    @Published var callAmount:    Double = 0
    @Published var playerCards:   [Card] = []
    @Published var boardCards:    [Card] = []
    @Published var equity:        Double = 0
    @Published var potOdds:       Double = 0
    @Published var spr:           Double = 0
    @Published var suggestedAction: PokerLogic.Action = .fold
    @Published var handStrength:  String = ""
    @Published var flushDraw:     Double = 0
    @Published var straightDraw:  Double = 0
    @Published var isRunning:     Bool   = false
    @Published var position:      String = "MP"

    // MARK: - Private

    private let camera    = CameraController()
    private let sampler   = FrameSampler(fps: 1.0)
    private let ocr       = OCREngine()
    private let calcQueue = DispatchQueue(label: "hud.calc", qos: .userInitiated)
    private var stack: Double = 100

    // MARK: - Lifecycle

    func start(profile: CalibrationProfile, stack: Double) {
        self.stack = stack

        camera.onFrame = { [weak self] buffer in
            self?.sampler.process(buffer)
        }
        sampler.onSampledFrame = { [weak self] buffer in
            guard let self else { return }
            self.calcQueue.async {
                let result = self.ocr.recognize(pixelBuffer: buffer, profile: profile)
                self.applyResult(result)
            }
        }

        camera.start()
        DispatchQueue.main.async { self.isRunning = true }
    }

    func stop() {
        camera.stop()
        isRunning = false
    }

    func updateStack(_ value: Double) {
        stack = value
    }

    // MARK: - Apply OCR result + compute poker metrics

    private func applyResult(_ result: OCREngine.RecognitionResult) {
        let newPot   = result.pot          ?? pot
        let newCall  = result.call         ?? callAmount
        let newCards = result.playerCards.isEmpty ? playerCards : result.playerCards
        let newBoard = result.boardCards.isEmpty  ? boardCards  : result.boardCards
        let pos      = position

        let equity     = newCards.isEmpty ? 0.0 : MonteCarloEngine.equity(playerHand: newCards, board: newBoard)
        let potOddsVal = PokerLogic.potOdds(pot: newPot, call: newCall)
        let sprVal     = PokerLogic.spr(stack: stack, pot: newPot)
        let action     = PokerLogic.suggestAction(equity: equity, potOdds: potOddsVal,
                                                  isPreflop: newBoard.isEmpty, position: pos)
        let draws      = PokerLogic.drawOdds(playerHand: newCards, board: newBoard)
        let (rankEnum, _) = HandEvaluator.evaluate(newCards + newBoard)

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.pot           = newPot
            self.callAmount    = newCall
            self.playerCards   = newCards
            self.boardCards    = newBoard
            self.equity        = equity
            self.potOdds       = potOddsVal
            self.spr           = sprVal
            self.suggestedAction = action
            self.handStrength  = newCards.isEmpty ? "" : rankEnum.displayName
            self.flushDraw     = draws.flush
            self.straightDraw  = draws.straight
        }
    }
}
