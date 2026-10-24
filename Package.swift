// swift-tools-version: 6.0
import PackageDescription
let package = Package(name: "FocusWriter", platforms: [.macOS(.v14)], targets: [.executableTarget(name: "FocusWriter", path: ".", exclude: ["README.md", "RELEASE_NOTES.md", "build-app.sh", "publish.sh", "AppIcon.png", "AppIcon.icns", "generated_images", "dist"], sources: ["main.swift"])])
