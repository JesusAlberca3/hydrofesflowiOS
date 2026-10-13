import Foundation

enum RegimenFlujo: String {
    case laminar = "Laminar"
    case transicion = "Transición"
    case turbulento = "Turbulento"

    var etiqueta: String { rawValue }
}

func etiquetaRegimenFlujo(_ regimen: RegimenFlujo) -> String {
    switch regimen {
    case .laminar: "Laminar (Re < 2300)"
    case .transicion: "Transición (2300 < Re < 4000)"
    case .turbulento: "Turbulento (Re > 4000)"
    }
}

/// Factor de fricción de Darcy-Weisbach: laminar, transición interpolada y Swamee-Jain.
enum Friccion {
    static let reynoldsLaminarMax = 2300.0
    static let reynoldsTurbulentoMin = 4000.0

    static func reynolds(
        velocidad: Double,
        diametroM: Double,
        viscosidad: Double = Constantes.viscosidadCinematica
    ) -> Double {
        velocidad * diametroM / viscosidad
    }

    static func regimen(_ reynolds: Double) -> RegimenFlujo {
        if reynolds < reynoldsLaminarMax { return .laminar }
        if reynolds < reynoldsTurbulentoMin { return .transicion }
        return .turbulento
    }

    /// Aproximación explícita de Swamee-Jain (válida para 5000 ≤ Re ≤ 1e8).
    static func swameeJain(rugosidadM: Double, diametroM: Double, reynolds: Double) -> Double {
        0.25 / pow(log10(rugosidadM / (3.7 * diametroM) + 5.74 / pow(reynolds, 0.9)), 2)
    }

    /// Solución iterativa de Colebrook-White. Referencia de las pruebas.
    static func colebrookWhite(
        rugosidadM: Double,
        diametroM: Double,
        reynolds: Double,
        iteraciones: Int = 50
    ) -> Double {
        var f = swameeJain(rugosidadM: rugosidadM, diametroM: diametroM, reynolds: reynolds)
        for _ in 0..<iteraciones {
            let raiz = -2.0 * log10(rugosidadM / (3.7 * diametroM) + 2.51 / (reynolds * sqrt(f)))
            f = 1.0 / (raiz * raiz)
        }
        return f
    }

    /// Factor de fricción cubriendo los tres regímenes.
    static func factorFriccion(rugosidadM: Double, diametroM: Double, reynolds: Double) -> Double {
        if reynolds <= 0 { return 0 }
        if reynolds < reynoldsLaminarMax { return 64.0 / reynolds }
        if reynolds < reynoldsTurbulentoMin {
            let fLaminar = 64.0 / reynoldsLaminarMax
            let fTurbulento = swameeJain(
                rugosidadM: rugosidadM,
                diametroM: diametroM,
                reynolds: reynoldsTurbulentoMin
            )
            let t = (reynolds - reynoldsLaminarMax) / (reynoldsTurbulentoMin - reynoldsLaminarMax)
            return fLaminar + t * (fTurbulento - fLaminar)
        }
        return swameeJain(rugosidadM: rugosidadM, diametroM: diametroM, reynolds: reynolds)
    }
}
