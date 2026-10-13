import Foundation
import Testing
@testable import HydroFesFlow

@MainActor
struct EntradasTests {
    @Test(arguments: [
        ("1.5", 1.5), ("1,5", 1.5), (" 2 ", 2.0), (".5", 0.5), ("5.", 5.0), ("0", 0.0),
    ])
    func parseoAceptaFormatosDecimales(texto: String, esperado: Double) {
        #expect(Parseo.double(texto) == esperado)
    }

    @Test(arguments: ["", " ", ".", ",", "1.2.3", "abc", "inf", "nan", "1e400", "-"])
    func parseoRechazaTextosNoNumericos(texto: String) {
        #expect(Parseo.double(texto) == nil)
    }

    @Test func sanearConvierteComaYRechazaPulsacionesInvalidas() {
        #expect(Sanear.numero("1,5") == "1.5")
        #expect(Sanear.numero("") == "")
        #expect(Sanear.numero(".") == ".")
        #expect(Sanear.numero("1.2.") == nil)
        #expect(Sanear.numero("12a") == nil)
        #expect(Sanear.numero("-3") == nil)
        #expect(Sanear.numero("1e9") == nil)
        #expect(Sanear.numero(String(repeating: "9", count: Sanear.longitudMaxima)) != nil)
        #expect(Sanear.numero(String(repeating: "9", count: Sanear.longitudMaxima + 1)) == nil)
    }

    @Test func elCampoMasLargoNoDesbordaAlConvertirUnidades() throws {
        let texto = String(repeating: "9", count: Sanear.longitudMaxima)
        for unidad in UnidadLongitud.allCases {
            let metros = try #require(EntradaLongitud(texto: texto, unidad: unidad).valorMetros)
            #expect(metros.isFinite)
        }
        for unidad in UnidadCaudal.allCases {
            let m3s = try #require(EntradaCaudal(texto: texto, unidad: unidad).valorM3s)
            #expect(m3s.isFinite)
        }
    }

    @Test func avisosDeCampo() {
        #expect(AvisoCampo.positivo("") == nil)
        #expect(AvisoCampo.positivo("2") == nil)
        #expect(AvisoCampo.positivo("0") == AvisoCampo.mayorQueCero)
        #expect(AvisoCampo.positivo("0.") == AvisoCampo.mayorQueCero)
        #expect(AvisoCampo.positivo(".") == AvisoCampo.noNumerico)
        #expect(AvisoCampo.noNegativo("0") == nil)
        #expect(AvisoCampo.noNegativo("-1") == AvisoCampo.noNegativo)
    }

    @Test func conversionDeUnidadesEnLasEntradas() {
        #expect(EntradaLongitud(texto: "300", unidad: .milimetro).valorMetros == 0.3)
        #expect(EntradaCaudal(texto: "50", unidad: .litroSegundo).valorM3s == 0.05)
        #expect(EntradaLongitud(texto: "", unidad: .metro).valorMetros == nil)
    }
}

@MainActor
struct FormulariosTests {
    @Test func formulariosVaciosNoEstanCompletosYNoFallan() {
        #expect(!FormularioCaudal().datosCompletos)
        #expect(!FormularioDiametro().datosCompletos)
        #expect(!FormularioFriccion().datosCompletos)
        #expect(!FormularioLocales().datosCompletos)
        #expect(!FormularioCeleridad().datosCompletos)
        #expect(!FormularioCanal().datosCompletos)
        #expect(FormularioCaudal().calcular().error == Errores.datosIncompletos)
        #expect(FormularioDiametro().calcular().error == Errores.datosIncompletos)
        #expect(FormularioFriccion().calcular().error == Errores.datosIncompletos)
        #expect(FormularioLocales().calcular().error == Errores.datosIncompletos)
        #expect(FormularioCeleridad().calcular().error == Errores.datosIncompletos)
        #expect(FormularioCanal().calcular().error == Errores.datosIncompletos)
    }

    @Test func ejemploDeCaudalMuestraLosValoresDocumentados() throws {
        let salida = FormularioCaudal.ejemplo.calcular()
        #expect(salida.error == nil)
        #expect(salida.principal?.valor == "214.185 L/s")
        #expect(salida.renglones.contains(Renglon(etiqueta: "Velocidad media V", valor: "3.0301 m/s")))
        #expect(salida.renglones.contains(Renglon(etiqueta: "Pérdida por fricción", valor: "18.5961 m")))
        #expect(salida.renglones.contains(Renglon(etiqueta: "Pérdidas locales", valor: "0.9359 m")))
        #expect(salida.renglones.contains(Renglon(etiqueta: "Carga de velocidad V²/2g", valor: "0.4680 m")))
        let total = salida.reparto.reduce(0) { $0 + $1.metros }
        #expect(abs(total - 20) < 1e-6)
        #expect(abs(salida.reparto.reduce(0) { $0 + $1.fraccion } - 1) < 1e-12)
    }

