import XCTest
import RealityKit
import ARKit
@testable import WoofTalkAR

@MainActor
final class ARPlacementEngineTests: XCTestCase {

    var engine: ARPlacementEngine!
    var mockARView: MockARView!

    override func setUp() async throws {
        try await super.setUp()
        engine = ARPlacementEngine.shared
        mockARView = MockARView()
    }

    override func tearDown() async throws {
        engine = nil
        mockARView = nil
        try await super.tearDown()
    }

    // MARK: - estimateDogPosition Tests

    func testEstimateDogPosition_RaycastHit() async throws {
        // Given: A camera transform looking forward
        let cameraTransform = simd_float4x4(
            [1, 0, 0, 0],
            [0, 1, 0, 0],
            [0, 0, 1, 0],
            [0, 0, 0, 1]
        )

        // Set up mock raycast to hit at 3m
        let hitPosition = SIMD3<Float>(0, 0, -3) // In front of camera
        mockARView.mockRaycastResults = [MockRaycastResult(
            worldTransform: simd_float4x4(
                [1, 0, 0, 0],
                [0, 1, 0, 0],
                [0, 0, 1, 0],
                [hitPosition.x, hitPosition.y, hitPosition.z, 1]
            )
        )]

        // When
        let (position, usedFallback) = try await engine.estimateDogPosition(
            from: cameraTransform,
            in: mockARView
        )

        // Then
        XCTAssertFalse(usedFallback, "Should use raycast result, not fallback")
        XCTAssertEqual(position.x, hitPosition.x, accuracy: 0.001)
        XCTAssertEqual(position.y, hitPosition.y, accuracy: 0.001)
        XCTAssertEqual(position.z, hitPosition.z, accuracy: 0.001)
    }

    func testEstimateDogPosition_RaycastMiss_UsesFallback() async throws {
        // Given: Camera transform facing forward
        let cameraTransform = simd_float4x4(
            [1, 0, 0, 0],
            [0, 1, 0, 0],
            [0, 0, 1, 0],
            [0, 0, 0, 1]
        )

        // No raycast hits (empty array)
        mockARView.mockRaycastResults = []

        // When
        let (position, usedFallback) = try await engine.estimateDogPosition(
            from: cameraTransform,
            in: mockARView
        )

        // Then
        XCTAssertTrue(usedFallback, "Should use fallback when raycast fails")
        XCTAssertEqual(position.x, 0, accuracy: 0.001)
        XCTAssertEqual(position.y, 0, accuracy: 0.001)
        // Position should be between 4-6 meters in front (negative z in forward direction)
        XCTAssertLessThanOrEqual(position.z, -3.999)
        XCTAssertGreaterThanOrEqual(position.z, -6.001)
    }

    func testEstimateDogPosition_FallbackDistanceRange() async throws {
        // Given: Camera at origin facing -Z
        let cameraTransform = simd_float4x4(
            [1, 0, 0, 0],
            [0, 1, 0, 0],
            [0, 0, 1, 0],
            [0, 0, 0, 1]
        )

        // Test multiple iterations to verify randomness stays in range
        for _ in 0..<10 {
            mockARView.mockRaycastResults = []
            let (position, usedFallback) = try await engine.estimateDogPosition(
                from: cameraTransform,
                in: mockARView
            )

            XCTAssertTrue(usedFallback)
            let distance = abs(position.z) // Distance along -Z axis
            XCTAssertGreaterThanOrEqual(distance, 4.0)
            XCTAssertLessThanOrEqual(distance, 6.0)
        }
    }

    // MARK: - clampDistance Tests

    func testClampDistance_WithinRange() async throws {
        // Given: Camera at origin, target at 5m
        let cameraTransform = simd_float4x4(
            [1, 0, 0, 0],
            [0, 1, 0, 0],
            [0, 0, 1, 0],
            [0, 0, 0, 1]
        )
        let targetPosition = SIMD3<Float>(0, 0, -5)

        // When
        let clamped = engine.clampDistance(targetPosition, from: cameraTransform)

        // Then: Should remain at 5m (within 1-10m range)
        XCTAssertEqual(clamped.x, 0, accuracy: 0.001)
        XCTAssertEqual(clamped.y, 0, accuracy: 0.001)
        XCTAssertEqual(clamped.z, -5, accuracy: 0.001)
    }

    func testClampDistance_TooClose() async throws {
        // Given: Target at 0.5m (too close)
        let cameraTransform = simd_float4x4(
            [1, 0, 0, 0],
            [0, 1, 0, 0],
            [0, 0, 1, 0],
            [0, 0, 0, 1]
        )
        let targetPosition = SIMD3<Float>(0, 0, -0.5)

        // When
        let clamped = engine.clampDistance(targetPosition, from: cameraTransform)

        // Then: Should clamp to 1m
        XCTAssertEqual(clamped.x, 0, accuracy: 0.001)
        XCTAssertEqual(clamped.y, 0, accuracy: 0.001)
        XCTAssertEqual(clamped.z, -1, accuracy: 0.001)
    }

