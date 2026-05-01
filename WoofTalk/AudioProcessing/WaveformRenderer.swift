import AVFoundation
import CoreGraphics

/// Renders audio waveform visualization for recording/playback feedback
final class WaveformRenderer {
    private let samplesPerPixel: Int

    init(samplesPerPixel: Int = 256) {
        self.samplesPerPixel = samplesPerPixel
    }

    /// Render waveform as CGImage from audio buffer
    func renderWaveform(from buffer: AVAudioPCMBuffer, size: CGSize, color: CGColor) -> CGImage? {
        guard let floatData = buffer.floatChannelData else { return nil }
        let frameCount = Int(buffer.frameLength)
        let samples = floatData[0]

        let width = Int(size.width)
        let height = Int(size.height)
        let midY = height / 2

        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )

        context?.setFillColor(CGColor(gray: 0, alpha: 0))
        context?.fill(CGRect(origin: .zero, size: size))

        context?.setStrokeColor(color)
        context?.setLineWidth(1.0)

        let pixelsPerSample = Double(width) / Double(frameCount)
        context?.beginPath()

        for x in 0..<width {
            let sampleIndex = Int(Double(x) / pixelsPerSample)
            guard sampleIndex < frameCount else { break }
            let sample = samples[sampleIndex]
            let y = midY + Int(sample * Float(midY))
            if x == 0 {
                context?.move(to: CGPoint(x: x, y: y))
            } else {
                context?.addLine(to: CGPoint(x: x, y: y))
            }
        }

        context?.strokePath()
        return context?.makeImage()
    }

    /// Extract normalized sample values for custom drawing
    func extractSamples(from buffer: AVAudioPCMBuffer, maxSamples: Int = 100) -> [Float] {
        guard let floatData = buffer.floatChannelData else { return [] }
        let frameCount = Int(buffer.frameLength)
        let samples = floatData[0]

        let step = max(1, frameCount / maxSamples)
        var result: [Float] = []
        for i in stride(from: 0, to: frameCount, by: step) {
            if result.count >= maxSamples { break }
            result.append(abs(samples[i]))
        }
        return result
    }

    /// Generate waveform path for given buffer
    func waveformPath(from buffer: AVAudioPCMBuffer, bounds: CGRect) -> CGPath {
        let path = CGMutablePath()
        let samples = extractSamples(from: buffer, maxSamples: Int(bounds.width))
        guard !samples.isEmpty else { return path }

        let midY = bounds.midY
        let maxHeight = bounds.height / 2

        for (i, sample) in samples.enumerated() {
            let x = bounds.minX + CGFloat(i) * bounds.width / CGFloat(samples.count)
            let y = midY + CGFloat(sample) * maxHeight
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        return path
    }
}
