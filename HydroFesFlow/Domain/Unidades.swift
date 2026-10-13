import Foundation

/// Unidades de longitud. El dominio trabaja en metros.
enum UnidadLongitud: String, CaseIterable, Identifiable {
    case milimetro
    case centimetro
    case metro
    case pulgada
    case pie

    var id: String { rawValue }

    var etiqueta: String {
        switch self {
        case .milimetro: "mm"
        case .centimetro: "cm"
        case .metro: "m"
        case .pulgada: "in"
        case .pie: "ft"
        }
    }

    var factorAMetros: Double {
        switch self {
        case .milimetro: 1e-3
        case .centimetro: 1e-2
        case .metro: 1
        case .pulgada: 0.0254
        case .pie: 0.3048
        }
    }

    func aMetros(_ valor: Double) -> Double { valor * factorAMetros }

    func desdeMetros(_ metros: Double) -> Double { metros / factorAMetros }
}

/// Unidades de caudal. El dominio trabaja en m³/s.
enum UnidadCaudal: String, CaseIterable, Identifiable {
    case litroSegundo
    case metro3Segundo
    case metro3Hora
    case galonMinuto

    var id: String { rawValue }

    var etiqueta: String {
        switch self {
        case .litroSegundo: "L/s"
        case .metro3Segundo: "m³/s"
        case .metro3Hora: "m³/h"
        case .galonMinuto: "gal/min"
        }
    }

    var factorAM3s: Double {
        switch self {
        case .litroSegundo: 1e-3
        case .metro3Segundo: 1
        case .metro3Hora: 1.0 / 3600.0
        case .galonMinuto: 6.309_02e-5
        }
    }

    func aM3s(_ valor: Double) -> Double { valor * factorAM3s }

    func desdeM3s(_ m3s: Double) -> Double { m3s / factorAM3s }
}
