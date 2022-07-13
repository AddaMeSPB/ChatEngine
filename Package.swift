// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "ChatEngine",
    platforms: [
       .macOS(.v10_15)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.62.1"),
//        .package(path: "../AddaSharedModels"),
        .package(url: "https://github.com/AddaMeSPB/AddaSharedModels.git", from: "1.1.1"),
        .package(url: "https://github.com/vapor/jwt.git", from: "4.2.0"),
        .package(url: "https://github.com/vapor/apns.git", from: "1.0.1")
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "AddaSharedModels", package: "AddaSharedModels"),
                .product(name: "JWT", package: "jwt"),
                .product(name: "APNS", package: "apns")
            ],
            swiftSettings: [
                // Enable better optimizations when building in Release configuration. Despite the use of
                // the `.unsafeFlags` construct required by SwiftPM, this flag is recommended for Release
                // builds. See <https://github.com/swift-server/guides#building-for-production> for details.
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
            ]
        ),
        .executableTarget(name: "Run", dependencies: [.target(name: "App")]),
        .testTarget(name: "AppTests",
                    dependencies: [
                        .target(name: "App"),
                        .product(name: "XCTVapor", package: "vapor"),
                        .product(name: "AddaSharedModels", package: "AddaSharedModels")
                    ]
                )
    ]
)
