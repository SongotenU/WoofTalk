import Foundation
import Vision
import CoreML
import AVFoundation

actor BarkDetector {
    static let shared = BarkDetector()
    private var audioRecorder: AudioRecorder?
    private var classificationRequest: VNCoreMLRequest?
    private let confidenceThreshold: Float = 0.7
    private let debounceInterval: TimeInterval = 1.0
    private var lastClassificationDate = Date.distantPast

    weak var delegate: BarkDetectorDelegate?

    private init() {
        setupModel()
        setupAudio()
    }

    private func setupModel() {
        guard let modelURL = Bundle.main.url(forResource: "DogBarkClassifier", withExtension: "mlmodel") else {
            print("ERROR: DogBarkClassifier.mlmodel not found in bundle")
            return
        }

        do {
            let model = try VNCoreMLModel(
                for: MLModel(contentsOf: modelURL)
            )
            classificationRequest = VNCoreMLRequest(model: model) { [weak self] request, error in
                if let error = error {
                    print("Classification error: \(error)")
                    return
                }
                self?.handleClassification(request: request)
            }
            classificationRequest?.imageCropAndScaleOption = .scaleCropToFill
            print("Model loaded successfully from \(modelURL.lastPathComponent)")
        } catch {
            print("Failed to load model: \(error)")
        }
    }

    private func setupAudio() {
        audioRecorder = AudioRecorder.shared
        audioRecorder?.delegate = nil

        NotificationCenter.default.addObserver(
            forName: .audioBufferCaptured,
            object: audioRecorder,
            queue: .global(qos: .userInitiated)
        ) { [weak self] notification in
            self?.processAudioBuffer(notification)
        }
    }

    func start() throws {
        try audioRecorder?.start()
        print("BarkDetector started")
    }

    func stop() {
        audioRecorder?.stop()
    }

    private nonisolated func processAudioBuffer(_ notification: Notification) {
        guard let buffer = notification.userInfo?["buffer"] as? AVAudioPCMBuffer,
              let request = classificationRequest else { return }

        // Convert AVAudioPCMBuffer to MLMultiArray
        guard let multiArray = buffer.toMultiArray() else {
            print("Failed to convert buffer to MLMultiArray")
            return
        }

        // Convert MLMultiArray to CVPixelBuffer (Vision expects image-like input)
        guard let pixelBuffer = multiArray.toCVPixelBuffer() else {
            print("Failed to convert MLMultiArray to CVPixelBuffer")
            return
        }

        do {
            try VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
        } catch {
            print("VN request failed: \(error)")
        }
    }

    private func handleClassification(request: VNRequest) {
        guard let results = request.results as? [VNClassificationObservation],
              let top = results.first else { return }

        let className = mapClassLabel(top.identifier)
        let confidence = top.confidence

        let classification = BarkClassification(
            timestamp: Date(),
            className: className,
            confidence: confidence
        )

        // Debounce
        let now = Date()
        guard now.timeIntervalSince(lastClassificationDate) > debounceInterval else { return }
        lastClassificationDate = now

        if classification.isDogSound {
            Task { @MainActor in
                delegate?.barkDetector(self, didDetect: classification)
            }
        }
    }

    private func mapClassLabel(_ identifier: String) -> String {
        let lowercased = identifier.lowercased()
        if lowercased.contains("bark") { return "bark" }
        if lowercased.contains("howl") { return "howl" }
        if lowercased.contains("whine") { return "whine" }
        return "silence"
    }
}

protocol BarkDetectorDelegate: AnyObject {
    func barkDetector(_ detector: BarkDetector, didDetect classification: BarkClassification)
}

// MARK: - AVAudioPCMBuffer extensions for conversion

extension AVAudioPCMBuffer {
    func toMultiArray() -> MLMultiArray? {
        guard let channelData = self.floatChannelData?.pointee else { return nil }
        let frameLength = Int(self.frameLength)
        let channelDataArray = Array(UnsafeBufferPointer(start: channelData, count: frameLength))

        do {
            // Shape: [1, 1024] - batch dim 1, 1024 samples
            let multiArray = try MLMultiArray(
                shape: [1, 1024] as [NSNumber],
                dataType: .float32
            )
            for (i, value) in channelDataArray.enumerated() where i < 1024 {
                multiArray[i] = value as NSNumber
            }
            return multiArray
        } catch {
            print("Failed to create MLMultiArray: \(error)")
            return nil
        }
    }
}

extension MLMultiArray {
    func toCVPixelBuffer() -> CVPixelBuffer? {
        // Convert 1D float array to 2D image-like pixel buffer for Vision
        // Shape: [1, 1024] -> [1, 1024] single-channel image
        let width = 1
        let height = 1024

        var pixelBuffer: CVPixelBuffer?
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ] as CFDictionary

        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32ARGB,
            attrs,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            print("Failed to create CVPixelBuffer: status \(status)")
            return nil
        }

        // Copy data from MLMultiArray to pixel buffer (simplified - single channel)
        CVPixelBufferLockBaseAddress(buffer, [])
        if let baseAddress = CVPixelBufferGetBaseAddress(buffer) {
            let bufferPointer = baseAddress.assumingMemoryBound(to: UInt8.self)
            for i in 0..<min(1024, Int(self.count)) {
                let floatVal = self[i].floatValue
                let byteVal = UInt8(max(0, min(255, floatVal * 127 + 128)))
                // ARGB format: fill all channels with same value for grayscale
                bufferPointer[i * 4] = byteVal     // A
                bufferPointer[i * 4 + 1] = byteVal // R
                bufferPointer[i * 4 + 2] = byteVal // G
                bufferPointer[i * 4 + 3] = byteVal // B
            }
        }
        CVPixelBufferUnlockBaseAddress(buffer, [])

        return buffer
    }
}
