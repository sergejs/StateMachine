// swift-tools-version:5.1
//
//  Package.swift
//  StateMachine
//
//  Created by Sergejs Smirnovs on 05/03/2020.
//  Copyright © 2020 Sergejs Smirnovs. All rights reserved.
//

import PackageDescription

let package = Package(
  name: "StateMachine",
  platforms: [
    .macOS(.v10_15),
    .iOS(.v13),
    .watchOS(.v6),
    .tvOS(.v13),
  ],
  products: [
    .library(
      name: "StateMachine",
      type: .dynamic,
      targets: ["StateMachine"]
    ),
  ],
  dependencies: [
    .package(url: "git@github.com:sergejs/SwiftLogger.git", from: "1.0.1")
  ],
  targets: [
    .target(name: "StateMachine", dependencies: ["SwiftLogger"]),
    .testTarget(name: "StateMachineTests", dependencies: ["StateMachine"]),
  ]
)
