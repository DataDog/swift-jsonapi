// swift-tools-version: 5.9

import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "swift-json-api",
  platforms: [
    .macOS(.v10_15),
    .iOS(.v13),
    .tvOS(.v13),
    .watchOS(.v6),
    .macCatalyst(.v13),
  ],
  products: [
    .library(
      name: "JSONAPI",
      targets: ["JSONAPI"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-syntax", "509.0.0"..<"511.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-macro-testing", from: "0.2.0"),
  ],
  targets: [
    .target(
      name: "JSONAPI",
      dependencies: ["JSONAPIMacros"]
    ),
    .testTarget(
      name: "JSONAPITests",
      dependencies: ["JSONAPI"]
    ),
    .macro(
      name: "JSONAPIMacros",
      dependencies: [
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
      ]
    ),
    .testTarget(
      name: "JSONAPIMacrosTests",
      dependencies: [
        "JSONAPIMacros",
        .product(name: "MacroTesting", package: "swift-macro-testing"),
      ]
    ),
  ]
)
