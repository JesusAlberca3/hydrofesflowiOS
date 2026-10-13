import Foundation

enum CategoriaAccesorio: String, CaseIterable, Identifiable {
    case valvulas
    case codosCurvas
    case derivaciones
    case entradasSalidas

    var id: String { rawValue }

    var etiqueta: String {
        switch self {
        case .valvulas: "Válvulas"
        case .codosCurvas: "Codos y curvas"
        case .derivaciones: "Derivaciones"
        case .entradasSalidas: "Entradas y salidas"
        }
    }
}

struct Accesorio: Identifiable, Hashable {
    let nombre: String
    let coeficienteK: Double
    let categoria: CategoriaAccesorio

    var id: String { nombre }
}

struct AccesorioSeleccionado: Identifiable, Hashable {
    var accesorio: Accesorio
    var cantidad: Int = 0

    var id: String { accesorio.nombre }
    var aporteK: Double { Double(cantidad) * accesorio.coeficienteK }
}

enum CatalogoAccesorios {
    static let todos: [Accesorio] = [
        Accesorio(nombre: "Válvula de globo abierta", coeficienteK: 10, categoria: .valvulas),
        Accesorio(nombre: "Válvula check totalmente abierta", coeficienteK: 2.5, categoria: .valvulas),
        Accesorio(nombre: "Válvula en ángulo completamente abierta", coeficienteK: 5, categoria: .valvulas),
        Accesorio(nombre: "Válvula de compuerta totalmente abierta", coeficienteK: 0.2, categoria: .valvulas),
        Accesorio(nombre: "Válvula de compuerta con ¾ de apertura", coeficienteK: 1.5, categoria: .valvulas),
        Accesorio(nombre: "Válvula de compuerta con ½ de apertura", coeficienteK: 5.6, categoria: .valvulas),
        Accesorio(nombre: "Válvula de compuerta con ¼ de apertura", coeficienteK: 24, categoria: .valvulas),
        Accesorio(nombre: "Codo de 90°", coeficienteK: 0.9, categoria: .codosCurvas),
        Accesorio(nombre: "Codo de 45°", coeficienteK: 0.42, categoria: .codosCurvas),
        Accesorio(nombre: "Retorno (curva en U)", coeficienteK: 2.2, categoria: .codosCurvas),
        Accesorio(nombre: "Tee en sentido recto", coeficienteK: 0.3, categoria: .derivaciones),
        Accesorio(nombre: "Tee a través de la salida lateral", coeficienteK: 1.8, categoria: .derivaciones),
        Accesorio(nombre: "Ye de 45°, en sentido recto", coeficienteK: 0.3, categoria: .derivaciones),
        Accesorio(nombre: "Ye de 45°, en salida lateral", coeficienteK: 0.8, categoria: .derivaciones),
        Accesorio(nombre: "Unión", coeficienteK: 0.3, categoria: .derivaciones),
        Accesorio(nombre: "Pérdida por entrada brusca", coeficienteK: 0.8, categoria: .entradasSalidas),
        Accesorio(nombre: "Pérdida por entrada gradual", coeficienteK: 0.2, categoria: .entradasSalidas),
        Accesorio(nombre: "Pérdida por pichancha", coeficienteK: 5.5, categoria: .entradasSalidas),
        Accesorio(nombre: "Salida", coeficienteK: 1, categoria: .entradasSalidas),
    ]

    static var seleccionInicial: [AccesorioSeleccionado] {
        todos.map { AccesorioSeleccionado(accesorio: $0) }
    }
}

struct PerdidaLocal {
    let coeficienteKTotal: Double
    let perdidaM: Double
    let velocidad: Double
    let area: Double
    let cargaVelocidad: Double
    let longitudEquivalenteM: Double?
}

enum PerdidasLocales {
    /// h_L = ΣK · V²/(2g). Si se aporta f, L_eq = ΣK · D / f.
    static func calcular(
        caudalM3s: Double,
        diametroM: Double,
        coeficienteKTotal: Double,
        factorFriccion: Double? = nil
    ) -> Resultado<PerdidaLocal> {
        if diametroM <= 0 { return .error(Errores.diametroInvalido) }
        if caudalM3s <= 0 { return .error(Errores.caudalInvalido) }

        let area = PerdidasFriccion.areaCircular(diametroM)
        let velocidad = caudalM3s / area
        let cargaVelocidad = velocidad * velocidad / (2 * Constantes.gravedad)
        let perdida = coeficienteKTotal * cargaVelocidad
        let longitudEquivalente = factorFriccion.flatMap { f -> Double? in
            f > 0 ? coeficienteKTotal * diametroM / f : nil
        }

        var advertencias: [String] = []
        if coeficienteKTotal <= 0 {
            advertencias.append("No has seleccionado ningún accesorio: ΣK = 0, la pérdida local es nula.")
        }

        return .exito(
            PerdidaLocal(
                coeficienteKTotal: coeficienteKTotal,
                perdidaM: perdida,
                velocidad: velocidad,
                area: area,
                cargaVelocidad: cargaVelocidad,
                longitudEquivalenteM: longitudEquivalente
            ),
            advertencias: advertencias
        )
    }
}
