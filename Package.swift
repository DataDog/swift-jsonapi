// swift-tools-version: 5.9

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "swift-json-api",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
        .macCatalyst(.v13)
    ],
    products: [
        .library(
            name: "JSONAPI",
            targets: ["JSONAPI"]
        ),
        .executable(
            name: "JSONAPIClient",
            targets: ["JSONAPIClient"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax", "509.0.0"..<"511.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-macro-testing", from: "0.2.0"),
    ],
    targets: [
        .macro(
            name: "JSONAPIMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .target(name: "JSONAPI", dependencies: ["JSONAPIMacros"]),
        .executableTarget(name: "JSONAPIClient", dependencies: ["JSONAPI"]),
        .testTarget(
            name: "JSONAPITests",
            dependencies: [
                "JSONAPIMacros",
                .product(name: "MacroTesting", package: "swift-macro-testing"),
            ]
        ),
    ]
)
