// swift-tools-version:4.1
//
//  Cycle.swift
//  Cycle
//
//  Created by Brian Semiglia on 23/10/15.
//  Copyright © 2017 BrianSemiglia. All rights reserved.
//

import PackageDescription

let package = Package(
    name: "Cycle",
    products: [
        .library(
            name: "Cycle",
            targets: ["Cycle"]),
        ],
    dependencies: [],
    targets: [
        .target(
            name: "Cycle",
            dependencies: [],
            path: "Sources"),
        .testTarget(
            name: "CycleTests",
            dependencies: ["Cycle"],
            path: "Tests")
    ]
)
