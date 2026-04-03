import RealityKit
import SwiftUI
import ARKit

struct TranslationBubble {
    let entity: Entity
    let text: String
    let dismissHandler: (() -> Void)?

    // MARK: - State

    /// Whether this bubble is pinned (exempt from auto-dismiss and eviction)
    var isPinned: Bool = false {
        didSet {
            updatePinVisual()
        }
    }

    // MARK: - Configuration

    /// Reference distance for font scaling (font size calibrated for this distance)
    private static let referenceDistance: Float = 2.0
    private static let baseFontSize: Float = 0.05 // ~24pt at 2m

    /// Font size range (clamped)
    private static let minFontSize: Float = 0.02  // ~12pt
    private static let maxFontSize: Float = 0.1   // ~48pt

    /// Background opacity based on distance
    private static let nearOpacity: Float = 0.85
    private static let farOpacity: Float = 0.95
    private static let transitionDistance: Float = 3.0

    /// Text mesh cache for performance (static shared across all bubbles)
    private static let meshCache = NSCache<NSString, MeshResource>()

    /// Current distance from camera (set via configureForDistance)
    private var currentDistance: Float = 2.0

    /// Pin visual indicator (small pin icon on top-right of bubble)
    private lazy var pinEntity: ModelEntity? = {
        let pinSize: Float = 0.03 // 3cm
        let pinMesh = MeshResource.generateBox(size: [pinSize, pinSize * 1.5, 0.005])
        var pinMaterial = UnlitMaterial()
        pinMaterial.color = .init(tint: UIColor.systemGreen.withAlphaComponent(0.9))
        let pinEntity = ModelEntity(mesh: pinMesh, materials: [pinMaterial])
        pinEntity.position = [0.18, 0.09, 0.002] // Top-right corner of bubble
        return pinEntity
    }()

    init(text: String, dismissHandler: (() -> Void)? = nil) {
        self.text = text
        self.dismissHandler = dismissHandler

        // Create world anchor (will be positioned by ARCoordinator)
        let anchor = AnchorEntity(.world)

        // Create bubble background (rounded rectangle plane)
        let bubbleWidth: Float = 0.4  // 40cm wide
        let bubbleHeight: Float = 0.2 // 20cm tall
        let bubbleMesh = MeshResource.generatePlane(width: bubbleWidth, height: bubbleHeight)

        // Semi-transparent dark background (opacity will be adjusted by configureForDistance)
        var bubbleMaterial = UnlitMaterial()
        bubbleMaterial.color = .init(tint: UIColor(white: 0.1, alpha: Self.nearOpacity))

        let bubbleEntity = ModelEntity(mesh: bubbleMesh, materials: [bubbleMaterial])

        // Create text overlay with caching
        let textMesh = Self.generateOrCacheText(text, fontSize: Self.baseFontSize)
        var textMaterial = UnlitMaterial()
        textMaterial.color = .init(tint: .white)

        let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])
        textEntity.position = [0, 0, 0.001] // Slightly in front of bubble
        bubbleEntity.addChild(textEntity)

        // Billboard: always face camera horizontally (Y axis rotation)
        var billboard = BillboardComponent()
        billboard.mode = .y
        bubbleEntity.components.set(billboard)

        // Enable tap gesture
        bubbleEntity.generateCollisionShapes(recursive: true)
        anchor.addChild(bubbleEntity)

        self.entity = anchor

        // Store reference for debugging
        bubbleEntity.name = "TranslationBubble_\(text.prefix(10))"

        // Setup pin gesture (long press)
        setupPinGesture(on: bubbleEntity)

        // Initially hidden
        updatePinVisual()
    }

    // MARK: - Gesture Setup

    private func setupPinGesture(on entity: ModelEntity) {
        // Note: RealityKit gesture support varies by platform.
        // For visionOS, we'll use hit-testing from ARView and handle gestures there.
        // This bubble just exposes the togglePin() method.
    }

    // MARK: - Pin Management

    /// Toggle the pinned state (called by gesture handler)
    func togglePin() {
        isPinned.toggle()
    }

    /// Update visual indicator for pin state
    private func updatePinVisual() {
        guard let bubbleEntity = entity.children.first,
              let pinEntity = pinEntity else { return }

        if isPinned {
            // Add pin icon if not already present
            if !bubbleEntity.children.contains(pinEntity) {
                bubbleEntity.addChild(pinEntity)
            }
            // Maybe change border color
            if var material = bubbleEntity.model?.materials.first as? UnlitMaterial {
                material.color = .init(tint: UIColor.systemGreen.withAlphaComponent(0.3))
                bubbleEntity.model?.materials = [material]
            }
        } else {
            // Remove pin icon
            pinEntity.removeFromParent()
            // Reset border color
            if var material = bubbleEntity.model?.materials.first as? UnlitMaterial {
                material.color = .init(tint: UIColor(white: 0.1, alpha: CGFloat(Self.nearOpacity)))
                bubbleEntity.model?.materials = [material]
            }
        }
    }

    /// Configure bubble appearance based on viewing distance
    func configureForDistance(_ distance: Float) {
        currentDistance = distance

        // Update background opacity: farther = more opaque
        let opacity: Float
        if distance <= Self.transitionDistance {
            opacity = Self.nearOpacity
        } else {
            opacity = Self.farOpacity
        }

        // Update bubble background material
        if let bubbleEntity = entity.children.first {
            if var material = bubbleEntity.model?.materials.first as? UnlitMaterial {
                material.color = .init(tint: UIColor(white: 0.1, alpha: CGFloat(opacity)))
                bubbleEntity.model?.materials = [material]
            }
        }

        // Note: Font size scaling would require regenerating text mesh
        // That's expensive; for now we keep fixed base size
        // Future: implement dynamic mesh regeneration if needed
    }

    // MARK: - Text Mesh Caching

    private static func generateOrCacheText(_ text: String, fontSize: Float) -> MeshResource {
        let cacheKey = "\(text)_\(fontSize)" as NSString

        if let cached = meshCache.object(forKey: cacheKey) {
            return cached
        }

        // Generate new mesh
        let mesh = MeshResource.generateText(
            text,
            extrusionDepth: 0.01,
            font: .systemFont(ofSize: CGFloat(fontSize)),
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byWordWrapping
        )

        meshCache.setObject(mesh, forKey: cacheKey)
        return mesh
    }
}

    func add(to arView: ARView) {
        arView.scene.addAnchor(entity)
        arView.installGestures([.tap], for: entity)
    }

    func remove(from arView: ARView) {
        arView.scene.removeAnchor(entity)
    }
}

// Convenience extension for ARView
extension ARView {
    func addTranslationBubble(_ bubble: TranslationBubble) {
        bubble.add(to: self)
    }

    func removeTranslationBubble(_ bubble: TranslationBubble) {
        bubble.remove(from: self)
    }
}
