// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "LineApps",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "LineApps", targets: ["LineApps"])],
    targets: [
        .executableTarget(name: "LineApps"),
        .testTarget(name: "LineAppsTests", dependencies: ["LineApps"])
    ]
)
