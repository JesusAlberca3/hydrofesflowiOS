import Foundation

/// Conducción por gravedad entre dos depósitos o hacia descarga libre.
///
/// H = (1 + f·L/D + ΣK) · V²/(2g)
///
/// El 1 es la carga de velocidad en la descarga. Caudal y diámetro usan la misma ecuación.
enum FlujoGravedad {
    private static let toleranciaFriccion = 1e-10
    private static let toleranciaDiametro = 1e-10
    private static let maxIteraciones = 200
    private static let diametroInicial = 0.5

    struct ResultadoCaudal {
        let caudalM3s: Double
        let velocidad: Double
        let area: Double
        let factorFriccion: Double
        let reynolds: Double
        let regimen: RegimenFlujo
        let perdidaFriccionM: Double
        let perdidaLocalM: Double
        let cargaVelocidadM: Double
        let iteraciones: Int
    }

    struct ResultadoDiametro {
        let diametroM: Double
        let velocidad: Double
        let area: Double
        let factorFriccion: Double
        let reynolds: Double
        let regimen: RegimenFlujo
        let perdidaFriccionM: Double
        let perdidaLocalM: Double
        let cargaVelocidadM: Double
        let iteraciones: Int
    }

    static func caudal(
        diametroM: Double,
        longitudM: Double,
        rugosidadMm: Double,
        cargaDisponibleM: Double,
        sumaK: Double
    ) -> Resultado<ResultadoCaudal> {
        if !Validacion.positivo(diametroM) { return .error(Errores.diametroInvalido) }
        if !Validacion.positivo(longitudM) { return .error(Errores.longitudInvalida) }
        if !Validacion.positivo(cargaDisponibleM) { return .error(Errores.cargaInvalida) }
        if !Validacion.noNegativo(sumaK) { return .error(Errores.kNegativo) }
        if !Validacion.noNegativo(rugosidadMm) { return .error(Errores.rugosidadInvalida) }

        let rugosidadM = rugosidadMm / 1000
        var f = 0.02
        var velocidad = 0.0
        var reynolds = 0.0
        var iteraciones = 0
        var delta = 0.0

        repeat {
            velocidad = velocidadPorEnergia(cargaDisponibleM, f, longitudM, diametroM, sumaK)
            reynolds = Friccion.reynolds(velocidad: velocidad, diametroM: diametroM)
            let fNuevo = Friccion.factorFriccion(rugosidadM: rugosidadM, diametroM: diametroM, reynolds: reynolds)
            delta = abs(fNuevo - f)
            f = fNuevo
            iteraciones += 1
        } while delta > toleranciaFriccion && iteraciones < maxIteraciones

        if !velocidad.isFinite || velocidad <= 0 {
            return .error(Errores.sinConvergencia)
        }

        velocidad = velocidadPorEnergia(cargaDisponibleM, f, longitudM, diametroM, sumaK)
        let area = Double.pi * diametroM * diametroM / 4
        let cargaVelocidad = velocidad * velocidad / (2 * Constantes.gravedad)
        let caudal = area * velocidad
        let perdidaFriccion = f * (longitudM / diametroM) * cargaVelocidad
        let perdidaLocal = sumaK * cargaVelocidad

        guard Validacion.positivo(caudal), Validacion.positivo(velocidad), Validacion.positivo(f),
              Validacion.finitos(reynolds, perdidaFriccion, perdidaLocal, cargaVelocidad) else {
            return .error(Errores.fueraDeRango)
        }

        return .exito(
            ResultadoCaudal(
                caudalM3s: caudal,
                velocidad: velocidad,
                area: area,
                factorFriccion: f,
                reynolds: reynolds,
                regimen: Friccion.regimen(reynolds),
                perdidaFriccionM: perdidaFriccion,
                perdidaLocalM: perdidaLocal,
                cargaVelocidadM: cargaVelocidad,
                iteraciones: iteraciones
            ),
            advertencias: advertenciasVelocidad(velocidad)
        )
    }

