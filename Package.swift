// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "StateMachine",
  platforms: [.iOS(.v13)],
  products: [
    // Products define the executables and libraries produced by a package, and make them visible to other packages.
    .library(
      name: "StateMachine",
      targets: ["StateMachine"]),
  ],
  dependencies: [],
  targets: [
    .target(
      name: "StateMachine",
      dependencies: []),
    .testTarget(
      name: "StateMachineTests",
      dependencies: ["StateMachine"]),
  ]
)
