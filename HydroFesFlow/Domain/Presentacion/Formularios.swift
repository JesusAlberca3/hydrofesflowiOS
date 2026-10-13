import Foundation

// Cada formulario guarda lo escrito por el usuario, sabe si basta para calcular
// y traduce el resultado del dominio a los renglones del panel.

struct FormularioCaudal: Equatable {
    var diametro = EntradaLongitud(unidad: .milimetro)
    var longitud = EntradaLongitud()
    var material = CatalogoMateriales.porDefecto
    var carga = ""
    var sumaK = "0"

    /// Ejemplo de comprobación de docs/CALCULOS.md del proyecto Android.
    static let ejemplo = FormularioCaudal(
        diametro: EntradaLongitud(texto: "300", unidad: .milimetro),
        longitud: EntradaLongitud(texto: "1000", unidad: .metro),
        material: CatalogoMateriales.porDefecto,
        carga: "20",
        sumaK: "2"
    )

    var datosCompletos: Bool {
        diametro.valorMetros != nil && longitud.valorMetros != nil
            && Parseo.double(carga) != nil && Parseo.double(sumaK) != nil
    }

    var avisoCarga: String? { AvisoCampo.positivo(carga) }
    var avisoSumaK: String? { AvisoCampo.noNegativo(sumaK) }

    func calcular() -> SalidaCalculo {
        guard let d = diametro.valorMetros, let l = longitud.valorMetros,
              let h = Parseo.double(carga), let k = Parseo.double(sumaK) else {
            return .fallo(Errores.datosIncompletos)
        }
        switch FlujoGravedad.caudal(diametroM: d, longitudM: l, rugosidadMm: material.rugosidadMm, cargaDisponibleM: h, sumaK: k) {
        case .error(let mensaje):
            return .fallo(mensaje)
        case .exito(let v, let avisos):
            return SalidaCalculo(
                renglones: [
                    Renglon(
                        etiqueta: "Caudal Q",
                        valor: Formato.conUnidad(UnidadCaudal.litroSegundo.desdeM3s(v.caudalM3s), "L/s", decimales: 3),
                        destacado: true,
                        nota: "\(Formato.auto(v.caudalM3s)) m³/s"
                    ),
                    Renglon(etiqueta: "Velocidad media V", valor: Formato.conUnidad(v.velocidad, "m/s")),
                    Renglon(etiqueta: "Área hidráulica A", valor: Formato.conUnidad(v.area, "m²")),
                    Renglon(etiqueta: "Número de Reynolds", valor: Formato.cientifico(v.reynolds)),
                    Renglon(etiqueta: "Factor de fricción f", valor: Formato.numero(v.factorFriccion, decimales: 5)),
                    Renglon(etiqueta: "Régimen", valor: etiquetaRegimenFlujo(v.regimen)),
                    Renglon(etiqueta: "Pérdida por fricción", valor: Formato.conUnidad(v.perdidaFriccionM, "m")),
                    Renglon(etiqueta: "Pérdidas locales", valor: Formato.conUnidad(v.perdidaLocalM, "m")),
                    Renglon(etiqueta: "Carga de velocidad V²/2g", valor: Formato.conUnidad(v.cargaVelocidadM, "m")),
                    Renglon(etiqueta: "Iteraciones", valor: String(v.iteraciones)),
                ],
                advertencias: unicas(avisos),
                reparto: SalidaCalculo.repartoDeCarga(friccion: v.perdidaFriccionM, locales: v.perdidaLocalM, velocidad: v.cargaVelocidadM)
            )
        }
    }
}

struct FormularioDiametro: Equatable {
    var caudal = EntradaCaudal()
    var longitud = EntradaLongitud()
    var material = CatalogoMateriales.porDefecto
    var carga = ""
    var sumaK = "0"

    static let ejemplo = FormularioDiametro(
        caudal: EntradaCaudal(texto: "214.185", unidad: .litroSegundo),
        longitud: EntradaLongitud(texto: "1000", unidad: .metro),
        material: CatalogoMateriales.porDefecto,
        carga: "20",
        sumaK: "2"
    )

    var datosCompletos: Bool {
        caudal.valorM3s != nil && longitud.valorMetros != nil
            && Parseo.double(carga) != nil && Parseo.double(sumaK) != nil
    }

    var avisoCarga: String? { AvisoCampo.positivo(carga) }
    var avisoSumaK: String? { AvisoCampo.noNegativo(sumaK) }

