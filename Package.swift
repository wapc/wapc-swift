// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WapcHost",
    platforms: [
        .macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v5),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "WapcHost",
            targets: ["WapcHost"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
//        .package(name: "WasmInterpreter", url: "https://github.com/shareup/wasm-interpreter-apple.git", from: "0.5.0"),
//        .package(name: "WasmInterpreter", url: "https://github.com/brooksmtownsend/wasm-interpreter-apple.git", from: "0.5.0"),
        .package(name: "WasmInterpreter", path: "../../brooksmtownsend/wasm-interpreter-apple"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "WapcHost",
            dependencies: ["WasmInterpreter", .product(name: "Logging", package: "swift-log")]),
        .testTarget(
            name: "WapcHostTests",
            dependencies: ["WapcHost", "WasmInterpreter", .product(name: "Logging", package: "swift-log")],
            resources: [.process("hello.wasm"), .process("hello_as.wasm"), .process("hello_tinygo.wasm"), .process("hello_zig.wasm")]),
    ]
)
