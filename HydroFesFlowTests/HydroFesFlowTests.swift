import Foundation
import Testing
@testable import HydroFesFlow

@MainActor
struct FriccionTests {
    @Test func swameeJainSeAproximaAColebrook() {
        let casos = [
            (1.5e-6, 0.20, 5e5),
            (2.6e-4, 0.30, 1e6),
            (0.0, 0.10, 1e5),
            (9.0e-4, 0.50, 2e6),
        ]
        for (eps, d, re) in casos {
            let sj = Friccion.swameeJain(rugosidadM: eps, diametroM: d, reynolds: re)
            let cb = Friccion.colebrookWhite(rugosidadM: eps, diametroM: d, reynolds: re)
            let errorRelativo = abs(sj - cb) / cb
            #expect(errorRelativo < 0.01)
        }
    }

    @Test func regimenLaminarUsa64EntreReynolds() {
        let f = Friccion.factorFriccion(rugosidadM: 1.5e-6, diametroM: 0.05, reynolds: 1000)
        #expect(abs(f - 0.064) < 1e-12)
    }

    @Test func clasificacionDeRegimen() {
        #expect(Friccion.regimen(1500) == .laminar)
        #expect(Friccion.regimen(3000) == .transicion)
        #expect(Friccion.regimen(100_000) == .turbulento)
    }

    @Test func factorContinuoEnLasFronteras() {
        let eps = 1.5e-6
        let d = 0.1
        let fLaminar = Friccion.factorFriccion(rugosidadM: eps, diametroM: d, reynolds: Friccion.reynoldsLaminarMax - 0.001)
        let fTransicionInicio = Friccion.factorFriccion(rugosidadM: eps, diametroM: d, reynolds: Friccion.reynoldsLaminarMax + 0.001)
        #expect(abs(fLaminar - fTransicionInicio) < 1e-6)

        let fTransicionFin = Friccion.factorFriccion(rugosidadM: eps, diametroM: d, reynolds: Friccion.reynoldsTurbulentoMin - 0.001)
        let fTurbulento = Friccion.factorFriccion(rugosidadM: eps, diametroM: d, reynolds: Friccion.reynoldsTurbulentoMin + 0.001)
        #expect(abs(fTransicionFin - fTurbulento) < 1e-6)
    }

    @Test func reynoldsConViscosidadDelAgua() {
        let re = Friccion.reynolds(velocidad: 2, diametroM: 0.1)
        #expect(abs(re - (2.0 * 0.1 / 1.004e-6)) < 1e-6)
    }
}

@MainActor
struct PerdidasFriccionTests {
    @Test func darcyReproduceElCalculoManual() throws {
        let l = 100.0
        let d = 0.20
        let q = 0.050
        let epsMm = 0.0015
        let r = try #require(PerdidasFriccion.darcyWeisbach(longitudM: l, diametroM: d, rugosidadMm: epsMm, caudalM3s: q).valor)

        let area = Double.pi * d * d / 4
        let v = q / area
        let re = v * d / Constantes.viscosidadCinematica
        let f = Friccion.swameeJain(rugosidadM: epsMm / 1000, diametroM: d, reynolds: re)
        let esperado = f * (l / d) * v * v / (2 * Constantes.gravedad)

        #expect(abs(r.perdidaM - esperado) < 1e-12)
        #expect(abs(r.velocidad - v) < 1e-12)
        #expect(abs((r.reynolds ?? 0) - re) < 1e-6)
        #expect(abs(r.gradienteHidraulico - esperado / l) < 1e-12)
    }

    @Test func alDuplicarElCaudalLaPerdidaCreceCasiConElCuadrado() throws {
        let base = try #require(PerdidasFriccion.darcyWeisbach(longitudM: 100, diametroM: 0.2, rugosidadMm: 0.0015, caudalM3s: 0.05).valor)
        let doble = try #require(PerdidasFriccion.darcyWeisbach(longitudM: 100, diametroM: 0.2, rugosidadMm: 0.0015, caudalM3s: 0.10).valor)
        let relacion = doble.perdidaM / base.perdidaM
        #expect(relacion >= 3.4 && relacion <= 4.0)
        #expect((doble.factorFriccion ?? 1) < (base.factorFriccion ?? 0))
    }