    @Test func ejemploDeDiametroRecuperaTrescientosMilimetros() {
        let salida = FormularioDiametro.ejemplo.calcular()
        #expect(salida.principal?.valor == "0.3000 m")
        #expect(salida.renglones.first { $0.etiqueta == "Equivalencias" }?.valor.hasPrefix("300.00 mm") == true)
    }

    @Test func ejemploDeFriccionContrastaLosTresMetodos() throws {
        let salida = FormularioFriccion.ejemplo.calcular()
        #expect(salida.principal?.valor == "0.9242 m")
        #expect(salida.comparativa.count == 3)
        let hazen = try #require(salida.comparativa.first { $0.metodo == .hazenWilliams }?.diferenciaPorcentual)
        let manning = try #require(salida.comparativa.first { $0.metodo == .chezyManning }?.diferenciaPorcentual)
        #expect(abs(hazen - 6.6) < 0.05)
        #expect(abs(manning - 20.5) < 0.05)
        #expect(salida.comparativa.first { $0.metodo == .darcyWeisbach }?.diferenciaPorcentual == nil)
    }

    @Test(arguments: MetodoFriccion.allCases)
    func cadaMetodoDeFriccionTieneResultadoPrincipal(metodo: MetodoFriccion) {
        var form = FormularioFriccion.ejemplo
        form.metodo = metodo
        let salida = form.calcular()
        #expect(salida.hayResultado)
        #expect(salida.principal?.etiqueta == "Pérdida por fricción h_f")
    }

    @Test func ejemploDeLocalesSumaCuatroCodosYUnaSalida() {
        let form = FormularioLocales.ejemplo
        #expect(abs(form.coeficienteKTotal - 4.6) < 1e-12)
        #expect(form.piezasTotales == 5)
        let salida = form.calcular()
        #expect(salida.renglones.contains(Renglon(etiqueta: "Coeficiente total ΣK", valor: "4.60")))
        #expect(salida.renglones.contains(Renglon(etiqueta: "Piezas seleccionadas", valor: "5")))
    }

    @Test func lasCantidadesDeAccesoriosSeAcotan() {
        var form = FormularioLocales()
        form.ajustar("Codo de 90°", delta: -5)
        #expect(form.piezasTotales == 0)
        for _ in 0..<(FormularioLocales.maximoPorPieza + 10) {
            form.ajustar("Codo de 90°", delta: 1)
        }
        #expect(form.piezasTotales == FormularioLocales.maximoPorPieza)
        form.ajustar("No existe", delta: 1)
        #expect(form.piezasTotales == FormularioLocales.maximoPorPieza)
        form.limpiarSeleccion()
        #expect(form.coeficienteKTotal == 0)
    }

    @Test func localesSinPiezasAvisanPerdidaNula() {
        var form = FormularioLocales.ejemplo
        form.limpiarSeleccion()
        let salida = form.calcular()
        #expect(salida.principal?.valor == "0.0000 m")
        #expect(salida.advertencias.contains { $0.contains("ΣK = 0") })
    }

    @Test func ejemploDeCeleridadConAcero() {
        let salida = FormularioCeleridad.ejemplo.calcular()
        #expect(salida.principal?.valor == "1149.32 m/s")
        #expect(salida.renglones.contains { $0.etiqueta == "Tiempo crítico 2L/a" })
        #expect(salida.renglones.contains { $0.etiqueta == "Sobrepresión de Joukowsky" })
    }

    @Test func celeridadIgnoraOpcionalesInvalidosYLoAvisa() {
        var form = FormularioCeleridad.ejemplo
        form.longitud.texto = "0"
        form.velocidad = "."
        let salida = form.calcular()
        #expect(salida.hayResultado)
        #expect(!salida.renglones.contains { $0.etiqueta == "Tiempo crítico 2L/a" })
        #expect(!salida.renglones.contains { $0.etiqueta == "Sobrepresión de Joukowsky" })
        #expect(salida.advertencias.count == 2)
    }

    @Test func ejemploDeCanalRectangularEsSubcritico() throws {
        let salida = FormularioCanal.ejemplo.calcular()
        #expect(salida.hayResultado)
        let regimen = try #require(salida.renglones.first { $0.etiqueta == "Régimen" })
        #expect(regimen.valor == "Subcrítico")
        #expect(regimen.tono == .subcritico)
    }

    @Test func canalCircularAvisaTiranteMayorQueDiametro() {
        var form = FormularioCanal.ejemplo
        form.geometria = .circular
        form.diametro = EntradaLongitud(texto: "0.8", unidad: .metro)
        #expect(form.avisoTirante != nil)
        #expect(form.calcular().error == Errores.tiranteCircular)
    }

