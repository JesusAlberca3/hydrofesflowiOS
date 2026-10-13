import Foundation

enum MetodoFriccion: String, CaseIterable, Identifiable {
    case darcyWeisbach
    case hazenWilliams
    case chezyManning

    var id: String { rawValue }

    var etiqueta: String {
        switch self {
        case .darcyWeisbach: "Darcy-Weisbach"
        case .hazenWilliams: "Hazen-Williams"
        case .chezyManning: "Chézy-Manning"
        }
    }

    var etiquetaCorta: String {
        switch self {
        case .darcyWeisbach: "Darcy"
        case .hazenWilliams: "Hazen"
        case .chezyManning: "Manning"
        }
    }

    var descripcion: String {
        switch self {
        case .darcyWeisbach:
            "Universal. Válido para cualquier fluido y régimen; requiere la rugosidad absoluta ε."
        case .hazenWilliams:
            "Empírico para agua a temperatura ambiente, D ≥ 50 mm y V entre 0.6 y 3 m/s."
        case .chezyManning:
            "Deriva de flujo en canales; aplicado a tubo lleno con R = D/4."
        }
    }
}

struct PerdidaFriccion: Equatable {
    let metodo: MetodoFriccion
    /// Pérdida de carga h_f [m].
    let perdidaM: Double
    let area: Double
    let velocidad: Double
    /// Gradiente hidráulico S = h_f / L [m/m].
    let gradienteHidraulico: Double
    /// Carga de velocidad V²/2g [m].
    let cargaVelocidad: Double
    let reynolds: Double?
    let factorFriccion: Double?
    let regimen: RegimenFlujo?
}

enum PerdidasFriccion {
    /// 4^(10/3) / π², redondeada como en el proyecto Android.
    static let constanteManning = 10.2937

    static func darcyWeisbach(
        longitudM: Double,
        diametroM: Double,
        rugosidadMm: Double,
        caudalM3s: Double
    ) -> Resultado<PerdidaFriccion> {
        if let error = validarConducto(longitudM, diametroM, caudalM3s) { return error }
        if !Validacion.noNegativo(rugosidadMm) { return .error(Errores.rugosidadInvalida) }

        let area = areaCircular(diametroM)
        let velocidad = caudalM3s / area
        let reynolds = Friccion.reynolds(velocidad: velocidad, diametroM: diametroM)
        let f = Friccion.factorFriccion(rugosidadM: rugosidadMm / 1000, diametroM: diametroM, reynolds: reynolds)
        let cargaVelocidad = velocidad * velocidad / (2 * Constantes.gravedad)
        let perdida = f * (longitudM / diametroM) * cargaVelocidad
        let regimen = Friccion.regimen(reynolds)
        if !resultadoValido(area: area, velocidad: velocidad, perdida: perdida, cargaVelocidad: cargaVelocidad, longitudM: longitudM)
            || !Validacion.finitos(reynolds, f) || f <= 0 {
            return .error(Errores.fueraDeRango)
        }

        var advertencias: [String] = []
        if regimen == .transicion {
            advertencias.append(
                "Re = \(Formato.cientifico(reynolds)) cae en la zona crítica (2300–4000): el factor de fricción es incierto."
            )
        }

        return .exito(
            PerdidaFriccion(
                metodo: .darcyWeisbach,
                perdidaM: perdida,
                area: area,
                velocidad: velocidad,
                gradienteHidraulico: perdida / longitudM,
                cargaVelocidad: cargaVelocidad,
                reynolds: reynolds,
                factorFriccion: f,
                regimen: regimen
            ),
            advertencias: advertencias
        )
    }

