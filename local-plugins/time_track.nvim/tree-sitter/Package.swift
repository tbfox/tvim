// swift-tools-version:5.3

import Foundation
import PackageDescription

var sources = ["src/parser.c"]
if FileManager.default.fileExists(atPath: "src/scanner.c") {
    sources.append("src/scanner.c")
}

let package = Package(
    name: "TreeSitterTimeTrack",
    products: [
        .library(name: "TreeSitterTimeTrack", targets: ["TreeSitterTimeTrack"]),
    ],
    dependencies: [
        .package(name: "SwiftTreeSitter", url: "https://github.com/tree-sitter/swift-tree-sitter", from: "0.9.0"),
    ],
    targets: [
        .target(
            name: "TreeSitterTimeTrack",
            dependencies: [],
            path: ".",
            sources: sources,
            resources: [
                .copy("queries")
            ],
            publicHeadersPath: "bindings/swift",
            cSettings: [.headerSearchPath("src")]
        ),
        .testTarget(
            name: "TreeSitterTimeTrackTests",
            dependencies: [
                "SwiftTreeSitter",
                "TreeSitterTimeTrack",
            ],
            path: "bindings/swift/TreeSitterTimeTrackTests"
        )
    ],
    cLanguageStandard: .c11
)
