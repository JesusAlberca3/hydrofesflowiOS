import Foundation
import Testing
@testable import HydroFesFlow

/// Valores que un usuario o un error de unidades pueden meter al motor.
let valoresExtremos: [Double] = [
    0, -1, -0.0, 1e-300, 1e-12, 1e-6, 0.001, 0.3, 1, 20, 1000, 1e6, 1e12, 1e300,
    .infinity, -.infinity, .nan, .leastNonzeroMagnitude, .greatestFiniteMagnitude,
]

private func finitos(_ valores: [Double?]) -> Bool {
    valores.allSatisfy { $0?.isFinite ?? true }
}

/// Ningún cálculo debe devolver éxito con NaN o ∞: o hay un número válido o un mensaje de error.
@MainActor
struct RobustezTests {
    @Test(arguments: valoresExtremos)
    func caudalNuncaDevuelveValoresNoFinitos(diametro: Double) {
        for longitud in valoresExtremos {
            for carga in [0, 1e-300, 20, 1e300, .nan] as [Double] {
                for sumaK in [0, 2, -1, .nan, .infinity] as [Double] {
                    let r = FlujoGravedad.caudal(diametroM: diametro, longitudM: longitud, rugosidadMm: 0.0015, cargaDisponibleM: carga, sumaK: sumaK)
                    if let v = r.valor {
                        #expect(finitos([v.caudalM3s, v.velocidad, v.factorFriccion, v.reynolds, v.perdidaFriccionM, v.perdidaLocalM, v.cargaVelocidadM]))
                        #expect(v.caudalM3s > 0)
                    }
                }
            }
        }
    }

    @Test(arguments: valoresExtremos)
    func diametroNuncaDevuelveValoresNoFinitos(caudal: Double) {
        for longitud in valoresExtremos {
            for carga in [0, 1e-300, 20, 1e300, .nan] as [Double] {
                for sumaK in [0, 2, -1, .nan] as [Double] {
                    let r = FlujoGravedad.diametro(caudalM3s: caudal, longitudM: longitud, rugosidadMm: 0.0015, cargaDisponibleM: carga, sumaK: sumaK)
                    if let v = r.valor {
                        #expect(finitos([v.diametroM, v.velocidad, v.factorFriccion, v.reynolds, v.perdidaFriccionM, v.perdidaLocalM, v.cargaVelocidadM]))
                        #expect(v.diametroM > 0)
                    }
                }
            }
        }
    }

    @Test(arguments: valoresExtremos)
    func friccionNuncaDevuelveValoresNoFinitos(diametro: Double) {
        for longitud in valoresExtremos {
            for caudal in valoresExtremos {
                let resultados = [
                    PerdidasFriccion.darcyWeisbach(longitudM: longitud, diametroM: diametro, rugosidadMm: 0.0015, caudalM3s: caudal),
                    PerdidasFriccion.hazenWilliams(longitudM: longitud, diametroM: diametro, coeficienteC: 150, caudalM3s: caudal),
                    PerdidasFriccion.chezyManning(longitudM: longitud, diametroM: diametro, coeficienteN: 0.009, caudalM3s: caudal),
                ]
                for r in resultados {
                    if let v = r.valor {
                        #expect(finitos([v.perdidaM, v.area, v.velocidad, v.gradienteHidraulico, v.cargaVelocidad, v.reynolds, v.factorFriccion]))
                    }
                }
            }
        }
    }

    @Test(arguments: valoresExtremos)
    func localesNuncaDevuelveValoresNoFinitos(caudal: Double) {
        for diametro in valoresExtremos {
            for k in [0, 4.6, -1, .nan, .infinity] as [Double] {
                if let v = PerdidasLocales.calcular(caudalM3s: caudal, diametroM: diametro, coeficienteKTotal: k, factorFriccion: 0.02).valor {
                    #expect(finitos([v.perdidaM, v.velocidad, v.area, v.cargaVelocidad, v.longitudEquivalenteM]))
                    #expect(v.perdidaM >= 0)
                }
            }
        }
    }

