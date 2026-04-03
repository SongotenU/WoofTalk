// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "WoofTalkAR",
    platforms: [
        .visionOS(.v1)
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.20.0")
    ],
    targets: [
        .target(
            name: "WoofTalkAR",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift")
            ]
        ),
        .testTarget(
            name: "BarkDetectorTests",
            dependencies: ["WoofTalkAR"]
        ),
        .testTarget(
            name: "ARPlacementEngineTests",
            dependencies: ["WoofTalkAR"]
        )
    ]
)
