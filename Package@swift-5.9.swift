// swift-tools-version:5.9
import PackageDescription

let zlibPlatforms: [Platform] = [.linux, .android, .windows]
let unixZlibPlatforms: [Platform] = [.linux, .android]

// CZLib is only used on zlibPlatforms, but SwiftPM probes pkg-config for every
// declared systemLibrary. On an Apple host that probe is useless (it can only
// find the host's zlib) and warns when pkg-config is missing, so skip it there.
// The target itself stays declared so cross-compiling from a Mac still works.
#if canImport(Darwin)
let czlib: Target = .systemLibrary(name: "CZLib")
#else
let czlib: Target = .systemLibrary(
    name: "CZLib",
    pkgConfig: "zlib",
    providers: [.brew(["zlib"]), .apt(["zlib"])])
#endif

let package = Package(
    name: "ZIPFoundation",
    platforms: [
        .macOS(.v10_13), .iOS(.v12), .tvOS(.v12), .watchOS(.v5), .visionOS(.v1)
    ],
    products: [
        .library(name: "ZIPFoundation", targets: ["ZIPFoundation"])
    ],
    targets: [
        .target(
            name: "ZIPFoundation",
            dependencies: [
                .target(name: "CZLib", condition: .when(platforms: zlibPlatforms))
            ],
            resources: [
                .copy("Resources/PrivacyInfo.xcprivacy")
            ],
            cSettings: [
                .define("_GNU_SOURCE", to: "1", .when(platforms: unixZlibPlatforms))
            ],
            linkerSettings: [
                .linkedLibrary("z", .when(platforms: unixZlibPlatforms)),
                .linkedLibrary("zlib", .when(platforms: [.windows]))
            ]),
        czlib,
        .testTarget(name: "ZIPFoundationTests", dependencies: ["ZIPFoundation"])
    ],
    swiftLanguageVersions: [.v4, .v4_2, .v5]
)
