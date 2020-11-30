// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "ChatEngine",
    platforms: [
       .macOS(.v10_15)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.32.0"),
//        .package(path: "../AddaAPIGatewayModels"),
        .package(url: "https://github.com/AddaMeSPB/AddaAPIGatewayModels.git", from: "1.0.36"),
        .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0-rc.1.4"),
        .package(url: "https://github.com/vapor/apns.git", from: "1.0.0-rc.1.1")
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "AddaAPIGatewayModels", package: "AddaAPIGatewayModels"),
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
        .target(name: "Run", dependencies: [.target(name: "App")]),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
