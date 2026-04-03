import Foundation
import RealityKit
import ARKit

actor ARCoordinator {
    static let shared = ARCoordinator()
    private var arView: ARView?
    private var activeBubbles: [TranslationBubble] = []
    private var pinnedBubbles: Set<TranslationBubble> = []
    private let maxActiveBubbles = 3
    private let autoDismissTime: TimeInterval = 10.0

    // FPS monitoring for performance tuning
    private var lastFrameTime: Date = Date()
    private var frameCount: Int = 0
    private var fpsLogInterval: TimeInterval = 5.0 // Log every 5 seconds

    private init() {}

    // MARK: - Pinning

    /// Pin a bubble to prevent auto-dismiss and eviction
    func pinBubble(_ bubble: TranslationBubble) {
        pinnedBubbles.insert(bubble)
        // Could also log or notify UI
        print("📌 Bubble pinned")
    }

    /// Unpin a bubble (allows normal lifecycle)
    func unpinBubble(_ bubble: TranslationBubble) {
        pinnedBubbles.remove(bubble)
        print("📌 Bubble unpinned")
    }

    /// Check if a bubble is pinned
    func isPinned(_ bubble: TranslationBubble) -> Bool {
        return pinnedBubbles.contains(bubble)
    }

    func setARView(_ view: ARView) {
        self.arView = view
        // Setup gesture handling
        GestureHandler.shared.setupGestures(on: view)
    }

    func showBubble(text: String, duration: TimeInterval? = nil) {
        guard let arView = arView else {
            print("ERROR: ARView not set in ARCoordinator")
            return
        }

        // Evict oldest bubble if at capacity (FIFO), but skip pinned bubbles
        if activeBubbles.count >= maxActiveBubbles {
            // Find the oldest bubble that is NOT pinned
            if let evictIndex = activeBubbles.firstIndex(where: { !$0.isPinned }) {
                let evicted = activeBubbles.remove(at: evictIndex)
                arView.removeTranslationBubble(evicted)
            } else {
                // All bubbles are pinned — cannot add new one
                print("⚠️ All bubbles pinned, skipping new bubble")
                return
            }
        }

        // Create bubble with dismiss callback
        let bubble = TranslationBubble(text: text) { [weak self] in
            self?.dismissBubble(bubble)
        }

        // Position bubble using ARPlacementEngine
        if let cameraTransform = arView.session.currentFrame?.camera.transform {
            let placementResult = ARPlacementEngine.shared.placeBubble(
                text: text,
                from: cameraTransform,
                in: arView
            )

            if let result = placementResult {
                bubble.entity.position = result.position
                // Configure bubble appearance for this distance
                bubble.configureForDistance(result.distance)
                if result.usedFallback {
                    print("📍 Bubble placed using fallback (raycast failed) at \(result.distance)m")
                }
            } else {
                // Placement engine failed, fall back to old method
                let forward = SIMD3<Float>(
                    cameraTransform.columns.2.x,
                    cameraTransform.columns.2.y,
                    cameraTransform.columns.2.z
                )
                let position = SIMD3<Float>(
                    cameraTransform.columns.3.x,
                    cameraTransform.columns.3.y,
                    cameraTransform.columns.3.z
                ) + forward * 2.0
                bubble.entity.position = position
                print("⚠️ Placement engine failed, using legacy 2m positioning")
            }
        } else {
            // Fallback: position at world origin 2m in front if no camera
            bubble.entity.position = [0, 0, -2]
        }

        // Add to scene
        arView.addTranslationBubble(bubble)
        activeBubbles.append(bubble)

        // Auto-dismiss timer (skip if pinned)
        if !bubble.isPinned {
            let dismissTime = duration ?? autoDismissTime
            Task {
                try await Task.sleep(nanoseconds: UInt64(dismissTime * 1_000_000_000))
                await dismissBubble(bubble)
            }
        } else {
            print("📌 Bubble pinned — auto-dismiss disabled")
        }
    }

    nonisolated func dismissBubble(_ bubble: TranslationBubble) {
        Task { @MainActor in
            guard let arView = arView,
                  let index = activeBubbles.firstIndex(where: { $0.entity === bubble.entity }) else { return }
            arView.removeTranslationBubble(bubble)
            activeBubbles.remove(at: index)
        }
    }

    func dismissAllBubbles() {
        Task { @MainActor in
            guard let arView = arView else { return }
            for bubble in activeBubbles {
                arView.removeTranslationBubble(bubble)
            }
            activeBubbles.removeAll()
        }
    }
}