    func calcular() -> SalidaCalculo {
        guard let q = caudal.valorM3s, let l = longitud.valorMetros,
              let h = Parseo.double(carga), let k = Parseo.double(sumaK) else {
            return .fallo(Errores.datosIncompletos)
        }
        switch FlujoGravedad.diametro(caudalM3s: q, longitudM: l, rugosidadMm: material.rugosidadMm, cargaDisponibleM: h, sumaK: k) {
        case .error(let mensaje):
            return .fallo(mensaje)
        case .exito(let v, let avisos):
            let mm = Formato.numero(UnidadLongitud.milimetro.desdeMetros(v.diametroM), decimales: 2)
            let pulgadas = Formato.numero(UnidadLongitud.pulgada.desdeMetros(v.diametroM), decimales: 2)
            return SalidaCalculo(
                renglones: [
                    Renglon(etiqueta: "Diámetro calculado D", valor: Formato.conUnidad(v.diametroM, "m"), destacado: true),
                    Renglon(etiqueta: "Equivalencias", valor: "\(mm) mm  ·  \(pulgadas) in"),
                    Renglon(etiqueta: "Velocidad media V", valor: Formato.conUnidad(v.velocidad, "m/s")),
                    Renglon(etiqueta: "Área hidráulica A", valor: Formato.conUnidad(v.area, "m²")),
                    Renglon(etiqueta: "Número de Reynolds", valor: Formato.cientifico(v.reynolds)),
                    Renglon(etiqueta: "Factor de fricción f", valor: Formato.numero(v.factorFriccion, decimales: 5)),
                    Renglon(etiqueta: "Régimen", valor: etiquetaRegimenFlujo(v.regimen)),
                    Renglon(etiqueta: "Pérdida por fricción", valor: Formato.conUnidad(v.perdidaFriccionM, "m")),
                    Renglon(etiqueta: "Pérdidas locales", valor: Formato.conUnidad(v.perdidaLocalM, "m")),
                    Renglon(etiqueta: "Carga de velocidad V²/2g", valor: Formato.conUnidad(v.cargaVelocidadM, "m")),
                    Renglon(etiqueta: "Iteraciones hasta converger", valor: String(v.iteraciones)),
                ],
                advertencias: unicas(avisos),
                reparto: SalidaCalculo.repartoDeCarga(friccion: v.perdidaFriccionM, locales: v.perdidaLocalM, velocidad: v.cargaVelocidadM)
            )
        }
    }
}

struct FormularioFriccion: Equatable {
    var longitud = EntradaLongitud()
    var diametro = EntradaLongitud(unidad: .milimetro)
    var caudal = EntradaCaudal()
    var material = CatalogoMateriales.porDefecto
    var metodo = MetodoFriccion.darcyWeisbach

    /// Segundo caso de comprobación de docs/CALCULOS.md.
    static let ejemplo = FormularioFriccion(
        longitud: EntradaLongitud(texto: "100", unidad: .metro),
        diametro: EntradaLongitud(texto: "200", unidad: .milimetro),
        caudal: EntradaCaudal(texto: "50", unidad: .litroSegundo),
        material: CatalogoMateriales.porDefecto,
        metodo: .darcyWeisbach
    )

    var datosCompletos: Bool {
        longitud.valorMetros != nil && diametro.valorMetros != nil && caudal.valorM3s != nil
    }

    func evaluar(_ metodo: MetodoFriccion, l: Double, d: Double, q: Double) -> Resultado<PerdidaFriccion> {
        switch metodo {
        case .darcyWeisbach:
            PerdidasFriccion.darcyWeisbach(longitudM: l, diametroM: d, rugosidadMm: material.rugosidadMm, caudalM3s: q)
        case .hazenWilliams:
            PerdidasFriccion.hazenWilliams(longitudM: l, diametroM: d, coeficienteC: material.coeficienteHazenWilliams, caudalM3s: q)
        case .chezyManning:
            PerdidasFriccion.chezyManning(longitudM: l, diametroM: d, coeficienteN: material.coeficienteManning, caudalM3s: q)
        }
    }