    @Test(arguments: GeometriaCanal.allCases)
    func cadaGeometriaCalculaConSusDatos(geometria: GeometriaCanal) {
        var form = FormularioCanal.ejemplo
        form.geometria = geometria
        form.talud = "1.5"
        form.diametro = EntradaLongitud(texto: "2", unidad: .metro)
        #expect(form.datosCompletos)
        #expect(form.calcular().hayResultado)
        #expect(form.datos.flatMap(PerfilSeccion.de) != nil)
    }

    @Test func ceroEnUnCampoDaErrorClaroSinFallar() {
        var form = FormularioCaudal.ejemplo
        form.diametro.texto = "0"
        #expect(form.datosCompletos)
        #expect(form.calcular().error == Errores.diametroInvalido)
        #expect(form.diametro.avisoPositivo == AvisoCampo.mayorQueCero)
    }
}

@MainActor
struct SalidaTests {
    @Test func textoCompartibleIncluyeRenglonesYAvisos() {
        let salida = SalidaCalculo(
            renglones: [Renglon(etiqueta: "Caudal Q", valor: "1 L/s", destacado: true)],
            advertencias: ["Cuidado"]
        )
        let texto = salida.textoCompartible(titulo: "Caudal")
        #expect(texto.contains("HidroFES Flow · Caudal"))
        #expect(texto.contains("Caudal Q: 1 L/s"))
        #expect(texto.contains("Aviso: Cuidado"))
    }

    @Test func repartoVacioSiNoHayCarga() {
        #expect(SalidaCalculo.repartoDeCarga(friccion: 0, locales: 0, velocidad: 0).isEmpty)
        #expect(SalidaCalculo.repartoDeCarga(friccion: .nan, locales: 1, velocidad: 1).isEmpty)
    }

    @Test func advertenciasSinRepetir() {
        #expect(unicas(["a", "b", "a", "c", "b"]) == ["a", "b", "c"])
    }

    @Test func formatoDeValoresEspeciales() {
        #expect(Formato.numero(.nan) == "—")
        #expect(Formato.numero(.infinity) == "∞")
        #expect(Formato.auto(0) == "0.0000")
        #expect(Formato.auto(1e7) == "1.000e+07")
        #expect(Formato.auto(1e-4) == "1.000e-04")
        #expect(Formato.numero(1.5, decimales: 2) == "1.50")
    }
}

@MainActor
struct PerfilSeccionTests {
    @Test func rectanguloMojaTodoElAnchoDePlantilla() throws {
        let perfil = try #require(PerfilSeccion.de(DatosCanal(geometria: .rectangular, pendiente: 0.001, manning: 0.015, tirante: 1, anchoPlantilla: 3)))
        let xs = perfil.agua.map(\.x)
        #expect(abs((xs.max() ?? 0) - (xs.min() ?? 0) - 3) < 1e-12)
        #expect(perfil.alto > perfil.tirante)
        #expect(!perfil.cerrado)
    }

    @Test func espejoDelDibujoCoincideConElCalculo() throws {
        let datos = DatosCanal(geometria: .trapezoidal, pendiente: 0.001, manning: 0.015, tirante: 1, anchoPlantilla: 3, talud: 1.5)
        let perfil = try #require(PerfilSeccion.de(datos))
        let espejo = try #require(Canales.calcular(datos).valor).espejoAgua
        let superficie = try #require(perfil.agua.last).x - (try #require(perfil.agua.first)).x
        #expect(abs(superficie - espejo) < 1e-12)
    }

    @Test func circuloLlenoYMedioLleno() throws {
        let lleno = try #require(PerfilSeccion.de(DatosCanal(geometria: .circular, pendiente: 0.001, manning: 0.013, tirante: 1, diametro: 1)))
        #expect(lleno.cerrado)
        let medio = try #require(PerfilSeccion.de(DatosCanal(geometria: .circular, pendiente: 0.001, manning: 0.013, tirante: 0.5, diametro: 1)))
        #expect(medio.agua.allSatisfy { $0.y <= 0.5 + 1e-9 })
    }

    @Test func datosInvalidosNoDibujan() {
        #expect(PerfilSeccion.de(DatosCanal(geometria: .circular, pendiente: 0.001, manning: 0.013, tirante: 2, diametro: 1)) == nil)
        #expect(PerfilSeccion.de(DatosCanal(geometria: .rectangular, pendiente: 0.001, manning: 0.015, tirante: 1, anchoPlantilla: 0)) == nil)
        #expect(PerfilSeccion.de(DatosCanal(geometria: .triangular, pendiente: 0.001, manning: 0.015, tirante: .nan, talud: 1)) == nil)
    }
}
