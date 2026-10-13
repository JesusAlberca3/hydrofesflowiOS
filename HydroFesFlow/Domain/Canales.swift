import Foundation

enum GeometriaCanal: String, CaseIterable, Identifiable {
    case rectangular
    case triangular
    case trapezoidal
    case circular

    var id: String { rawValue }

    var etiqueta: String {
        switch self {
        case .rectangular: "Rectangular"
        case .triangular: "Triangular"
        case .trapezoidal: "Trapezoidal"
        case .circular: "Circular"
        }
    }
}

enum RegimenCanal: String {
    case subcritico = "Subcrítico"
    case critico = "Crítico"
    case supercritico = "Supercrítico"

    var etiqueta: String { rawValue }

    var nota: String {
        switch self {
        case .subcritico: "Fr < 1: el control está aguas abajo"
        case .supercritico: "Fr > 1: el control está aguas arriba"
        case .critico: "Fr ≈ 1: energía específica mínima"
        }
    }
}

struct SeccionMojada {
    let area: Double
    let perimetroMojado: Double
    let espejoAgua: Double

    var radioHidraulico: Double { area / perimetroMojado }

    /// Profundidad hidráulica A/T. Nil si el espejo se anula.
    var profundidadHidraulica: Double? {
        espejoAgua > 1e-9 ? area / espejoAgua : nil
    }
}

struct DatosCanal {
    var geometria: GeometriaCanal
    var pendiente: Double
    var manning: Double
    var tirante: Double
    var anchoPlantilla: Double = 0
    var talud: Double = 0
    var diametro: Double = 0

    func conTirante(_ tirante: Double) -> DatosCanal {
        var copia = self
        copia.tirante = tirante
        return copia
    }
}

struct ResultadoCanal {
    let area: Double
    let perimetroMojado: Double
    let radioHidraulico: Double
    let espejoAgua: Double
    let profundidadHidraulica: Double?
    let caudal: Double
    let velocidad: Double
    let energiaEspecifica: Double
    let numeroFroude: Double?
    let regimen: RegimenCanal?
    let tiranteCritico: Double?
    let relacionLlenado: Double?
}

/// Flujo uniforme por Manning y tirante crítico por bisección.
enum Canales {
    private static let maxRelacionLlenado = 0.999

    static func calcular(_ datos: DatosCanal) -> Resultado<ResultadoCanal> {
        if let error = validar(datos) { return error }
        guard let seccion = seccionMojada(datos) else {
            return .error(Errores.datosIncompletos)
        }
        if !Validacion.positivo(seccion.area) || !Validacion.positivo(seccion.perimetroMojado)
            || !seccion.espejoAgua.isFinite {
            return .error(Errores.geometriaInvalida)
        }

        let radio = seccion.radioHidraulico
        let caudal = (1 / datos.manning) * seccion.area * pow(radio, 2.0 / 3.0) * sqrt(datos.pendiente)
        let velocidad = caudal / seccion.area
        let energia = datos.tirante + velocidad * velocidad / (2 * Constantes.gravedad)
        let profundidad = seccion.profundidadHidraulica
        let froude = profundidad.map { velocidad / sqrt(Constantes.gravedad * $0) }
        guard Validacion.positivo(radio), Validacion.positivo(caudal), Validacion.positivo(velocidad),
              Validacion.finitos(energia, profundidad, froude) else {
            return .error(Errores.fueraDeRango)
        }
        let critico = tiranteCritico(datos, caudal: caudal).flatMap(Validacion.opcionalPositivo)

        var advertencias: [String] = []
        if profundidad == nil {
            advertencias.append(
                "Con y ≈ D el espejo de agua tiende a cero: la sección trabaja llena y el número de Froude deja de estar definido. Usa el módulo de conductos a presión."
            )
        }
        if datos.geometria == .circular {
            let llenado = datos.tirante / datos.diametro
            if llenado > 0.94 {
                advertencias.append(
                    "Por encima de y/D ≈ 0.938 el gasto disminuye al aumentar el tirante (zona inestable del conducto parcialmente lleno)."
                )
            }
        }
        if let froude, abs(froude - 1) < 0.05 {
            advertencias.append("Fr ≈ 1: el flujo está próximo al estado crítico y la superficie libre es inestable.")
        }

        return .exito(
            ResultadoCanal(
                area: seccion.area,
                perimetroMojado: seccion.perimetroMojado,
                radioHidraulico: radio,
                espejoAgua: seccion.espejoAgua,
                profundidadHidraulica: profundidad,
                caudal: caudal,
                velocidad: velocidad,
                energiaEspecifica: energia,
                numeroFroude: froude,
                regimen: froude.map(clasificarRegimen),
                tiranteCritico: critico,
                relacionLlenado: datos.geometria == .circular ? datos.tirante / datos.diametro : nil
            ),
            advertencias: advertencias
        )
    }