    @Test(arguments: valoresExtremos)
    func celeridadNuncaDevuelveValoresNoFinitos(diametro: Double) {
        for espesor in valoresExtremos {
            for longitud in [nil, 0, 1200, .infinity, .nan] as [Double?] {
                for velocidad in [nil, 0, 1.8, .nan, .infinity] as [Double?] {
                    let r = Celeridad.calcular(diametroInteriorM: diametro, espesorM: espesor, moduloYoungPa: 207e9, longitudConduccionM: longitud, velocidadRegimen: velocidad)
                    if let v = r.valor {
                        #expect(finitos([v.celeridad, v.celeridadAguaLibre, v.sobrepresionPorMetroSegundo, v.tiempoCriticoS, v.sobrepresionJoukowskyM]))
                        #expect(v.celeridad > 0)
                    }
                }
            }
        }
    }

    @Test(arguments: GeometriaCanal.allCases)
    func canalesNuncaDevuelvenValoresNoFinitos(geometria: GeometriaCanal) {
        for tirante in valoresExtremos {
            for dimension in valoresExtremos {
                for pendiente in [0.001, 1e-300, 1e300, .nan] as [Double] {
                    for manning in [0.015, 1e-300, .nan] as [Double] {
                        let datos = DatosCanal(
                            geometria: geometria,
                            pendiente: pendiente,
                            manning: manning,
                            tirante: tirante,
                            anchoPlantilla: dimension,
                            talud: dimension,
                            diametro: dimension
                        )
                        if let v = Canales.calcular(datos).valor {
                            #expect(finitos([v.area, v.perimetroMojado, v.radioHidraulico, v.espejoAgua, v.profundidadHidraulica, v.caudal, v.velocidad, v.energiaEspecifica, v.numeroFroude, v.tiranteCritico, v.relacionLlenado]))
                            #expect(v.caudal > 0)
                        }
                        _ = PerfilSeccion.de(datos)
                    }
                }
            }
        }
    }

    @Test func nanSeRechazaComoDatoInvalido() {
        #expect(FlujoGravedad.caudal(diametroM: .nan, longitudM: 1000, rugosidadMm: 0.0015, cargaDisponibleM: 20, sumaK: 2).mensajeError == Errores.diametroInvalido)
        #expect(FlujoGravedad.diametro(caudalM3s: 0.2, longitudM: .nan, rugosidadMm: 0.0015, cargaDisponibleM: 20, sumaK: 2).mensajeError == Errores.longitudInvalida)
        #expect(PerdidasFriccion.hazenWilliams(longitudM: 100, diametroM: 0.2, coeficienteC: .nan, caudalM3s: 0.05).mensajeError == Errores.coeficienteInvalido)
        #expect(Celeridad.calcular(diametroInteriorM: 0.2, espesorM: .infinity, moduloYoungPa: 207e9).mensajeError == Errores.espesorInvalido)
        #expect(Canales.calcular(DatosCanal(geometria: .rectangular, pendiente: .nan, manning: 0.015, tirante: 1, anchoPlantilla: 3)).mensajeError == Errores.pendienteInvalida)
    }

    @Test func diametroMicroscopicoSeReportaFueraDeRango() {
        let r = PerdidasFriccion.darcyWeisbach(longitudM: 1e-300, diametroM: 1e-300, rugosidadMm: 0, caudalM3s: 1e-300)
        #expect(r.mensajeError == Errores.fueraDeRango)
    }

    @Test func coeficienteKNegativoEnLocalesSeRechaza() {
        #expect(PerdidasLocales.calcular(caudalM3s: 0.05, diametroM: 0.15, coeficienteKTotal: -1).mensajeError == Errores.kNegativo)
    }

    @Test func rugosidadNegativaSeRechaza() {
        #expect(PerdidasFriccion.darcyWeisbach(longitudM: 100, diametroM: 0.2, rugosidadMm: -0.1, caudalM3s: 0.05).mensajeError == Errores.rugosidadInvalida)
        #expect(FlujoGravedad.caudal(diametroM: 0.3, longitudM: 1000, rugosidadMm: -1, cargaDisponibleM: 20, sumaK: 2).mensajeError == Errores.rugosidadInvalida)
        #expect(FlujoGravedad.diametro(caudalM3s: 0.2, longitudM: 1000, rugosidadMm: -1, cargaDisponibleM: 20, sumaK: 2).mensajeError == Errores.rugosidadInvalida)
    }

