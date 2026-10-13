// swift-tools-version: 6.0
// Motor de cálculo de HidroFES Flow como paquete, para ejecutar las pruebas
// del dominio con `swift test` en Linux o macOS sin simulador.
// La app se sigue abriendo desde HydroFesFlow.xcodeproj.

import PackageDescription

let package = Package(
    name: "HydroFesFlow",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "HydroFesFlow", targets: ["HydroFesFlow"]),
    ],
    targets: [
        .target(
            name: "HydroFesFlow",
            path: "HydroFesFlow/Domain"
        ),
        .testTarget(
            name: "HydroFesFlowTests",
            dependencies: ["HydroFesFlow"],
            path: "HydroFesFlowTests"
        ),
    ],
    swiftLanguageModes: [.v5]
)
