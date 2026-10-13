import Foundation

/// Color semántico de un renglón; la vista lo traduce a la paleta.
enum Tono: Equatable {
    case normal
    case subcritico
    case critico
    case supercritico
}

struct Renglon: Identifiable, Equatable {
    let etiqueta: String
    let valor: String
    var destacado: Bool = false
    var nota: String?
    var tono: Tono = .normal

    var id: String { etiqueta }
}

/// Parte de la carga disponible H que consume cada término de la ecuación de la energía.
struct SegmentoCarga: Identifiable, Equatable {
    enum Tipo: String {
        case friccion = "Fricción"
        case locales = "Locales"
        case velocidad = "Velocidad"
    }

    let tipo: Tipo
    let metros: Double
    let fraccion: Double

    var id: String { tipo.rawValue }
}

struct ContrasteMetodo: Identifiable, Equatable {
    let metodo: MetodoFriccion
    let perdida: Double
    /// Diferencia porcentual respecto a Darcy-Weisbach; nil para Darcy.
    let diferenciaPorcentual: Double?

    var id: String { metodo.rawValue }
}

/// Lo que muestra el panel de resultados tras pulsar calcular.
struct SalidaCalculo: Equatable {
    var renglones: [Renglon] = []
    var error: String?
    var advertencias: [String] = []
    var reparto: [SegmentoCarga] = []
    var comparativa: [ContrasteMetodo] = []

    static let vacia = SalidaCalculo()

    static func fallo(_ mensaje: String) -> SalidaCalculo {
        SalidaCalculo(error: mensaje)
    }

    var hayResultado: Bool { error == nil && !renglones.isEmpty }

    var principal: Renglon? { renglones.first { $0.destacado } }

    /// Texto para copiar o compartir.
    func textoCompartible(titulo: String) -> String {
        var lineas = ["HidroFES Flow · \(titulo)"]
        lineas += renglones.map { "\($0.etiqueta): \($0.valor)" }
        if !advertencias.isEmpty {
            lineas.append("")
            lineas += advertencias.map { "Aviso: \($0)" }
        }
        return lineas.joined(separator: "\n")
    }

    static func repartoDeCarga(friccion: Double, locales: Double, velocidad: Double) -> [SegmentoCarga] {
        let total = friccion + locales + velocidad
        guard total > 0, total.isFinite else { return [] }
        return [
            SegmentoCarga(tipo: .friccion, metros: friccion, fraccion: friccion / total),
            SegmentoCarga(tipo: .locales, metros: locales, fraccion: locales / total),
            SegmentoCarga(tipo: .velocidad, metros: velocidad, fraccion: velocidad / total),
        ]
    }
}

/// Une advertencias sin repetirlas, conservando el orden.
func unicas(_ avisos: [String]) -> [String] {
    var vistos = Set<String>()
    return avisos.filter { vistos.insert($0).inserted }
}
