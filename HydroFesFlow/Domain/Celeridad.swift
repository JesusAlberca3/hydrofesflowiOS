import Foundation

struct ResultadoCeleridad {
    /// Celeridad de la onda de presión a [m/s].
    let celeridad: Double
    /// Celeridad teórica en medio indefinido √(K/ρ) [m/s].
    let celeridadAguaLibre: Double
    /// Sobrepresión de Joukowsky por cada 1 m/s de cierre brusco [m].
    let sobrepresionPorMetroSegundo: Double
    /// Tiempo crítico 2L/a [s].
    let tiempoCriticoS: Double?
    /// Sobrepresión para la velocidad de régimen indicada [m].
    let sobrepresionJoukowskyM: Double?
}

/// Celeridad de Allievi-Korteweg: a = 1 / √( ρ · ( 1/K + D/(E·e) ) ).
enum Celeridad {
    static func calcular(
        diametroInteriorM: Double,
        espesorM: Double,
        moduloYoungPa: Double,
        longitudConduccionM: Double? = nil,
        velocidadRegimen: Double? = nil
    ) -> Resultado<ResultadoCeleridad> {
        if diametroInteriorM <= 0 { return .error(Errores.diametroInvalido) }
        if espesorM <= 0 { return .error(Errores.espesorInvalido) }
        if moduloYoungPa <= 0 { return .error(Errores.materialInvalido) }

        let rho = Constantes.densidadAgua
        let k = Constantes.moduloVolumetricoAgua
        let celeridad = 1 / sqrt(rho * (1 / k + diametroInteriorM / (moduloYoungPa * espesorM)))
        let celeridadLibre = sqrt(k / rho)

        var advertencias: [String] = []
        let relacion = diametroInteriorM / espesorM
        if relacion > 200 {
            advertencias.append(
                "La relación D/e = \(Formato.numero(relacion, decimales: 1)) es muy alta; verifica el espesor introducido."
            )
        }
        if relacion < 5 {
            advertencias.append(
                "La relación D/e = \(Formato.numero(relacion, decimales: 1)) corresponde a pared gruesa; la hipótesis de pared delgada de Allievi pierde precisión."
            )
        }

        let tiempo = longitudConduccionM.flatMap { longitud -> Double? in
            longitud > 0 ? 2 * longitud / celeridad : nil
        }
        let joukowsky = velocidadRegimen.flatMap { velocidad -> Double? in
            velocidad > 0 ? celeridad * velocidad / Constantes.gravedad : nil
        }

        return .exito(
            ResultadoCeleridad(
                celeridad: celeridad,
                celeridadAguaLibre: celeridadLibre,
                sobrepresionPorMetroSegundo: celeridad / Constantes.gravedad,
                tiempoCriticoS: tiempo,
                sobrepresionJoukowskyM: joukowsky
            ),
            advertencias: advertencias
        )
    }
}