    @Test func hazenUsaLosExponentesDelSI() throws {
        let l = 100.0
        let d = 0.20
        let c = 150.0
        let q = 0.050
        let r = try #require(PerdidasFriccion.hazenWilliams(longitudM: l, diametroM: d, coeficienteC: c, caudalM3s: q).valor)
        let esperado = 10.674 * l * pow(q / c, 1.852) / pow(d, 4.871)
        #expect(abs(r.perdidaM - esperado) < 1e-12)
    }

    @Test func hazenQuedaCercaDeDarcyParaPVC() throws {
        let dw = try #require(PerdidasFriccion.darcyWeisbach(longitudM: 100, diametroM: 0.2, rugosidadMm: 0.0015, caudalM3s: 0.05).valor)
        let hw = try #require(PerdidasFriccion.hazenWilliams(longitudM: 100, diametroM: 0.2, coeficienteC: 150, caudalM3s: 0.05).valor)
        let desviacion = abs(hw.perdidaM - dw.perdidaM) / dw.perdidaM
        #expect(desviacion < 0.15)
    }

    @Test func manningCoincideConRadioDEntre4() throws {
        let l = 100.0
        let d = 0.20
        let n = 0.009
        let q = 0.050
        let r = try #require(PerdidasFriccion.chezyManning(longitudM: l, diametroM: d, coeficienteN: n, caudalM3s: q).valor)
        let area = Double.pi * d * d / 4
        let v = q / area
        let radio = d / 4
        let pendiente = pow(n * v / pow(radio, 2.0 / 3.0), 2)
        let esperado = pendiente * l
        #expect(abs(r.perdidaM - esperado) <= esperado * 1e-4)
    }

    @Test func constanteDeManning() {
        let exacta = pow(4.0, 10.0 / 3.0) / (Double.pi * Double.pi)
        #expect(abs(exacta - PerdidasFriccion.constanteManning) < 1e-3)
    }

    @Test func rechazaEntradasNoFisicas() {
        #expect(PerdidasFriccion.darcyWeisbach(longitudM: 100, diametroM: 0, rugosidadMm: 0.0015, caudalM3s: 0.05).esError)
        #expect(PerdidasFriccion.darcyWeisbach(longitudM: 0, diametroM: 0.2, rugosidadMm: 0.0015, caudalM3s: 0.05).esError)
        #expect(PerdidasFriccion.darcyWeisbach(longitudM: 100, diametroM: 0.2, rugosidadMm: 0.0015, caudalM3s: 0).esError)
        #expect(PerdidasFriccion.hazenWilliams(longitudM: 100, diametroM: 0.2, coeficienteC: 0, caudalM3s: 0.05).esError)
        #expect(PerdidasFriccion.chezyManning(longitudM: 100, diametroM: 0.2, coeficienteN: 0, caudalM3s: 0.05).esError)
    }

    @Test func ejemploDeComprobacionDePerdidas() throws {
        let dw = try #require(PerdidasFriccion.darcyWeisbach(longitudM: 100, diametroM: 0.2, rugosidadMm: 0.0015, caudalM3s: 0.05).valor)
        let hw = try #require(PerdidasFriccion.hazenWilliams(longitudM: 100, diametroM: 0.2, coeficienteC: 150, caudalM3s: 0.05).valor)
        let mn = try #require(PerdidasFriccion.chezyManning(longitudM: 100, diametroM: 0.2, coeficienteN: 0.009, caudalM3s: 0.05).valor)
        #expect(abs(dw.perdidaM - 0.9242) < 5e-4)
        #expect(abs(hw.perdidaM - 0.9849) < 5e-4)
        #expect(abs(mn.perdidaM - 1.1139) < 5e-4)
    }
}

@MainActor
struct FlujoGravedadTests {
    let longitud = 1000.0
    let carga = 20.0
    let sumaK = 2.0
    let rugosidadPvcMm = 0.0015