    @Test func flujoLaminarConvergeYCierraLaEnergia() throws {
        let r = try #require(FlujoGravedad.caudal(diametroM: 0.01, longitudM: 100, rugosidadMm: 0.0015, cargaDisponibleM: 0.01, sumaK: 0).valor)
        #expect(r.regimen == .laminar)
        #expect(abs(r.cargaVelocidadM + r.perdidaFriccionM + r.perdidaLocalM - 0.01) < 1e-9)
        #expect(r.iteraciones < 200)
    }

    @Test func zonaDeTransicionAvisaDeIncertidumbre() {
        let d = 0.05
        let reynoldsObjetivo = 3000.0
        let velocidad = reynoldsObjetivo * Constantes.viscosidadCinematica / d
        let caudal = velocidad * Double.pi * d * d / 4
        let r = PerdidasFriccion.darcyWeisbach(longitudM: 10, diametroM: d, rugosidadMm: 0.0015, caudalM3s: caudal)
        #expect(r.valor?.regimen == .transicion)
        #expect(r.advertencias.contains { $0.contains("zona crítica") })
    }

    @Test func rugosidadCeroEsTuberiaLisaValida() throws {
        let r = try #require(PerdidasFriccion.darcyWeisbach(longitudM: 100, diametroM: 0.2, rugosidadMm: 0, caudalM3s: 0.05).valor)
        #expect(r.perdidaM > 0)
    }

    @Test func todosLosMaterialesCalculanElEjemplo() {
        for material in CatalogoMateriales.todos {
            let r = FlujoGravedad.caudal(diametroM: 0.3, longitudM: 1000, rugosidadMm: material.rugosidadMm, cargaDisponibleM: 20, sumaK: 2)
            #expect(r.valor != nil, "\(material.nombre)")
        }
        for material in CatalogoMaterialesElasticos.todos {
            #expect(Celeridad.calcular(diametroInteriorM: 0.3, espesorM: 0.01, moduloYoungPa: material.moduloYoungPa).valor != nil, "\(material.nombre)")
        }
    }

    @Test func caudalYDiametroSonInversosEnVariosMateriales() throws {
        for material in CatalogoMateriales.todos {
            for d in [0.05, 0.3, 1.2] {
                let q = try #require(FlujoGravedad.caudal(diametroM: d, longitudM: 500, rugosidadMm: material.rugosidadMm, cargaDisponibleM: 15, sumaK: 3).valor).caudalM3s
                let recuperado = try #require(FlujoGravedad.diametro(caudalM3s: q, longitudM: 500, rugosidadMm: material.rugosidadMm, cargaDisponibleM: 15, sumaK: 3).valor).diametroM
                #expect(abs(recuperado - d) < 1e-6, "\(material.nombre) D=\(d)")
            }
        }
    }

    @Test func tiranteCircularIgualAlDiametroNoFalla() throws {
        let r = try #require(Canales.calcular(DatosCanal(geometria: .circular, pendiente: 0.001, manning: 0.013, tirante: 1, diametro: 1)).valor)
        #expect(r.numeroFroude == nil)
        #expect(r.regimen == nil)
    }

    @Test func trapecioConPlantillaCeroEquivaleATriangulo() throws {
        let trapecio = try #require(Canales.calcular(DatosCanal(geometria: .trapezoidal, pendiente: 0.001, manning: 0.015, tirante: 1, anchoPlantilla: 0, talud: 1.5)).valor)
        let triangulo = try #require(Canales.calcular(DatosCanal(geometria: .triangular, pendiente: 0.001, manning: 0.015, tirante: 1, talud: 1.5)).valor)
        #expect(abs(trapecio.caudal - triangulo.caudal) < 1e-12)
    }
}
