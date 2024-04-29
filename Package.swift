// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "NetworkGear",
  platforms: [
    .macOS("10.15.4"), // Workaround for https://bugs.swift.org/browse/SR-13859
    .iOS(.v13),
    .watchOS(.v6),
    .tvOS(.v13),
  ],
  products: [
    // Products define the executables and libraries produced by a package, and make them visible to other packages.
    .library(name: "CLibCURL", targets: ["CLibCURL"]),
    .library(
      name: "SwiftNetworkGear",
      type: .dynamic,
      targets: [
        "CURLClient",
        "CNetworkGear",
        "NetworkGear"
      ]
    ),
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    .package(url:"https://github.com/YOCKOW/SwiftBootstring.git", from: "1.1.0"),
    .package(url:"https://github.com/YOCKOW/SwiftPublicSuffix.git", from: "2.0.1"),
    .package(url:"https://github.com/YOCKOW/SwiftRanges.git", from: "3.1.0"),
    .package(url:"https://github.com/YOCKOW/SwiftTemporaryFile.git", from: "4.0.7"),
    .package(url:"https://github.com/YOCKOW/SwiftUnicodeSupplement.git", from: "1.1.1"),
    .package(url:"https://github.com/YOCKOW/ySwiftExtensions.git", from: "1.9.0"),
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages which this package depends on.
    .systemLibrary(
      name: "CLibCURL",
      pkgConfig: "libcurl",
      providers: [
        .brew(["curl"]),
        .apt(["libcurl4-openssl-dev"]),
      ]
    ),
    .target(
      name: "CURLClient",
      dependencies: [
        "CLibCURL",
        "SwiftTemporaryFile",
        "ySwiftExtensions",
      ]
    ),
    .target(
      name: "CNetworkGear",
      dependencies: [],
      exclude: [
        "README.md",
      ]
    ),
    .target(name: "NetworkGear", dependencies: [
      "CURLClient",
      "CNetworkGear",
      "SwiftBootstring",
      "SwiftPublicSuffix",
      "SwiftRanges",
      "SwiftUnicodeSupplement",
      "ySwiftExtensions",
    ]),
    .target(name: "sockaddr_tests", dependencies: [], path:"Tests/sockaddr-tests"),
    .testTarget(name: "CURLTests", dependencies: ["CLibCURL", "CURLClient"]),
    .testTarget(
      name: "CNetworkGearTests",
      dependencies: [
        "CNetworkGear",
        "NetworkGear",
        "sockaddr_tests"
      ]
    ),
    .testTarget(
      name: "HTTPTests",
      dependencies: [
        "CLibCURL",
        "CURLClient",
        "NetworkGear",
      ]
    ),
    .testTarget(
      name: "NetworkGearTests",
      dependencies: [
        "CNetworkGear",
        "NetworkGear",
        "sockaddr_tests"
      ]
    ),
  ],
  swiftLanguageVersions: [.v5]
)

import Foundation
if ProcessInfo.processInfo.environment["YOCKOW_USE_LOCAL_PACKAGES"] != nil {
  let repoDirPath = String(#filePath).split(separator: "/", omittingEmptySubsequences: false).dropLast().joined(separator: "/")
  func localPath(with url: String) -> String {
    guard let url = URL(string: url) else { fatalError("Unexpected URL.") }
    let dirName = url.deletingPathExtension().lastPathComponent
    return "../\(dirName)"
  }
  package.dependencies = package.dependencies.map {
    guard case .sourceControl(_, let location, _) = $0.kind else { return $0 }
    let depRelPath = localPath(with: location)
    guard FileManager.default.fileExists(atPath: "\(repoDirPath)/\(depRelPath)") else {
      return $0
    }
    return .package(path: depRelPath)
  }
}