    @Test func caudalYDiametroSonConsistentes() throws {
        let diametroOriginal = 0.30
        let q = try #require(FlujoGravedad.caudal(
            diametroM: diametroOriginal,
            longitudM: longitud,
            rugosidadMm: rugosidadPvcMm,
            cargaDisponibleM: carga,
            sumaK: sumaK
        ).valor).caudalM3s
        let recuperado = try #require(FlujoGravedad.diametro(
            caudalM3s: q,
            longitudM: longitud,
            rugosidadMm: rugosidadPvcMm,
            cargaDisponibleM: carga,
            sumaK: sumaK
        ).valor).diametroM
        #expect(abs(recuperado - diametroOriginal) < 1e-6)
    }

    @Test func laEnergiaSeReparteEnLaCargaDisponible() throws {
        let r = try #require(FlujoGravedad.caudal(
            diametroM: 0.30,
            longitudM: longitud,
            rugosidadMm: rugosidadPvcMm,
            cargaDisponibleM: carga,
            sumaK: sumaK
        ).valor)
        let suma = r.cargaVelocidadM + r.perdidaFriccionM + r.perdidaLocalM
        #expect(abs(suma - carga) < 1e-6)
    }

    @Test func ejemploDocumentadoDeCaudal() throws {
        let r = try #require(FlujoGravedad.caudal(
            diametroM: 0.30,
            longitudM: longitud,
            rugosidadMm: rugosidadPvcMm,
            cargaDisponibleM: carga,
            sumaK: sumaK
        ).valor)
        #expect(abs(r.caudalM3s * 1000 - 214.185) < 0.001)
        #expect(abs(r.velocidad - 3.0301) < 0.0001)
        #expect(abs(r.factorFriccion - 0.01192) < 0.00001)
        #expect(abs(r.perdidaFriccionM - 18.5961) < 0.0001)
        #expect(abs(r.perdidaLocalM - 0.9359) < 0.0001)
        #expect(abs(r.cargaVelocidadM - 0.4680) < 0.0001)
    }

    @Test func elCaudalEsAreaPorVelocidad() throws {
        let d = 0.25
        let r = try #require(FlujoGravedad.caudal(
            diametroM: d,
            longitudM: longitud,
            rugosidadMm: rugosidadPvcMm,
            cargaDisponibleM: carga,
            sumaK: sumaK
        ).valor)
        #expect(abs(Double.pi * d * d / 4 * r.velocidad - r.caudalM3s) < 1e-12)
    }

    @Test func elDiametroConvergeEnPocasIteraciones() throws {
        let r = try #require(FlujoGravedad.diametro(
            caudalM3s: 0.2,
            longitudM: longitud,
            rugosidadMm: rugosidadPvcMm,
            cargaDisponibleM: carga,
            sumaK: sumaK
        ).valor)
        #expect(r.iteraciones >= 1 && r.iteraciones <= 50)
    }

    @Test func masRugosidadProduceMenosCaudal() throws {
        let liso = try #require(FlujoGravedad.caudal(diametroM: 0.30, longitudM: longitud, rugosidadMm: 0.0015, cargaDisponibleM: carga, sumaK: sumaK).valor).caudalM3s
        let rugoso = try #require(FlujoGravedad.caudal(diametroM: 0.30, longitudM: longitud, rugosidadMm: 0.9, cargaDisponibleM: carga, sumaK: sumaK).valor).caudalM3s
        #expect(rugoso < liso)
    }

    @Test func masCargaProduceMasCaudal() throws {
        let baja = try #require(FlujoGravedad.caudal(diametroM: 0.30, longitudM: longitud, rugosidadMm: rugosidadPvcMm, cargaDisponibleM: 10, sumaK: sumaK).valor).caudalM3s
        let alta = try #require(FlujoGravedad.caudal(diametroM: 0.30, longitudM: longitud, rugosidadMm: rugosidadPvcMm, cargaDisponibleM: 40, sumaK: sumaK).valor).caudalM3s
        #expect(alta > baja)
    }

    @Test func rechazaEntradasNoFisicas() {
        #expect(FlujoGravedad.caudal(diametroM: 0, longitudM: longitud, rugosidadMm: 0.0015, cargaDisponibleM: carga, sumaK: sumaK).esError)
        #expect(FlujoGravedad.caudal(diametroM: 0.3, longitudM: 0, rugosidadMm: 0.0015, cargaDisponibleM: carga, sumaK: sumaK).esError)
        #expect(FlujoGravedad.caudal(diametroM: 0.3, longitudM: longitud, rugosidadMm: 0.0015, cargaDisponibleM: 0, sumaK: sumaK).esError)
        #expect(FlujoGravedad.diametro(caudalM3s: 0, longitudM: longitud, rugosidadMm: 0.0015, cargaDisponibleM: carga, sumaK: sumaK).esError)
        #expect(FlujoGravedad.caudal(diametroM: 0.3, longitudM: longitud, rugosidadMm: 0.0015, cargaDisponibleM: carga, sumaK: -1).esError)
    }
}

