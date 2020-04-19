// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "NetworkGear",
  products: [
    // Products define the executables and libraries produced by a package, and make them visible to other packages.
    .library(name: "SwiftNetworkGear", type: .dynamic, targets: ["NetworkGear"]),
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    .package(url:"https://github.com/YOCKOW/SwiftBonaFideCharacterSet.git", from:"1.6.2"),
    .package(url:"https://github.com/YOCKOW/SwiftBootstring.git", from: "1.1.0"),
    .package(url:"https://github.com/YOCKOW/SwiftPublicSuffix.git", from: "2.0.1"),
    .package(url:"https://github.com/YOCKOW/SwiftRanges.git", from: "3.1.0"),
    .package(url:"https://github.com/YOCKOW/SwiftUnicodeSupplement.git", from: "1.0.0"),
    .package(url:"https://github.com/YOCKOW/ySwiftExtensions.git", "0.9.1"..<"2.0.0"),
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages which this package depends on.
    .target(name: "NetworkGear", dependencies: [
      "SwiftBonaFideCharacterSet",
      "SwiftBootstring",
      "SwiftPublicSuffix",
      "SwiftRanges",
      "SwiftUnicodeSupplement",
      "ySwiftExtensions",
    ]),
    .target(name: "sockaddr_tests", dependencies: [], path:"Tests/sockaddr-tests"),
    .testTarget(name: "NetworkGearTests", dependencies: ["NetworkGear", "sockaddr_tests"]),
    .testTarget(name: "HTTPTests", dependencies: ["NetworkGear"]),
  ],
  swiftLanguageVersions: [.v4, .v4_2, .v5]
)

import Foundation
if ProcessInfo.processInfo.environment["YOCKOW_USE_LOCAL_PACKAGES"] != nil {
  func localPath(with url: String) -> String {
    guard let url = URL(string: url) else { fatalError("Unexpected URL.") }
    let dirName = url.deletingPathExtension().lastPathComponent
    return "../\(dirName)"
  }
  package.dependencies = package.dependencies.map { .package(path: localPath(with: $0.url)) }
}
