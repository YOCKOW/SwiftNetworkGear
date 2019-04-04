// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Network",
  products: [
    // Products define the executables and libraries produced by a package, and make them visible to other packages.
    .library(name: "SwiftNetwork", type:.dynamic, targets: ["Network", "HTTP"]),
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    .package(url:"https://github.com/YOCKOW/SwiftBonaFideCharacterSet.git", from:"1.4.1"),
    .package(url:"https://github.com/YOCKOW/SwiftBootstring", from: "1.0.1"),
    .package(url:"https://github.com/YOCKOW/SwiftExtensions", from: "0.1.0"),
    .package(url:"https://github.com/YOCKOW/SwiftPublicSuffix", from: "1.1.0"),
    .package(url:"https://github.com/YOCKOW/SwiftRanges.git", from: "2.0.0"),
    .package(url:"https://github.com/YOCKOW/SwiftUnicodeSupplement", from: "0.5.0"),
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages which this package depends on.
    .target(name: "Network", dependencies: ["SwiftBootstring", "SwiftPublicSuffix", "SwiftUnicodeSupplement"]),
    .target(name: "HTTP", dependencies: ["Network", "SwiftBonaFideCharacterSet", "SwiftYOCKOWExtensions", "SwiftRanges"]),
    .target(name: "sockaddr_tests", dependencies: [], path:"Tests/sockaddr-tests"),
    .testTarget(name: "NetworkTests", dependencies: ["Network", "sockaddr_tests"]),
    .testTarget(name: "HTTPTests", dependencies: ["HTTP"]),
  ],
  swiftLanguageVersions: [.v4, .v4_2, .v5]
)