@MainActor
struct CeleridadYLocalesTests {
    @Test func coincideConKorteweg() throws {
        let d = 0.5
        let e = 0.008
        let young = 207e9
        let obtenido = try #require(Celeridad.calcular(diametroInteriorM: d, espesorM: e, moduloYoungPa: young).valor).celeridad
        let k = Constantes.moduloVolumetricoAgua
        let rho = Constantes.densidadAgua
        let referencia = sqrt(k / rho) / sqrt(1 + k * d / (young * e))
        #expect(abs(referencia - obtenido) < 1e-9)
    }

    @Test func paredRigidaTiendeAlAguaLibre() throws {
        let r = try #require(Celeridad.calcular(diametroInteriorM: 0.2, espesorM: 0.01, moduloYoungPa: 1e30).valor)
        #expect(abs(r.celeridad - sqrt(Constantes.moduloVolumetricoAgua / Constantes.densidadAgua)) < 1e-3)
    }

    @Test func elAceroDaMayorCeleridadQueElPVC() throws {
        let acero = try #require(Celeridad.calcular(diametroInteriorM: 0.2, espesorM: 0.006, moduloYoungPa: 207e9).valor).celeridad
        let pvc = try #require(Celeridad.calcular(diametroInteriorM: 0.2, espesorM: 0.006, moduloYoungPa: 3.3e9).valor).celeridad
        #expect(acero > pvc)
    }