    func testClampDistance_TooFar() async throws {
        // Given: Target at 15m (too far)
        let cameraTransform = simd_float4x4(
            [1, 0, 0, 0],
            [0, 1, 0, 0],
            [0, 0, 1, 0],
            [0, 0, 0, 1]
        )
        let targetPosition = SIMD3<Float>(0, 0, -15)

        // When
        let clamped = engine.clampDistance(targetPosition, from: cameraTransform)

        // Then: Should clamp to 10m
        XCTAssertEqual(clamped.x, 0, accuracy: 0.001)
        XCTAssertEqual(clamped.y, 0, accuracy: 0.001)
        XCTAssertEqual(clamped.z, -10, accuracy: 0.001)
    }

    func testClampDistance_OffAxis() async throws {
        // Given: Target offset to the right (x=3) at 8m depth (z=-8)
        let cameraTransform = simd_float4x4(
            [1, 0, 0, 0],
            [0, 1, 0, 0],
            [0, 0, 1, 0],
            [0, 0, 0, 1]
        )
        let targetPosition = SIMD3<Float>(3, 0, -8)

        // When
        let clamped = engine.clampDistance(targetPosition, from: cameraTransform)

        // Then: Should maintain direction but clamp distance to 10m
        let direction = SIMD3<Float>(3, 0, -8)
        let normalized = direction / 10.0 // At distance 10
        XCTAssertEqual(clamped.x, normalized.x, accuracy: 0.001)
        XCTAssertEqual(clamped.y, normalized.y, accuracy: 0.001)
        XCTAssertEqual(clamped.z, normalized.z, accuracy: 0.001)
    }

    // MARK: - isPositionVisible Tests

    func testIsPositionVisible_NoOcclusion() async throws {
        // Given: Clear line of sight
        let cameraTransform = simd_float4x4(
            [1, 0, 0, 0],
            [0, 1, 0, 0],
            [0, 0, 1, 0],
            [0, 0, 0, 1]
        )
        let targetPosition = SIMD3<Float>(0, 0, -5)

        // No raycast hits (clear path)
        mockARView.mockRaycastResults = []

        // When
        let visible = await engine.isPositionVisible(
            from: cameraTransform,
            to: targetPosition,
            in: mockARView
        )

        // Then: Should be visible
        XCTAssertTrue(visible)
    }

    func testIsPositionVisible_OccludedByGeometry() async throws {
        // Given: Target at 5m, but geometry at 3m blocks view
        let cameraTransform = simd_float4x4(
            [1, 0, 0, 0],
            [0, 1, 0, 0],
            [0, 0, 1, 0],
            [0, 0, 0, 1]
        )
        let targetPosition = SIMD3<Float>(0, 0, -5)

        // Simulate geometry hit at 3m
        let hitPosition = SIMD3<Float>(0, 0, -3)
        mockARView.mockRaycastResults = [MockRaycastResult(
            worldTransform: simd_float4x4(
                [1, 0, 0, 0],
                [0, 1, 0, 0],
                [0, 0, 1, 0],
                [hitPosition.x, hitPosition.y, hitPosition.z, 1]
            )
        )]

        // When
        let visible = await engine.isPositionVisible(
            from: cameraTransform,
            to: targetPosition,
            in: mockARView
        )

        // Then: Should be occluded (hit at 3m < target at 5m)
        XCTAssertFalse(visible)
    }

    func testIsPositionVisible_ExactHitCountsAsVisible() async throws {
        // Given: Target at 5m, geometry hit exactly at 5m
        let cameraTransform = simd_float4x4(
            [1, 0, 0, 0],
            [0, 1, 0, 0],
            [0, 0, 1, 0],
            [0, 0, 0, 1]
        )
        let targetPosition = SIMD3<Float>(0, 0, -5)

        // Simulate geometry hit exactly at target
        let hitPosition = SIMD3<Float>(0, 0, -5)
        mockARView.mockRaycastResults = [MockRaycastResult(
            worldTransform: simd_float4x4(
                [1, 0, 0, 0],
                [0, 1, 0, 0],
                [0, 0, 1, 0],
                [hitPosition.x, hitPosition.y, hitPosition.z, 1]
            )
        )]

        // When
        let visible = await engine.isPositionVisible(
            from: cameraTransform,
            to: targetPosition,
            in: mockARView
        )

        // Then: Within 10cm margin, should count as visible
        XCTAssertTrue(visible)
    }

    func testIsPositionVisible_MultipleHits() async throws {
        // Given: Target at 10m, hit at 2m and 8m (first hit blocks)
        let cameraTransform = simd_float4x4(
            [1, 0, 0, 0],
            [0, 1, 0, 0],
            [0, 0, 1, 0],
            [0, 0, 0, 1]
        )
        let targetPosition = SIMD3<Float>(0, 0, -10)

        // Multiple hits: wall at 2m, then furniture at 8m
        mockARView.mockRaycastResults = [
            MockRaycastResult(worldTransform: simd_float4x4(
                [1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, -2, 1]
            )),
            MockRaycastResult(worldTransform: simd_float4x4(
                [1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, -8, 1]
            ))
        ]

        // When
        let visible = await engine.isPositionVisible(
            from: cameraTransform,
            to: targetPosition,
            in: mockARView
        )

        // Then: First hit at 2m < 10m - 0.1, so occluded
        XCTAssertFalse(visible)
    }