    static func clasificarRegimen(_ froude: Double) -> RegimenCanal {
        if froude < 0.995 { return .subcritico }
        if froude > 1.005 { return .supercritico }
        return .critico
    }

    static func seccionMojada(_ datos: DatosCanal) -> SeccionMojada? {
        let y = datos.tirante
        switch datos.geometria {
        case .rectangular:
            let b = datos.anchoPlantilla
            return SeccionMojada(area: b * y, perimetroMojado: b + 2 * y, espejoAgua: b)
        case .triangular:
            let z = datos.talud
            return SeccionMojada(
                area: z * y * y,
                perimetroMojado: 2 * y * sqrt(1 + z * z),
                espejoAgua: 2 * z * y
            )
        case .trapezoidal:
            let b = datos.anchoPlantilla
            let z = datos.talud
            return SeccionMojada(
                area: y * (b + z * y),
                perimetroMojado: b + 2 * y * sqrt(1 + z * z),
                espejoAgua: b + 2 * z * y
            )
        case .circular:
            let d = datos.diametro
            if d <= 0 || y > d { return nil }
            let theta = 2 * acos(min(1, max(-1, 1 - 2 * y / d)))
            return SeccionMojada(
                area: (d * d / 8) * (theta - sin(theta)),
                perimetroMojado: (d / 2) * theta,
                espejoAgua: d * sin(theta / 2)
            )
        }
    }

    /// Bisección de Q²·T/(g·A³) − 1 = 0. Conserva el criterio de signo del proyecto Android.
    static func tiranteCritico(_ datos: DatosCanal, caudal: Double) -> Double? {
        if caudal <= 0 { return nil }

        let limiteSuperior: Double
        switch datos.geometria {
        case .circular:
            limiteSuperior = datos.diametro * maxRelacionLlenado
        default:
            limiteSuperior = max(datos.tirante * 20, 100)
        }

        func f(_ y: Double) -> Double? {
            guard let seccion = seccionMojada(datos.conTirante(y)) else { return nil }
            if seccion.area <= 1e-12 || seccion.espejoAgua <= 1e-12 { return nil }
            return caudal * caudal * seccion.espejoAgua / (Constantes.gravedad * pow(seccion.area, 3)) - 1
        }

        var inferior = 1e-6
        var superior = limiteSuperior
        guard let fInferior = f(inferior), let fSuperior = f(superior) else { return nil }
        if fInferior * fSuperior > 0 { return nil }

        for _ in 0..<120 {
            let medio = 0.5 * (inferior + superior)
            guard let fMedio = f(medio) else { return nil }
            if fInferior * fMedio <= 0 {
                superior = medio
            } else {
                inferior = medio
            }
        }
        return 0.5 * (inferior + superior)
    }

    private static func validar(_ datos: DatosCanal) -> Resultado<ResultadoCanal>? {
        if !Validacion.positivo(datos.pendiente) { return .error(Errores.pendienteInvalida) }
        if !Validacion.positivo(datos.manning) { return .error(Errores.manningInvalido) }
        if !Validacion.positivo(datos.tirante) { return .error(Errores.tiranteInvalido) }
        switch datos.geometria {
        case .rectangular:
            if !Validacion.positivo(datos.anchoPlantilla) { return .error(Errores.anchoInvalido) }
        case .triangular:
            if !Validacion.positivo(datos.talud) { return .error(Errores.taludInvalido) }
        case .trapezoidal:
            if !Validacion.noNegativo(datos.anchoPlantilla) || !Validacion.positivo(datos.talud) {
                return .error(Errores.trapecioInvalido)
            }
        case .circular:
            if !Validacion.positivo(datos.diametro) { return .error(Errores.diametroInvalido) }
            if datos.tirante > datos.diametro { return .error(Errores.tiranteCircular) }
        }
        return nil
    }
}
