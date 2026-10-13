import Foundation

struct MaterialTuberia: Identifiable, Hashable {
    let nombre: String
    /// Rugosidad absoluta ε [mm].
    let rugosidadMm: Double
    /// Coeficiente C de Hazen-Williams.
    let coeficienteHazenWilliams: Double
    /// Coeficiente n de Manning [s/m^(1/3)].
    let coeficienteManning: Double

    var id: String { nombre }
    var rugosidadM: Double { rugosidadMm / 1000 }
}

enum CatalogoMateriales {
    static let todos: [MaterialTuberia] = [
        MaterialTuberia(nombre: "PVC", rugosidadMm: 0.0015, coeficienteHazenWilliams: 150, coeficienteManning: 0.009),
        MaterialTuberia(nombre: "Polietileno de alta densidad", rugosidadMm: 0.001524, coeficienteHazenWilliams: 150, coeficienteManning: 0.009),
        MaterialTuberia(nombre: "Policloruro de vinilo clorado", rugosidadMm: 0.0015, coeficienteHazenWilliams: 150, coeficienteManning: 0.009),
        MaterialTuberia(nombre: "Cobre", rugosidadMm: 0.0015, coeficienteHazenWilliams: 135, coeficienteManning: 0.010),
        MaterialTuberia(nombre: "Latón", rugosidadMm: 0.0015, coeficienteHazenWilliams: 135, coeficienteManning: 0.011),
        MaterialTuberia(nombre: "Plomo", rugosidadMm: 0.0015, coeficienteHazenWilliams: 135, coeficienteManning: 0.011),
        MaterialTuberia(nombre: "Vidrio", rugosidadMm: 0.0015, coeficienteHazenWilliams: 140, coeficienteManning: 0.011),
        MaterialTuberia(nombre: "Acero esmaltado", rugosidadMm: 0.0048, coeficienteHazenWilliams: 148, coeficienteManning: 0.010),
        MaterialTuberia(nombre: "Asbesto cemento", rugosidadMm: 0.03, coeficienteHazenWilliams: 147, coeficienteManning: 0.011),
        MaterialTuberia(nombre: "Acero nuevo", rugosidadMm: 0.045, coeficienteHazenWilliams: 145, coeficienteManning: 0.011),
        MaterialTuberia(nombre: "Hierro fundido asfaltado", rugosidadMm: 0.12, coeficienteHazenWilliams: 148, coeficienteManning: 0.012),
        MaterialTuberia(nombre: "Acero galvanizado", rugosidadMm: 0.15, coeficienteHazenWilliams: 120, coeficienteManning: 0.016),
        MaterialTuberia(nombre: "Hierro fundido", rugosidadMm: 0.15, coeficienteHazenWilliams: 130, coeficienteManning: 0.012),
        MaterialTuberia(nombre: "Hierro galvanizado", rugosidadMm: 0.15, coeficienteHazenWilliams: 133, coeficienteManning: 0.016),
        MaterialTuberia(nombre: "Madera (duelas)", rugosidadMm: 0.18, coeficienteHazenWilliams: 120, coeficienteManning: 0.012),
        MaterialTuberia(nombre: "Concreto (cimbra metálica)", rugosidadMm: 0.18, coeficienteHazenWilliams: 140, coeficienteManning: 0.013),
        MaterialTuberia(nombre: "Hierro dúctil", rugosidadMm: 0.25, coeficienteHazenWilliams: 135, coeficienteManning: 0.022),
        MaterialTuberia(nombre: "Concreto simple", rugosidadMm: 0.36, coeficienteHazenWilliams: 135, coeficienteManning: 0.013),
        MaterialTuberia(nombre: "Concreto (cimbra madera)", rugosidadMm: 0.6, coeficienteHazenWilliams: 120, coeficienteManning: 0.015),
        MaterialTuberia(nombre: "Acero remachado", rugosidadMm: 0.9, coeficienteHazenWilliams: 110, coeficienteManning: 0.010),
    ]

    static let porDefecto: MaterialTuberia = todos[0]

    static func porNombre(_ nombre: String) -> MaterialTuberia {
        todos.first { $0.nombre == nombre } ?? porDefecto
    }
}

struct MaterialElastico: Identifiable, Hashable {
    let nombre: String
    /// Módulo de elasticidad de Young [GPa].
    let moduloYoungGPa: Double

    var id: String { nombre }
    var moduloYoungPa: Double { moduloYoungGPa * 1e9 }
}

enum CatalogoMaterialesElasticos {
    static let todos: [MaterialElastico] = [
        MaterialElastico(nombre: "PVC", moduloYoungGPa: 3.3),
        MaterialElastico(nombre: "PEAD", moduloYoungGPa: 0.8),
        MaterialElastico(nombre: "PRFV", moduloYoungGPa: 15),
        MaterialElastico(nombre: "Asbesto cemento", moduloYoungGPa: 24),
        MaterialElastico(nombre: "Concreto", moduloYoungGPa: 25),
        MaterialElastico(nombre: "Concreto reforzado", moduloYoungGPa: 45),
        MaterialElastico(nombre: "Hierro fundido", moduloYoungGPa: 90),
        MaterialElastico(nombre: "Hierro dúctil", moduloYoungGPa: 172),
        MaterialElastico(nombre: "Acero", moduloYoungGPa: 207),
    ]

    static let porDefecto: MaterialElastico = todos[0]

    static func porNombre(_ nombre: String) -> MaterialElastico {
        todos.first { $0.nombre == nombre } ?? porDefecto
    }
}

func descripcionMaterial(_ material: MaterialTuberia) -> String {
    "ε = \(Formato.auto(material.rugosidadMm, decimales: 4)) mm   ·   C = \(Formato.numero(material.coeficienteHazenWilliams, decimales: 0))   ·   n = \(Formato.numero(material.coeficienteManning, decimales: 3))"
}

func descripcionMaterialElastico(_ material: MaterialElastico) -> String {
    "E = \(Formato.numero(material.moduloYoungGPa, decimales: 1)) GPa"
}