    func calcular() -> SalidaCalculo {
        guard let l = longitud.valorMetros, let d = diametro.valorMetros, let q = caudal.valorM3s else {
            return .fallo(Errores.datosIncompletos)
        }
        let perdidas = MetodoFriccion.allCases.compactMap { m in
            evaluar(m, l: l, d: d, q: q).valor.map { (m, $0.perdidaM) }
        }
        let referencia = perdidas.first { $0.0 == .darcyWeisbach }?.1
        let comparativa = perdidas.map { m, perdida in
            ContrasteMetodo(
                metodo: m,
                perdida: perdida,
                diferenciaPorcentual: m == .darcyWeisbach ? nil : referencia.flatMap { ref in
                    ref > 0 ? (perdida / ref - 1) * 100 : nil
                }
            )
        }

        switch evaluar(metodo, l: l, d: d, q: q) {
        case .error(let mensaje):
            return .fallo(mensaje)
        case .exito(let v, let avisos):
            var filas = [
                Renglon(etiqueta: "Pérdida por fricción h_f", valor: Formato.conUnidad(v.perdidaM, "m", decimales: 4), destacado: true),
                Renglon(etiqueta: "Gradiente hidráulico S", valor: Formato.conUnidad(v.gradienteHidraulico, "m/m", decimales: 6)),
                Renglon(etiqueta: "Velocidad media V", valor: Formato.conUnidad(v.velocidad, "m/s")),
                Renglon(etiqueta: "Área hidráulica A", valor: Formato.conUnidad(v.area, "m²")),
                Renglon(etiqueta: "Carga de velocidad V²/2g", valor: Formato.conUnidad(v.cargaVelocidad, "m")),
            ]
            if let re = v.reynolds {
                filas.append(Renglon(etiqueta: "Número de Reynolds", valor: Formato.cientifico(re)))
            }
            if let f = v.factorFriccion {
                filas.append(Renglon(etiqueta: "Factor de fricción f", valor: Formato.numero(f, decimales: 5)))
            }
            if let regimen = v.regimen {
                filas.append(Renglon(etiqueta: "Régimen", valor: etiquetaRegimenFlujo(regimen)))
            }
            return SalidaCalculo(
                renglones: filas,
                advertencias: unicas(avisos),
                comparativa: comparativa.count > 1 ? comparativa : []
            )
        }
    }
}

struct FormularioLocales: Equatable {
    static let maximoPorPieza = 99

    var caudal = EntradaCaudal()
    var diametro = EntradaLongitud(unidad: .milimetro)
    var seleccion = CatalogoAccesorios.seleccionInicial

    static var ejemplo: FormularioLocales {
        var formulario = FormularioLocales(
            caudal: EntradaCaudal(texto: "50", unidad: .litroSegundo),
            diametro: EntradaLongitud(texto: "150", unidad: .milimetro)
        )
        formulario.fijar("Codo de 90°", cantidad: 4)
        formulario.fijar("Salida", cantidad: 1)
        return formulario
    }

    var coeficienteKTotal: Double { seleccion.reduce(0) { $0 + $1.aporteK } }
    var piezasTotales: Int { seleccion.reduce(0) { $0 + $1.cantidad } }
    var datosCompletos: Bool { caudal.valorM3s != nil && diametro.valorMetros != nil }

    mutating func ajustar(_ nombre: String, delta: Int) {
        guard let indice = seleccion.firstIndex(where: { $0.accesorio.nombre == nombre }) else { return }
        let nueva = seleccion[indice].cantidad + delta
        seleccion[indice].cantidad = min(Self.maximoPorPieza, max(0, nueva))
    }

    mutating func fijar(_ nombre: String, cantidad: Int) {
        guard let indice = seleccion.firstIndex(where: { $0.accesorio.nombre == nombre }) else { return }
        seleccion[indice].cantidad = min(Self.maximoPorPieza, max(0, cantidad))
    }

    mutating func limpiarSeleccion() {
        seleccion = CatalogoAccesorios.seleccionInicial
    }

    func calcular() -> SalidaCalculo {
        guard let q = caudal.valorM3s, let d = diametro.valorMetros else {
            return .fallo(Errores.datosIncompletos)
        }
        switch PerdidasLocales.calcular(caudalM3s: q, diametroM: d, coeficienteKTotal: coeficienteKTotal) {
        case .error(let mensaje):
            return .fallo(mensaje)
        case .exito(let v, let avisos):
            return SalidaCalculo(
                renglones: [
                    Renglon(etiqueta: "Pérdida local h_L", valor: Formato.conUnidad(v.perdidaM, "m"), destacado: true),
                    Renglon(etiqueta: "Coeficiente total ΣK", valor: Formato.numero(v.coeficienteKTotal, decimales: 2)),
                    Renglon(etiqueta: "Velocidad media V", valor: Formato.conUnidad(v.velocidad, "m/s")),
                    Renglon(etiqueta: "Carga de velocidad V²/2g", valor: Formato.conUnidad(v.cargaVelocidad, "m")),
                    Renglon(etiqueta: "Área hidráulica A", valor: Formato.conUnidad(v.area, "m²")),
                    Renglon(etiqueta: "Piezas seleccionadas", valor: String(piezasTotales)),
                ],
                advertencias: unicas(avisos)
            )
        }
    }
}