    static func diametro(
        caudalM3s: Double,
        longitudM: Double,
        rugosidadMm: Double,
        cargaDisponibleM: Double,
        sumaK: Double
    ) -> Resultado<ResultadoDiametro> {
        if !Validacion.positivo(caudalM3s) { return .error(Errores.caudalInvalido) }
        if !Validacion.positivo(longitudM) { return .error(Errores.longitudInvalida) }
        if !Validacion.positivo(cargaDisponibleM) { return .error(Errores.cargaInvalida) }
        if !Validacion.noNegativo(sumaK) { return .error(Errores.kNegativo) }
        if !Validacion.noNegativo(rugosidadMm) { return .error(Errores.rugosidadInvalida) }

        let rugosidadM = rugosidadMm / 1000
        var diametro = diametroInicial
        var f = 0.02
        var reynolds = 0.0
        var iteraciones = 0
        var error = 0.0

        repeat {
            let area = Double.pi * diametro * diametro / 4
            let velocidad = caudalM3s / area
            reynolds = Friccion.reynolds(velocidad: velocidad, diametroM: diametro)
            f = Friccion.factorFriccion(rugosidadM: rugosidadM, diametroM: diametro, reynolds: reynolds)

            let velocidadObjetivo = velocidadPorEnergia(cargaDisponibleM, f, longitudM, diametro, sumaK)
            let diametroNuevo = sqrt(4 * caudalM3s / (Double.pi * velocidadObjetivo))
            error = abs(diametroNuevo - diametro)
            diametro = diametroNuevo
            iteraciones += 1
        } while error > toleranciaDiametro && iteraciones < maxIteraciones

        if !diametro.isFinite || diametro <= 0 {
            return .error(Errores.sinConvergencia)
        }

        let area = Double.pi * diametro * diametro / 4
        let velocidad = caudalM3s / area
        let cargaVelocidad = velocidad * velocidad / (2 * Constantes.gravedad)
        let perdidaFriccion = f * (longitudM / diametro) * cargaVelocidad
        let perdidaLocal = sumaK * cargaVelocidad

        guard Validacion.positivo(area), Validacion.positivo(velocidad), Validacion.positivo(f),
              Validacion.finitos(reynolds, perdidaFriccion, perdidaLocal, cargaVelocidad) else {
            return .error(Errores.fueraDeRango)
        }

        var advertencias = advertenciasVelocidad(velocidad)
        if iteraciones >= maxIteraciones {
            advertencias.append(
                "Se alcanzó el máximo de \(maxIteraciones) iteraciones; el resultado puede no estar convergido."
            )
        }

        return .exito(
            ResultadoDiametro(
                diametroM: diametro,
                velocidad: velocidad,
                area: area,
                factorFriccion: f,
                reynolds: reynolds,
                regimen: Friccion.regimen(reynolds),
                perdidaFriccionM: perdidaFriccion,
                perdidaLocalM: perdidaLocal,
                cargaVelocidadM: cargaVelocidad,
                iteraciones: iteraciones
            ),
            advertencias: advertencias
        )
    }

    private static func velocidadPorEnergia(
        _ cargaH: Double,
        _ f: Double,
        _ longitudM: Double,
        _ diametroM: Double,
        _ sumaK: Double
    ) -> Double {
        sqrt((2 * Constantes.gravedad * cargaH) / (1 + f * longitudM / diametroM + sumaK))
    }

    private static func advertenciasVelocidad(_ velocidad: Double) -> [String] {
        var avisos: [String] = []
        if velocidad > 5 {
            avisos.append("V = \(Formato.numero(velocidad, decimales: 2)) m/s es alta; revisa erosión y golpe de ariete.")
        }
        if velocidad < 0.3 {
            avisos.append("V = \(Formato.numero(velocidad, decimales: 2)) m/s es baja; puede favorecer sedimentación.")
        }
        return avisos
    }
}
