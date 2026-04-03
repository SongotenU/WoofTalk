import Foundation
import RealityKit
import ARKit

/// Placement engine for AR bubbles using gaze-based positioning with raycast
actor ARPlacementEngine {
    static let shared = ARPlacementEngine()
    private init() {}

    /// Placement configuration
    private let minPlacementDistance: Float = 1.0   // 1m minimum
    private let maxPlacementDistance: Float = 10.0  // 10m maximum
    private let defaultPlacementDistance: Float = 5.0 // 5m average
    private let placementJitter: Float = 1.0        // ±1m random variation
    private let raycastExtent: Float = 10.0        // Max raycast distance

    /// Raycast provider for test injection (default uses real ARView session)
    var raycastProvider: ((ARRaycastQuery, ARView) -> [ARRaycastResult])?

    /// Result of a placement attempt
    struct PlacementResult {
        let position: SIMD3<Float>
        let distance: Float
        let usedFallback: Bool
        let reason: String?
    }

    /// Errors that can occur during placement
    enum PlacementError: Error, LocalizedError {
        case noCameraTransform
        case raycastFailed
        case occlusionRejected

        var errorDescription: String? {
            switch self {
            case .noCameraTransform: return "Camera transform unavailable"
            case .raycastFailed: return "Raycast failed to find surface"
            case .occlusionRejected: return "Position is occluded"
            }
        }
    }

    // MARK: - Public API

    /// Place a bubble with full pipeline: estimate position → check occlusion → clamp distance
    /// - Parameters:
    ///   - text: Bubble text content (used for logging/debugging)
    ///   - cameraTransform: Current camera transform matrix
    ///   - arView: ARView for raycast queries
    /// - Returns: PlacementResult with final position, or nil if placement fails
    func placeBubble(
        text: String,
        from cameraTransform: simd_float4x4,
        in arView: ARView
    ) -> PlacementResult? {

        // Step 1: Estimate position along gaze direction
        let estimatedPosition: SIMD3<Float>
        let usedFallback: Bool

        do {
            (estimatedPosition, usedFallback) = try estimateDogPosition(
                from: cameraTransform,
                in: arView
            )
        } catch {
            print("⚠️ Placement: \(error.localizedDescription) for text '\(text.prefix(20))'")
            return nil
        }

        // Step 2: Check occlusion (reject if blocked)
        guard isPositionVisible(
            from: cameraTransform,
            to: estimatedPosition,
            in: arView
        ) else {
            print("⚠️ Placement: Position occluded for text '\(text.prefix(20))'")
            return PlacementResult(
                position: estimatedPosition,
                distance: distance(from: cameraTransform, to: estimatedPosition),
                usedFallback: usedFallback,
                reason: "occluded"
            )
        }

        // Step 3: Clamp distance to allowed range
        let clampedPosition = clampDistance(estimatedPosition, from: cameraTransform)

        return PlacementResult(
            position: clampedPosition,
            distance: distance(from: cameraTransform, to: clampedPosition),
            usedFallback: usedFallback,
            reason: nil
        )
    }

    /// Estimate dog position by raycasting along camera forward vector
    /// - Returns: (position, usedFallback) tuple
    func estimateDogPosition(
        from cameraTransform: simd_float4x4,
        in arView: ARView
    ) throws -> (SIMD3<Float>, Bool) {

        // Extract camera position and forward direction
        let cameraPos = SIMD3<Float>(
            cameraTransform.columns.3.x,
            cameraTransform.columns.3.y,
            cameraTransform.columns.3.z
        )

        let forward = SIMD3<Float>(
            cameraTransform.columns.2.x,
            cameraTransform.columns.2.y,
            cameraTransform.columns.2.z
        )

        // Perform raycast along gaze direction
        let raycastQuery = ARRaycastQuery(
            origin: cameraPos,
            direction: forward,
            allowing: .estimatedPlane,
            alignment: .any
        )

        let results: [ARRaycastResult]
        if let provider = raycastProvider {
            results = provider(raycastQuery, arView)
        } else {
            results = arView.session.raycast(raycastQuery)
        }

        if let result = results.first {
            // Raycast hit: use the world position of the hit
            let worldPos = SIMD3<Float>(
                result.worldTransform.columns.3.x,
                result.worldTransform.columns.3.y,
                result.worldTransform.columns.3.z
            )
            return (worldPos, false)
        }

        // Fallback: place at random distance between 4-6 meters along gaze
        let fallbackDistance = Float.random(in: 4...6)
        let fallbackPosition = cameraPos + forward * fallbackDistance
        return (fallbackPosition, true)
    }

    /// Clamp a position to be within min/max distance from camera
    func clampDistance(_ position: SIMD3<Float>, from cameraTransform: simd_float4x4) -> SIMD3<Float> {
        let cameraPos = SIMD3<Float>(
            cameraTransform.columns.3.x,
            cameraTransform.columns.3.y,
            cameraTransform.columns.3.z
        )

        let toPosition = position - cameraPos
        let currentDistance = simd_length(toPosition)

        guard currentDistance > 0 else { return position }

        var clampedDistance = currentDistance

        // Apply min/max bounds
        if currentDistance < minPlacementDistance {
            clampedDistance = minPlacementDistance
        } else if currentDistance > maxPlacementDistance {
            clampedDistance = maxPlacementDistance
        } else {
            // No clamping needed
            return position
        }

        // Reconstruct position at clamped distance along same direction
        let direction = toPosition / currentDistance
        return cameraPos + direction * clampedDistance
    }

    /// Check if a position is visible from camera (no occlusion)
    /// Performs a raycast from camera to target; if something is closer than target, it's blocked
    func isPositionVisible(
        from cameraTransform: simd_float4x4,
        to targetPosition: SIMD3<Float>,
        in arView: ARView
    ) -> Bool {

        let cameraPos = SIMD3<Float>(
            cameraTransform.columns.3.x,
            cameraTransform.columns.3.y,
            cameraTransform.columns.3.z
        )

        let direction = targetPosition - cameraPos
        let targetDistance = simd_length(direction)

        guard targetDistance > 0 else { return true }

        let normalizedDir = direction / targetDistance

        // Raycast from camera to target position
        let raycastQuery = ARRaycastQuery(
            origin: cameraPos,
            direction: normalizedDir,
            allowing: .existingPlaneGeometry, // Prefer real geometry
            alignment: .any
        )

        // Check if any raycast hits before the target position
        let raycastResults: [ARRaycastResult]
        if let provider = raycastProvider {
            raycastResults = provider(raycastQuery, arView)
        } else {
            raycastResults = arView.session.raycast(raycastQuery)
        }

        for result in raycastResults {
            let hitDistance = distance(from: cameraPos, to: result.worldPosition)
            // If hit is significantly before target (within 10cm), position is occluded
            if hitDistance < targetDistance - 0.1 {
                return false
            }
        }

        return true
    }

    // MARK: - Helper Methods

    /// Calculate distance between two positions
    private func distance(from: SIMD3<Float>, to: SIMD3<Float>) -> Float {
        return simd_length(to - from)
    }

    /// Calculate distance from camera transform to position
    private func distance(from cameraTransform: simd_float4x4, to position: SIMD3<Float>) -> Float {
        let cameraPos = SIMD3<Float>(
            cameraTransform.columns.3.x,
            cameraTransform.columns.3.y,
            cameraTransform.columns.3.z
        )
        return distance(from: cameraPos, to: position)
    }
}
