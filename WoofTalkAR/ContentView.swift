import SwiftUI
import RealityKit
import ARKit

struct ContentView: View {
    @StateObject private var arViewModel = ARViewModel()
    @StateObject private var detectionManager = DetectionStateManager()

    var body: some View {
        ZStack {
            ARContainerView()
                .edgesIgnoringSafeArea(.all)

            // Debug HUD
            VStack {
                Text("Detection: \(detectionManager.lastClassification?.className ?? "none")")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                if let confidence = detectionManager.lastClassification?.confidence {
                    ProgressView(value: confidence, total: 1.0)
                        .frame(width: 200)
                }
                Spacer()
            }
            .padding(.top, 50)
        }
        .onAppear {
            arViewModel.start()
            detectionManager.start()
        }
        .onDisappear {
            detectionManager.stop()
            arViewModel.stop()
        }
    }
}

class ARViewModel: ObservableObject {
    @Published var isARReady = false
    private let coordinator = ARCoordinator.shared
    private var arView: ARView?

    func start() {
        NotificationCenter.default.addObserver(
            forName: .arViewReady,
            object: nil,
            queue: .main
        ) { notification in
            if let view = notification.object as? ARView {
                self.arView = view
                self.coordinator.setARView(view)
                self.isARReady = true
                print("ARCoordinator received ARView")
            }
        }
    }

    func stop() {
        coordinator.dismissAllBubbles()
        arView = nil
    }
}

struct ARContainerView: UIViewRepresentable {
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.session.run(WorldTrackingConfiguration())
        NotificationCenter.default.post(name: .arViewReady, object: arView)
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
}

// MARK: - DetectionStateManager with Translation Trigger

class DetectionStateManager: ObservableObject {
    @Published var lastClassification: BarkClassification?
    private var detector: BarkDetector?
    private let translationService = TranslationService.shared
    private let coordinator = ARCoordinator.shared
    private let spatialAudio = SpatialAudioController.shared

    init() {
        self.detector = BarkDetector.shared
        self.detector?.delegate = self
    }

    func start() {
        Task {
            do {
                try await detector?.start()
            } catch {
                print("Failed to start detector: \(error)")
            }
        }
    }

    func stop() {
        detector?.stop()
    }

    private func handleBarkDetection(_ classification: BarkClassification) {
        Task { @MainActor in
            self.lastClassification = classification
            print("Detected: \(classification.className) confidence: \(classification.confidence)")

            // Call translation Edge Function
            translationService.translate(
                humanText: "[Translated from \(classification.className)]",
                animalText: classification.className,
                confidence: classification.confidence
            ) { result in
                switch result {
                case .success(let record):
                    print("Translation received: \(record.human_text)")
                    // Show bubble with translation
                    self.coordinator.showBubble(text: record.human_text)

                    // Play spatial audio from bubble position (approximate 2m in front)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if let arView = self.coordinator.arView,
                           let cameraTransform = arView.session.currentFrame?.camera.transform {
                            let forward = SIMD3<Float>(
                                cameraTransform.columns.2.x,
                                cameraTransform.columns.2.y,
                                cameraTransform.columns.2.z
                            )
                            let cameraPos = SIMD3<Float>(
                                cameraTransform.columns.3.x,
                                cameraTransform.columns.3.y,
                                cameraTransform.columns.3.z
                            )
                            let bubblePosition = cameraPos + forward * 2.0
                            self.spatialAudio.playAudio(at: bubblePosition, soundFile: nil)
                        }
                    }

                case .failure(let error):
                    print("Translation error: \(error.localizedDescription)")
                }
            }
        }
    }
}

extension DetectionStateManager: BarkDetectorDelegate {
    nonisolated func barkDetector(_ detector: BarkDetector, didDetect classification: BarkClassification) {
        handleBarkDetection(classification)
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let arViewReady = Notification.Name("ARViewReady")
}