    @Test func tiempoCriticoYJoukowsky() throws {
        let longitud = 1200.0
        let velocidad = 1.8
        let r = try #require(Celeridad.calcular(
            diametroInteriorM: 0.3,
            espesorM: 0.01,
            moduloYoungPa: 207e9,
            longitudConduccionM: longitud,
            velocidadRegimen: velocidad
        ).valor)
        let tiempo = try #require(r.tiempoCriticoS)
        let sobrepresion = try #require(r.sobrepresionJoukowskyM)
        #expect(abs(tiempo - 2 * longitud / r.celeridad) < 1e-9)
        #expect(abs(sobrepresion - r.celeridad * velocidad / Constantes.gravedad) < 1e-9)
    }

    @Test func rechazaEspesorYDiametroNulos() {
        #expect(Celeridad.calcular(diametroInteriorM: 0, espesorM: 0.01, moduloYoungPa: 207e9).esError)
        #expect(Celeridad.calcular(diametroInteriorM: 0.2, espesorM: 0, moduloYoungPa: 207e9).esError)
        #expect(Celeridad.calcular(diametroInteriorM: 0.2, espesorM: 0.01, moduloYoungPa: 0).esError)
    }

    @Test func perdidaLocalUsaKPorCargaDeVelocidad() throws {
        let q = 0.05
        let d = 0.15
        let k = 11.8
        let r = try #require(PerdidasLocales.calcular(caudalM3s: q, diametroM: d, coeficienteKTotal: k).valor)
        let area = Double.pi * d * d / 4
        let v = q / area
        #expect(abs(r.perdidaM - k * v * v / (2 * Constantes.gravedad)) < 1e-12)
        #expect(abs(r.velocidad - v) < 1e-12)
    }

    @Test func longitudEquivalente() throws {
        let r = try #require(PerdidasLocales.calcular(caudalM3s: 0.05, diametroM: 0.15, coeficienteKTotal: 11.8, factorFriccion: 0.02).valor)
        let equivalente = try #require(r.longitudEquivalenteM)
        #expect(abs(equivalente - 11.8 * 0.15 / 0.02) < 1e-12)
    }

    @Test func elCatalogoSumaLosCoeficientes() {
        let seleccion = CatalogoAccesorios.seleccionInicial.map { item -> AccesorioSeleccionado in
            var copia = item
            if item.accesorio.nombre == "Codo de 90°" { copia.cantidad = 4 }
            if item.accesorio.nombre == "Salida" { copia.cantidad = 1 }
            return copia
        }
        let total = seleccion.reduce(0) { $0 + $1.aporteK }
        #expect(abs(total - (4 * 0.9 + 1)) < 1e-12)
    }

    @Test func rechazaDiametroNuloEnLocales() {
        #expect(PerdidasLocales.calcular(caudalM3s: 0.05, diametroM: 0, coeficienteKTotal: 3).esError)
        #expect(PerdidasLocales.calcular(caudalM3s: 0, diametroM: 0.15, coeficienteKTotal: 3).esError)
    }

    @Test func materialesTienenCoeficientesValidos() {
        for material in CatalogoMateriales.todos {
            #expect(material.rugosidadMm >= 0)
            #expect(material.coeficienteHazenWilliams >= 80 && material.coeficienteHazenWilliams <= 160)
            #expect(material.coeficienteManning >= 0.008 && material.coeficienteManning <= 0.03)
        }
    }

    @Test func rugosidadEnMetros() {
        let pvc = CatalogoMateriales.porNombre("PVC")
        #expect(abs(pvc.rugosidadMm - 0.0015) < 1e-12)
        #expect(abs(pvc.rugosidadM - 1.5e-6) < 1e-15)
    }

    @Test func noHayNombresDuplicados() {
        let nombres = CatalogoMateriales.todos.map(\.nombre)
        #expect(Set(nombres).count == nombres.count)
    }

    @Test func conversionDeLongitudIdaYVuelta() {
        for unidad in UnidadLongitud.allCases {
            let original = 12.5
            #expect(abs(unidad.desdeMetros(unidad.aMetros(original)) - original) < 1e-12)
        }
    }

    @Test func factoresDeLongitud() {
        #expect(abs(UnidadLongitud.pulgada.aMetros(1) - 0.0254) < 1e-12)
        #expect(abs(UnidadLongitud.milimetro.aMetros(100) - 0.1) < 1e-12)
        #expect(abs(UnidadLongitud.metro.aMetros(1) - 1) < 1e-12)
    }

    @Test func factoresDeCaudal() {
        #expect(abs(UnidadCaudal.litroSegundo.aM3s(50) - 0.05) < 1e-12)
        #expect(abs(UnidadCaudal.metro3Hora.aM3s(3600) - 1) < 1e-12)
    }
}

@MainActor
struct CanalesTests {
    @Test func rectangularReproduceManning() throws {
        let datos = DatosCanal(geometria: .rectangular, pendiente: 0.001, manning: 0.015, tirante: 1, anchoPlantilla: 3)
        let r = try #require(Canales.calcular(datos).valor)
        #expect(abs(r.area - 3) < 1e-12)
        #expect(abs(r.perimetroMojado - 5) < 1e-12)
        #expect(abs(r.radioHidraulico - 0.6) < 1e-12)
        #expect(abs(r.espejoAgua - 3) < 1e-12)
        let qEsperado = (1 / 0.015) * 3 * pow(0.6, 2.0 / 3.0) * sqrt(0.001)
        #expect(abs(r.caudal - qEsperado) < 1e-10)
        #expect(abs(r.velocidad - qEsperado / 3) < 1e-10)
    }

    @Test func tiranteCriticoRectangularCoincideConLaFormulaCerrada() throws {
        let b = 3.0
        let datos = DatosCanal(geometria: .rectangular, pendiente: 0.001, manning: 0.015, tirante: 1, anchoPlantilla: b)
        let r = try #require(Canales.calcular(datos).valor)
        let caudalUnitario = r.caudal / b
        let yc = pow(caudalUnitario * caudalUnitario / Constantes.gravedad, 1.0 / 3.0)
        let obtenido = try #require(r.tiranteCritico)
        #expect(abs(obtenido - yc) < 1e-6)
    }

