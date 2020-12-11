// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "Eliterover",
    platforms: [
       .macOS(.v10_15)
    ],
    dependencies: [
        // Fluent
        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
        // with postgres Driver
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0"),
        // Leaf
        .package(url: "https://github.com/vapor/leaf.git", from: "4.0.0-rc"),
        // Mail SMTP
        .package(url: "https://github.com/Mikroservices/Smtp.git", from: "2.0.0"),
        //HTML Kit
        .package(url: "https://github.com/vapor-community/HTMLKit.git", from: "2.0.0"),
        .package(name: "HTMLKitVaporProvider", url: "https://github.com/MatsMoll/htmlkit-vapor-provider.git", from: "1.0.0"),
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
        //A package to prevent CSRF
        .package(name: "VaporCSRF", url: "https://github.com/brokenhandsio/vapor-csrf.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "Leaf", package: "leaf"),
                .product(name: "Smtp", package: "Smtp"),
                .product(name: "HTMLKit", package: "HTMLKit"),
                .product(name: "HTMLKitVaporProvider", package: "HTMLKitVaporProvider"),
                .product(name: "Vapor", package: "vapor"),
                "VaporCSRF"
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
