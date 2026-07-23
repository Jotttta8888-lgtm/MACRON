// swift-tools-version:5.9
import PackageDescription
let package = Package(
    name: "MACRON",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "MACRON", targets: ["MACRON"])],
    targets: [.executableTarget(name: "MACRON", path: "Sources/MACRON")]
)