    @Test func froudeUsaProfundidadHidraulica() throws {
        let datos = DatosCanal(geometria: .triangular, pendiente: 0.001, manning: 0.015, tirante: 1, talud: 1.5)
        let r = try #require(Canales.calcular(datos).valor)
        let profundidad = try #require(r.profundidadHidraulica)
        let froude = try #require(r.numeroFroude)
        #expect(abs(profundidad - 0.5) < 1e-12)
        #expect(abs(froude - r.velocidad / sqrt(Constantes.gravedad * 0.5)) < 1e-12)
    }

    @Test func trapezoidalReproduceGeometria() throws {
        let b = 3.0
        let z = 1.5
        let y = 1.0
        let datos = DatosCanal(geometria: .trapezoidal, pendiente: 0.001, manning: 0.015, tirante: y, anchoPlantilla: b, talud: z)
        let r = try #require(Canales.calcular(datos).valor)
        #expect(abs(r.area - y * (b + z * y)) < 1e-12)
        #expect(abs(r.perimetroMojado - (b + 2 * y * sqrt(1 + z * z))) < 1e-12)
        #expect(abs(r.espejoAgua - (b + 2 * z * y)) < 1e-12)
    }

    @Test func circularAMediaCapacidad() throws {
        let d = 1.0
        let datos = DatosCanal(geometria: .circular, pendiente: 0.001, manning: 0.015, tirante: d / 2, diametro: d)
        let r = try #require(Canales.calcular(datos).valor)
        #expect(abs(r.area - Double.pi * d * d / 8) < 1e-10)
        #expect(abs(r.perimetroMojado - Double.pi * d / 2) < 1e-10)
        #expect(abs(r.espejoAgua - d) < 1e-10)
        #expect(abs(r.radioHidraulico - d / 4) < 1e-10)
    }

    @Test func gastoMaximoCircularCercaDe0938() throws {
        func q(_ relacion: Double) throws -> Double {
            try #require(Canales.calcular(DatosCanal(
                geometria: .circular,
                pendiente: 0.001,
                manning: 0.013,
                tirante: relacion,
                diametro: 1
            )).valor).caudal
        }
        #expect(try q(0.938) > q(0.80))
        #expect(try q(0.938) > q(0.999))
    }

    @Test func seccionLlenaDejaFroudeIndefinido() {
        let r = Canales.calcular(DatosCanal(geometria: .circular, pendiente: 0.001, manning: 0.013, tirante: 1, diametro: 1))
        #expect(r.valor?.numeroFroude == nil)
        #expect(!r.advertencias.isEmpty)
    }

    @Test func clasificacionSegunFroude() {
        #expect(Canales.clasificarRegimen(0.5) == .subcritico)
        #expect(Canales.clasificarRegimen(1) == .critico)
        #expect(Canales.clasificarRegimen(2) == .supercritico)
    }

    @Test func rechazaDatosNoFisicos() {
        let base = DatosCanal(geometria: .rectangular, pendiente: 0.001, manning: 0.015, tirante: 1, anchoPlantilla: 3)
        var sinPendiente = base
        sinPendiente.pendiente = 0
        var sinManning = base
        sinManning.manning = 0
        var sinTirante = base
        sinTirante.tirante = 0
        var sinAncho = base
        sinAncho.anchoPlantilla = 0
        #expect(Canales.calcular(sinPendiente).esError)
        #expect(Canales.calcular(sinManning).esError)
        #expect(Canales.calcular(sinTirante).esError)
        #expect(Canales.calcular(sinAncho).esError)
        #expect(Canales.calcular(DatosCanal(geometria: .circular, pendiente: 0.001, manning: 0.013, tirante: 1.5, diametro: 1)).esError)
    }

    @Test func energiaEspecifica() throws {
        let r = try #require(Canales.calcular(DatosCanal(geometria: .rectangular, pendiente: 0.001, manning: 0.015, tirante: 1, anchoPlantilla: 3)).valor)
        let esperado = 1 + r.velocidad * r.velocidad / (2 * Constantes.gravedad)
        #expect(abs(r.energiaEspecifica - esperado) < 1e-12)
    }
}