    /// Hazen-Williams en SI: h_f = 10.674 · L · (Q/C)^1.852 / D^4.871.
    static func hazenWilliams(
        longitudM: Double,
        diametroM: Double,
        coeficienteC: Double,
        caudalM3s: Double
    ) -> Resultado<PerdidaFriccion> {
        if let error = validarConducto(longitudM, diametroM, caudalM3s) { return error }
        if !Validacion.positivo(coeficienteC) { return .error(Errores.coeficienteInvalido) }

        let area = areaCircular(diametroM)
        let velocidad = caudalM3s / area
        let perdida = 10.674 * longitudM * pow(caudalM3s / coeficienteC, 1.852) / pow(diametroM, 4.871)
        let cargaVelocidad = velocidad * velocidad / (2 * Constantes.gravedad)
        if !resultadoValido(area: area, velocidad: velocidad, perdida: perdida, cargaVelocidad: cargaVelocidad, longitudM: longitudM) {
            return .error(Errores.fueraDeRango)
        }

        var advertencias: [String] = []
        if diametroM < 0.05 {
            advertencias.append("Hazen-Williams pierde validez para diámetros menores a 50 mm.")
        }
        if velocidad < 0.6 || velocidad > 3 {
            advertencias.append(
                "V = \(Formato.numero(velocidad, decimales: 2)) m/s está fuera del rango recomendado (0.6 a 3.0 m/s) para Hazen-Williams."
            )
        }

        return .exito(
            PerdidaFriccion(
                metodo: .hazenWilliams,
                perdidaM: perdida,
                area: area,
                velocidad: velocidad,
                gradienteHidraulico: perdida / longitudM,
                cargaVelocidad: cargaVelocidad,
                reynolds: nil,
                factorFriccion: nil,
                regimen: nil
            ),
            advertencias: advertencias
        )
    }

    /// Chézy-Manning en tubo lleno: h_f = 10.2937 · n² · L · Q² / D^(16/3).
    static func chezyManning(
        longitudM: Double,
        diametroM: Double,
        coeficienteN: Double,
        caudalM3s: Double
    ) -> Resultado<PerdidaFriccion> {
        if let error = validarConducto(longitudM, diametroM, caudalM3s) { return error }
        if !Validacion.positivo(coeficienteN) { return .error(Errores.coeficienteInvalido) }

        let area = areaCircular(diametroM)
        let velocidad = caudalM3s / area
        let perdida = constanteManning * coeficienteN * coeficienteN * longitudM
            * caudalM3s * caudalM3s / pow(diametroM, 16.0 / 3.0)
        let cargaVelocidad = velocidad * velocidad / (2 * Constantes.gravedad)
        if !resultadoValido(area: area, velocidad: velocidad, perdida: perdida, cargaVelocidad: cargaVelocidad, longitudM: longitudM) {
            return .error(Errores.fueraDeRango)
        }

        return .exito(
            PerdidaFriccion(
                metodo: .chezyManning,
                perdidaM: perdida,
                area: area,
                velocidad: velocidad,
                gradienteHidraulico: perdida / longitudM,
                cargaVelocidad: cargaVelocidad,
                reynolds: nil,
                factorFriccion: nil,
                regimen: nil
            ),
            advertencias: []
        )
    }

    static func areaCircular(_ diametroM: Double) -> Double {
        Double.pi * diametroM * diametroM / 4
    }

    private static func validarConducto(
        _ longitudM: Double,
        _ diametroM: Double,
        _ caudalM3s: Double
    ) -> Resultado<PerdidaFriccion>? {
        if !Validacion.positivo(longitudM) { return .error(Errores.longitudInvalida) }
        if !Validacion.positivo(diametroM) { return .error(Errores.diametroInvalido) }
        if !Validacion.positivo(caudalM3s) { return .error(Errores.caudalInvalido) }
        return nil
    }

    /// Descarta desbordamientos (∞, NaN) y subdesbordamientos que dejan el área en cero.
    private static func resultadoValido(
        area: Double,
        velocidad: Double,
        perdida: Double,
        cargaVelocidad: Double,
        longitudM: Double
    ) -> Bool {
        Validacion.positivo(area) && Validacion.positivo(velocidad)
            && Validacion.noNegativo(perdida) && Validacion.noNegativo(cargaVelocidad)
            && (perdida / longitudM).isFinite
    }
}