    // MARK: - placeBubble Integration Tests

    func testPlaceBubble_ReturnsValidResult_WithRaycast() async throws {
        // Given
        let cameraTransform = simd_float4x4(
            [1, 0, 0, 0],
            [0, 1, 0, 0],
            [0, 0, 1, 0],
            [0, 0, 0, 1]
        )

        // Raycast hits at 3m, within range, clear path
        let hitPosition = SIMD3<Float>(0, 0, -3)
        mockARView.mockRaycastResults = [MockRaycastResult(
            worldTransform: simd_float4x4(
                [1, 0, 0, 0],
                [0, 1, 0, 0],
                [0, 0, 1, 0],
                [hitPosition.x, hitPosition.y, hitPosition.z, 1]
            )
        )]

        // When
        let result = await engine.placeBubble(
            text: "Test bubble",
            from: cameraTransform,
            in: mockARView
        )

        // Then
        XCTAssertNotNil(result)
        XCTAssertFalse(result!.usedFallback)
        XCTAssertEqual(result!.position.z, -3, accuracy: 0.001)
        XCTAssertEqual(result!.distance, 3, accuracy: 0.001)
        XCTAssertNil(result!.reason)
    }

    func testPlaceBubble_ReturnsNil_WhenOccluded() async throws {
        // Given: Raycast hits but position is occluded
        let cameraTransform = simd_float4x4(
            [1, 0, 0, 0],
            [0, 1, 0, 0],
            [0, 0, 1, 0],
            [0, 0, 0, 1]
        )
        let hitPosition = SIMD3<Float>(0, 0, -3)
        mockARView.mockRaycastResults = [MockRaycastResult(
            worldTransform: simd_float4x4(
                [1, 0, 0, 0],
                [0, 1, 0, 0],
                [0, 0, 1, 0],
                [hitPosition.x, hitPosition.y, hitPosition.z, 1]
            )
        )]

        // Need to also have a raycast hit that's closer than the target
        // Set up occlusion detector to return false
        mockARView.shouldSimulateOcclusion = true

        // When
        let result = await engine.placeBubble(
            text: "Occluded test",
            from: cameraTransform,
            in: mockARView
        )

        // Then: Should return nil due to occlusion
        XCTAssertNil(result)
    }

    func testPlaceBubble_ClampsDistance_WhenTooFar() async throws {
        // Given: Raycast hits at 12m (beyond max 10m)
        let cameraTransform = simd_float4x4(
            [1, 0, 0, 0],
            [0, 1, 0, 0],
            [0, 0, 1, 0],
            [0, 0, 0, 1]
        )
        let hitPosition = SIMD3<Float>(0, 0, -12)
        mockARView.mockRaycastResults = [MockRaycastResult(
            worldTransform: simd_float4x4(
                [1, 0, 0, 0],
                [0, 1, 0, 0],
                [0, 0, 1, 0],
                [hitPosition.x, hitPosition.y, hitPosition.z, 1]
            )
        )]

        // When
        let result = await engine.placeBubble(
            text: "Far test",
            from: cameraTransform,
            in: mockARView
        )

        // Then: Should clamp to 10m
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.distance, 10, accuracy: 0.001)
        XCTAssertEqual(result!.position.z, -10, accuracy: 0.001)
    }
}

// MARK: - Mock ARView for Testing

class MockARView: ARView {
    var mockRaycastResults: [MockRaycastResult] = []
    var shouldSimulateOcclusion: Bool = false

    override func raycast(_ query: ARRaycastQuery) -> [ARRaycastResult] {
        if shouldSimulateOcclusion && mockRaycastResults.count > 0 {
            // Simulate occlusion by returning a hit that's closer than the first raycast result
            let occludingHit = MockRaycastResult(
                worldTransform: simd_float4x4(
                    [1, 0, 0, 0],
                    [0, 1, 0, 0],
                    [0, 0, 1, 0],
                    [0, 0, -2, 1] // Hit at 2m
                )
            )
            // Return both occluding hit and target hit
            return [occludingHit, mockRaycastResults.first!].compactMap { $0 as? ARRaycastResult }
        }
        return mockRaycastResults
    }
}

class MockRaycastResult: ARRaycastResult {
    let mockTransform: simd_float4x4

    init(worldTransform: simd_float4x4) {
        self.mockTransform = worldTransform
    }

    override var worldTransform: simd_float4x4 {
        return mockTransform
    }

    override var target: ARRaycastQuery.Target {
        return .existingPlaneGeometry
    }

    override var alignment: ARRaycastQuery.TargetAlignment {
        return .any
    }
}
