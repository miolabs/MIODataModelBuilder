// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CoreDataModelEditor",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "CoreDataModelEditor",
            targets: ["CoreDataModelEditor"]
        )
    ],
    dependencies: [
        // XMLCoder for parsing and writing Core Data model XML files
        .package(url: "https://github.com/MaxDesiatov/XMLCoder.git", from: "0.14.0")
    ],
    targets: [
        .executableTarget(
            name: "CoreDataModelEditor",
            dependencies: [
                .product(name: "XMLCoder", package: "XMLCoder")
            ],
            path: "CoreDataModelEditor/Sources"
        ),
//        .testTarget(
//            name: "CoreDataModelEditorTests",
//            dependencies: ["CoreDataModelEditor"],
//            path: "CoreDataModelEditor/Tests"
//        )
    ]
)
