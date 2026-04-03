import Foundation
import RealityKit
import ARKit
import SwiftUI

/// Handles user gestures on AR entities (bubbles)
actor GestureHandler {
    static let shared = GestureHandler()

    private weak var arView: ARView?
    private var currentDraggedBubble: TranslationBubble?

    private init() {}

    /// Configure gesture handlers on the ARView
    func setupGestures(on arView: ARView) {
        self.arView = arView

        // Long press for pin toggle
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.5
        arView.addGestureRecognizer(longPress)

        // Pan (drag) for manual placement
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        arView.addGestureRecognizer(pan)
    }

    // MARK: - Gesture Handlers

    @objc private func handleLongPress(_ gesture: UILongPressRecognizer) {
        guard let arView = arView else { return }

        let location = gesture.location(in: arView)

        switch gesture.state {
        case .began:
            // Check if we hit a bubble
            if let bubble = hitTestBubble(at: location, in: arView) {
                togglePin(bubble)
            }
        default:
            break
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let arView = arView else { return }

        let location = gesture.location(in: arView)

        switch gesture.state {
        case .began:
            // Start dragging a bubble
            if let bubble = hitTestBubble(at: location, in: arView) {
                currentDraggedBubble = bubble
                // Optional: visual feedback (highlight)
            }

        case .changed:
            // Move bubble to new position
            if let bubble = currentDraggedBubble {
                if let newPos = raycastPosition(from: location, in: arView) {
                    bubble.entity.position = newPos
                }
            }

        case .ended, .cancelled, .failed:
            // Stop dragging
            currentDraggedBubble = nil

        default:
            break
        }
    }

    // MARK: - Hit Testing & Raycasting

    /// Find a TranslationBubble entity at the given screen point
    private func hitTestBubble(at point: CGPoint, in arView: ARView) -> TranslationBubble? {
        // Perform raycast to find entities
        let results = arView.raycast(from: point, allowing: .existingPlaneGeometry, alignment: .any)

        // Alternative: use hitTest with Entity
        let entities = arView.hitTest(point)
        for entity in entities {
            // Walk up parent hierarchy to find anchor that belongs to a bubble
            var parent = entity.entity.parent
            while parent != nil {
                if let bubble = findBubbleEntity(parent!) {
                    return bubble
                }
                parent = parent?.parent
            }
        }

        return nil
    }

    /// Find TranslationBubble that owns this entity (by checking anchor)
    private func findBubbleEntity(_ entity: Entity) -> TranslationBubble? {
        // This is tricky: we need to map Entity back to TranslationBubble instance
        // Option 1: store a reference to TranslationBubble in entity's userData
        // For now, return nil and rely on ARCoordinator to track bubbles by entity
        return nil
    }

    /// Raycast from screen point to world position on a plane
    private func raycastPosition(from point: CGPoint, in arView: ARView) -> SIMD3<Float>? {
        let results = arView.raycast(from: point, allowing: .estimatedPlane, alignment: .any)
        guard let first = results.first else { return nil }
        return first.worldTransform.translation
    }

    // MARK: - Pin Management

    private func togglePin(_ bubble: TranslationBubble) {
        Task { @MainActor in
            let wasPinned = bubble.isPinned
            if wasPinned {
                ARCoordinator.shared.unpinBubble(bubble)
            } else {
                ARCoordinator.shared.pinBubble(bubble)
            }
            bubble.togglePin()
        }
    }
}

// MARK: - UILongPressGestureRecognizer

// Helper to avoid warnings
private typealias UILongPressGestureRecognizer = UIGestureRecognizer

extension UILongPressGestureRecognizer {
    convenience init(target: Any?, action: Selector?) {
        self.init()
        self.addTarget(target, action: action ?? #selector(handleDummy))
    }

    @objc private func handleDummy() {}
}