struct FormularioCeleridad: Equatable {
    var diametro = EntradaLongitud(unidad: .milimetro)
    var espesor = EntradaLongitud(unidad: .milimetro)
    var material = CatalogoMaterialesElasticos.porDefecto
    var longitud = EntradaLongitud()
    var velocidad = ""

    static let ejemplo = FormularioCeleridad(
        diametro: EntradaLongitud(texto: "500", unidad: .milimetro),
        espesor: EntradaLongitud(texto: "8", unidad: .milimetro),
        material: CatalogoMaterialesElasticos.porNombre("Acero"),
        longitud: EntradaLongitud(texto: "1200", unidad: .metro),
        velocidad: "1.8"
    )

    var datosCompletos: Bool { diametro.valorMetros != nil && espesor.valorMetros != nil }
    var avisoVelocidad: String? { AvisoCampo.positivo(velocidad) }

    func calcular() -> SalidaCalculo {
        guard let d = diametro.valorMetros, let e = espesor.valorMetros else {
            return .fallo(Errores.datosIncompletos)
        }
        let resultado = Celeridad.calcular(
            diametroInteriorM: d,
            espesorM: e,
            moduloYoungPa: material.moduloYoungPa,
            longitudConduccionM: longitud.valorMetros,
            velocidadRegimen: Parseo.double(velocidad)
        )
        switch resultado {
        case .error(let mensaje):
            return .fallo(mensaje)
        case .exito(let v, let avisos):
            var filas = [
                Renglon(etiqueta: "Celeridad a", valor: Formato.conUnidad(v.celeridad, "m/s", decimales: 2), destacado: true),
                Renglon(
                    etiqueta: "Celeridad en agua libre √(K/ρ)",
                    valor: Formato.conUnidad(v.celeridadAguaLibre, "m/s", decimales: 2),
                    nota: "Límite superior teórico con pared indeformable"
                ),
                Renglon(etiqueta: "Sobrepresión por 1 m/s (a/g)", valor: Formato.conUnidad(v.sobrepresionPorMetroSegundo, "m", decimales: 2)),
            ]
            if let tiempo = v.tiempoCriticoS {
                filas.append(Renglon(
                    etiqueta: "Tiempo crítico 2L/a",
                    valor: Formato.conUnidad(tiempo, "s", decimales: 3),
                    nota: "Cierre más lento que este tiempo ⇒ maniobra lenta"
                ))
            }
            if let sobrepresion = v.sobrepresionJoukowskyM {
                filas.append(Renglon(
                    etiqueta: "Sobrepresión de Joukowsky",
                    valor: Formato.conUnidad(sobrepresion, "m", decimales: 2),
                    nota: "Δh = a·ΔV/g para cierre instantáneo"
                ))
            }
            filas.append(Renglon(etiqueta: "Material de pared", valor: material.nombre))
            filas.append(Renglon(etiqueta: "Módulo de Young E", valor: "\(Formato.numero(material.moduloYoungGPa, decimales: 1)) GPa"))

            var todos = avisos
            if longitud.avisoPositivo != nil {
                todos.append("La longitud de la conducción no es válida; se omitió el tiempo crítico.")
            }
            if avisoVelocidad != nil {
                todos.append("La velocidad de régimen no es válida; se omitió la sobrepresión de Joukowsky.")
            }
            return SalidaCalculo(renglones: filas, advertencias: unicas(todos))
        }
    }
}

struct FormularioCanal: Equatable {
    var geometria = GeometriaCanal.rectangular
    var pendiente = ""
    var manning = ""
    var tirante = EntradaLongitud()
    var ancho = EntradaLongitud()
    var talud = ""
    var diametro = EntradaLongitud()

    /// Canal rectangular de las pruebas del proyecto Android.
    static let ejemplo = FormularioCanal(
        geometria: .rectangular,
        pendiente: "0.001",
        manning: "0.015",
        tirante: EntradaLongitud(texto: "1", unidad: .metro),
        ancho: EntradaLongitud(texto: "3", unidad: .metro)
    )

