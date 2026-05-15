import CoreVideo
import QuartzCore

/// Throttles a CVPixelBuffer stream to a target FPS, dropping frames in between.
final class FrameSampler {

    private let targetFPS: Double
    private var lastSampleTime: CFTimeInterval = 0

    var onSampledFrame: ((CVPixelBuffer) -> Void)?

    init(fps: Double = 1.0) {
        self.targetFPS = fps
    }

    func process(_ pixelBuffer: CVPixelBuffer) {
        let now = CACurrentMediaTime()
        guard now - lastSampleTime >= 1.0 / targetFPS else { return }
        lastSampleTime = now
        onSampledFrame?(pixelBuffer)
    }
}
