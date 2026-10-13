import XCTest

final class HydroFesFlowUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--pruebas-ui"]
        app.launch()
    }

    @MainActor
    func testInicioMuestraLosDosModulos() {
        XCTAssertTrue(app.staticTexts["HidroFES Flow"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["inicio.conductos"].exists)
        XCTAssertTrue(app.buttons["inicio.canales"].exists)
    }

    @MainActor
    func testCaudalConElEjemploDocumentado() {
        abrir("inicio.conductos", "opcion.Caudal")
        XCTAssertFalse(boton("accion.calcular").isEnabled, "Sin datos el botón debe estar desactivado")
        cargarEjemplo()
        XCTAssertEqual(resultadoPrincipal(), "214.185 L/s")
        XCTAssertTrue(existeTexto("Reparto de la carga H"))
        captura("Caudal - resultado")
        app.swipeUp()
        captura("Caudal - reparto de la carga")
    }

    @MainActor
    func testDiametroCeroMuestraErrorSinCerrarLaApp() {
        abrir("inicio.conductos", "opcion.Caudal")
        cargarEjemplo()
        irArriba()
        let diametro = app.textFields["campo.Diámetro interior"]
        XCTAssertTrue(diametro.waitForExistence(timeout: 5))
        diametro.borrarTexto()
        diametro.typeText("0")
        XCTAssertTrue(existeTexto("Debe ser mayor que cero."))
        XCTAssertTrue(existeTexto("Pulsa calcular para actualizar"))
        app.toolbars.buttons["Listo"].tapSiExiste()
        boton("accion.calcular").tap()
        let error = app.descendants(matching: .any)["resultado.error"]
        XCTAssertTrue(error.waitForExistence(timeout: 5))
        XCTAssertTrue(error.label.contains("El diámetro debe ser mayor que cero."))
        captura("Caudal - error de diámetro cero")
        XCTAssertEqual(app.state, .runningForeground)
    }

    @MainActor
    func testDiametroConElEjemploRecuperaTrescientosMilimetros() {
        abrir("inicio.conductos", "opcion.Diámetro")
        cargarEjemplo()
        XCTAssertEqual(resultadoPrincipal(), "0.3000 m")
    }

    @MainActor
    func testFriccionCambiaDeMetodoYRecalcula() {
        abrir("inicio.conductos", "opcion.Pérdidas de carga", "opcion.Por fricción")
        cargarEjemplo()
        XCTAssertEqual(resultadoPrincipal(), "0.9242 m")
        irArriba()
        boton("opcion.Hazen").tap()
        XCTAssertTrue(esperarResultado("0.9849 m"))
        boton("opcion.Manning").tap()
        XCTAssertTrue(esperarResultado("1.1139 m"))
        app.swipeUp()
        captura("Fricción - contraste entre métodos")
    }

    @MainActor
    func testLocalesSumanCoeficientesYPasanAlCaudal() {
        abrir("inicio.conductos", "opcion.Pérdidas de carga", "opcion.Locales o menores")
        let mas = boton("accesorio.mas.Codo de 90°")
        for _ in 0..<4 { mas.tap() }
        XCTAssertTrue(existeTexto("ΣK = 3.60"))
        captura("Pérdidas locales - accesorios")

        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        boton("opcion.Caudal").tap()
        let usar = boton("accion.usarSumaK")
        usar.desplazarHastaVer(en: app)
        usar.tap()
        XCTAssertEqual(app.textFields["campo.Suma de coeficientes locales ΣK"].value as? String, "3.60")
    }

    @MainActor
    func testCeleridadConElEjemplo() {
        abrir("inicio.conductos", "opcion.Celeridad")
        cargarEjemplo()
        XCTAssertEqual(resultadoPrincipal(), "1149.32 m/s")
        captura("Celeridad - resultado")
    }

    @MainActor
    func testCanalesEnTodasLasGeometrias() {
        abrir("inicio.canales")
        cargarEjemplo()
        XCTAssertTrue(resultadoPrincipal().hasSuffix("m³/s"))
        captura("Canales - resultado")
        irArriba()
        captura("Canales - sección rectangular")
        for geometria in ["Triangular", "Trapezoidal", "Circular", "Rectangular"] {
            boton("opcion.\(geometria)").tap()
            XCTAssertTrue(existeTexto("Introduce los datos y pulsa calcular."), geometria)
        }
    }

    @MainActor
    func testLimpiarDejaElFormularioVacio() {
        abrir("inicio.conductos", "opcion.Caudal")
        cargarEjemplo()
        boton("menu.acciones").tap()
        app.buttons["Limpiar datos"].tap()
        XCTAssertTrue(existeTexto("Introduce los datos y pulsa calcular."))
        XCTAssertFalse(boton("accion.calcular").isEnabled)
    }

    @MainActor
    func testModoOscuroEnCanalCircular() {
        app.terminate()
        app.launchArguments = ["--pruebas-ui", "--modo-oscuro"]
        app.launch()
        abrir("inicio.canales")
        cargarEjemplo()
        irArriba()
        boton("opcion.Circular").tap()
        let diametro = app.textFields["campo.Diámetro D"]
        XCTAssertTrue(diametro.waitForExistence(timeout: 5))
        diametro.tap()
        diametro.typeText("1.5")
        app.toolbars.buttons["Listo"].tapSiExiste()
        captura("Canales - sección circular (oscuro)")
        boton("accion.calcular").tap()
        XCTAssertTrue(resultadoPrincipal().hasSuffix("m³/s"))
        captura("Canales - resultado circular (oscuro)")
    }

    @MainActor
    func testDocumentacionSeAbre() {
        boton("inicio.documentacion").tap()
        XCTAssertTrue(app.staticTexts["HidroFES Flow 2.0"].waitForExistence(timeout: 5))
    }

    // MARK: - Ayudas

    private func irArriba() {
        app.swipeDown()
        app.swipeDown()
    }

    private func captura(_ nombre: String) {
        let adjunto = XCTAttachment(screenshot: app.screenshot())
        adjunto.name = nombre
        adjunto.lifetime = .keepAlways
        add(adjunto)
    }

    private func boton(_ identificador: String) -> XCUIElement {
        let elemento = app.buttons[identificador]
        XCTAssertTrue(elemento.waitForExistence(timeout: 10), "No apareció \(identificador)")
        return elemento
    }

    private func abrir(_ ruta: String...) {
        for paso in ruta {
            boton(paso).tap()
        }
    }

    private func cargarEjemplo() {
        boton("menu.acciones").tap()
        let ejemplo = app.buttons["Cargar ejemplo"]
        XCTAssertTrue(ejemplo.waitForExistence(timeout: 5))
        ejemplo.tap()
    }

    private func resultadoPrincipal() -> String {
        let valor = app.staticTexts["resultado.principal"]
        XCTAssertTrue(valor.waitForExistence(timeout: 10), "No apareció el resultado")
        return valor.label
    }

    private func existeTexto(_ fragmento: String, timeout: TimeInterval = 5) -> Bool {
        let consulta = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", fragmento))
        return consulta.firstMatch.waitForExistence(timeout: timeout)
    }

    private func esperarResultado(_ esperado: String) -> Bool {
        let valor = app.staticTexts["resultado.principal"]
        let condicion = NSPredicate(format: "label == %@", esperado)
        return XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: condicion, object: valor)], timeout: 5) == .completed
    }
}

private extension XCUIElement {
    /// Toca al final del campo para dejar el cursor detrás del texto y lo borra.
    func borrarTexto() {
        coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        guard let texto = value as? String, !texto.isEmpty else { return }
        typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: texto.count))
    }

    func tapSiExiste() {
        if exists { tap() }
    }

    func desplazarHastaVer(en app: XCUIApplication) {
        var intentos = 0
        while !isHittable && intentos < 5 {
            app.swipeUp()
            intentos += 1
        }
    }
}