    var datosCompletos: Bool {
        guard Parseo.double(pendiente) != nil, Parseo.double(manning) != nil, tirante.valorMetros != nil else {
            return false
        }
        switch geometria {
        case .rectangular: return ancho.valorMetros != nil
        case .triangular: return Parseo.double(talud) != nil
        case .trapezoidal: return ancho.valorMetros != nil && Parseo.double(talud) != nil
        case .circular: return diametro.valorMetros != nil
        }
    }

    var avisoPendiente: String? { AvisoCampo.positivo(pendiente) }
    var avisoManning: String? { AvisoCampo.positivo(manning) }
    var avisoTalud: String? { AvisoCampo.positivo(talud) }

    var avisoAncho: String? {
        geometria == .trapezoidal ? ancho.avisoNoNegativo : ancho.avisoPositivo
    }

    var avisoTirante: String? {
        if let aviso = tirante.avisoPositivo { return aviso }
        if geometria == .circular, let y = tirante.valorMetros, let d = diametro.valorMetros, d > 0, y > d {
            return "En sección circular debe ser menor o igual que D."
        }
        return nil
    }

    var datos: DatosCanal? {
        guard let s = Parseo.double(pendiente), let n = Parseo.double(manning), let y = tirante.valorMetros else {
            return nil
        }
        return DatosCanal(
            geometria: geometria,
            pendiente: s,
            manning: n,
            tirante: y,
            anchoPlantilla: ancho.valorMetros ?? 0,
            talud: Parseo.double(talud) ?? 0,
            diametro: diametro.valorMetros ?? 0
        )
    }

    func calcular() -> SalidaCalculo {
        guard datosCompletos, let datos else { return .fallo(Errores.datosIncompletos) }
        switch Canales.calcular(datos) {
        case .error(let mensaje):
            return .fallo(mensaje)
        case .exito(let v, let avisos):
            var filas = [
                Renglon(
                    etiqueta: "Caudal Q",
                    valor: Formato.conUnidad(v.caudal, "m³/s"),
                    destacado: true,
                    nota: "\(Formato.numero(UnidadCaudal.litroSegundo.desdeM3s(v.caudal), decimales: 1)) L/s"
                ),
                Renglon(etiqueta: "Velocidad media V", valor: Formato.conUnidad(v.velocidad, "m/s")),
                Renglon(etiqueta: "Área hidráulica A", valor: Formato.conUnidad(v.area, "m²")),
                Renglon(etiqueta: "Perímetro mojado P", valor: Formato.conUnidad(v.perimetroMojado, "m")),
                Renglon(etiqueta: "Radio hidráulico R", valor: Formato.conUnidad(v.radioHidraulico, "m")),
                Renglon(etiqueta: "Espejo de agua T", valor: Formato.conUnidad(v.espejoAgua, "m")),
            ]
            if let profundidad = v.profundidadHidraulica {
                filas.append(Renglon(etiqueta: "Profundidad hidráulica A/T", valor: Formato.conUnidad(profundidad, "m")))
            }
            filas.append(Renglon(etiqueta: "Energía específica E", valor: Formato.conUnidad(v.energiaEspecifica, "m")))
            if let froude = v.numeroFroude {
                filas.append(Renglon(etiqueta: "Número de Froude Fr", valor: Formato.numero(froude, decimales: 4)))
                if let regimen = v.regimen {
                    let tono: Tono = switch regimen {
                    case .subcritico: .subcritico
                    case .critico: .critico
                    case .supercritico: .supercritico
                    }
                    filas.append(Renglon(etiqueta: "Régimen", valor: regimen.etiqueta, nota: regimen.nota, tono: tono))
                }
            } else {
                filas.append(Renglon(etiqueta: "Número de Froude Fr", valor: "no definido", nota: "T → 0, sección llena"))
            }
            if let yc = v.tiranteCritico {
                filas.append(Renglon(
                    etiqueta: "Tirante crítico y_c",
                    valor: Formato.conUnidad(yc, "m"),
                    nota: "Resuelto por bisección sobre Q²T/(gA³) = 1"
                ))
            }
            if let llenado = v.relacionLlenado {
                filas.append(Renglon(etiqueta: "Relación de llenado y/D", valor: Formato.numero(llenado, decimales: 3)))
            }
            return SalidaCalculo(renglones: filas, advertencias: unicas(avisos))
        }
    }
}
