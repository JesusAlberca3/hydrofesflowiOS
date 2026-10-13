import SwiftUI

struct CaudalView: View {
    @State private var diametro = EntradaLongitud(unidad: .milimetro)
    @State private var longitud = EntradaLongitud()
    @State private var material = CatalogoMateriales.porDefecto
    @State private var carga = ""
    @State private var sumaK = "0"
    @State private var renglones: [Renglon] = []
    @State private var error: String?
    @State private var advertencias: [String] = []

    private var datosCompletos: Bool {
        diametro.valorMetros != nil && longitud.valorMetros != nil
            && Parseo.double(carga) != nil && Parseo.double(sumaK) != nil
    }

    var body: some View {
        PantallaCalculo(
            titulo: "Caudal",
            subtitulo: "Conducción por gravedad",
            accion: "Calcular caudal",
            accionHabilitada: datosCompletos,
            onCalcular: calcular
        ) {
            SeccionTarjeta(titulo: "Geometría de la conducción", simbolo: "slider.horizontal.3") {
                CampoLongitud(etiqueta: "Diámetro interior", entrada: $diametro)
                CampoLongitud(etiqueta: "Longitud de la tubería", entrada: $longitud)
                SelectorMaterial(material: $material)
            }
            SeccionTarjeta(
                titulo: "Condiciones hidráulicas",
                simbolo: "flask",
                descripcion: "H = (1 + f·L/D + ΣK) · V²/2g"
            ) {
                CampoNumerico(etiqueta: "Carga total disponible H", texto: $carga, sufijo: "m")
                CampoNumerico(
                    etiqueta: "Suma de coeficientes locales ΣK",
                    texto: $sumaK,
                    ayuda: "Usa el módulo de pérdidas locales para obtenerlo"
                )
            }
            PanelResultados(renglones: renglones, error: error, advertencias: advertencias)
        }
    }

    private func calcular() {
        guard let d = diametro.valorMetros, let l = longitud.valorMetros,
              let h = Parseo.double(carga), let k = Parseo.double(sumaK) else {
            renglones = []
            error = Errores.datosIncompletos
            advertencias = []
            return
        }
        switch FlujoGravedad.caudal(
            diametroM: d,
            longitudM: l,
            rugosidadMm: material.rugosidadMm,
            cargaDisponibleM: h,
            sumaK: k
        ) {
        case .error(let mensaje):
            renglones = []
            error = mensaje
            advertencias = []
        case .exito(let valor, let avisos):
            error = nil
            advertencias = avisos
            renglones = [
                Renglon(
                    etiqueta: "Caudal Q",
                    valor: Formato.conUnidad(UnidadCaudal.litroSegundo.desdeM3s(valor.caudalM3s), "L/s", decimales: 3),
                    destacado: true,
                    nota: "\(Formato.auto(valor.caudalM3s)) m³/s"
                ),
                Renglon(etiqueta: "Velocidad media V", valor: Formato.conUnidad(valor.velocidad, "m/s")),
                Renglon(etiqueta: "Área hidráulica A", valor: Formato.conUnidad(valor.area, "m²")),
                Renglon(etiqueta: "Número de Reynolds", valor: Formato.cientifico(valor.reynolds)),
                Renglon(etiqueta: "Factor de fricción f", valor: Formato.numero(valor.factorFriccion, decimales: 5)),
                Renglon(etiqueta: "Régimen", valor: etiquetaRegimenFlujo(valor.regimen)),
                Renglon(etiqueta: "Pérdida por fricción", valor: Formato.conUnidad(valor.perdidaFriccionM, "m")),
                Renglon(etiqueta: "Pérdidas locales", valor: Formato.conUnidad(valor.perdidaLocalM, "m")),
                Renglon(etiqueta: "Carga de velocidad V²/2g", valor: Formato.conUnidad(valor.cargaVelocidadM, "m")),
                Renglon(etiqueta: "Iteraciones", valor: String(valor.iteraciones)),
            ]
        }
    }
}

struct DiametroView: View {
    @State private var caudal = EntradaCaudal()
    @State private var longitud = EntradaLongitud()
    @State private var material = CatalogoMateriales.porDefecto
    @State private var carga = ""
    @State private var sumaK = "0"
    @State private var renglones: [Renglon] = []
    @State private var error: String?
    @State private var advertencias: [String] = []

    private var datosCompletos: Bool {
        caudal.valorM3s != nil && longitud.valorMetros != nil
            && Parseo.double(carga) != nil && Parseo.double(sumaK) != nil
    }

    var body: some View {
        PantallaCalculo(
            titulo: "Diámetro",
            subtitulo: "Conducción por gravedad",
            accion: "Calcular diámetro",
            accionHabilitada: datosCompletos,
            onCalcular: calcular
        ) {
            SeccionTarjeta(titulo: "Datos del proyecto", simbolo: "slider.horizontal.3") {
                CampoCaudal(etiqueta: "Gasto de diseño Q", entrada: $caudal)
                CampoLongitud(etiqueta: "Longitud de la tubería", entrada: $longitud)
                SelectorMaterial(material: $material)
            }
            SeccionTarjeta(
                titulo: "Condiciones hidráulicas",
                simbolo: "flask",
                descripcion: "Se itera sobre D hasta que la ecuación de la energía cierra."
            ) {
                CampoNumerico(etiqueta: "Carga total disponible H", texto: $carga, sufijo: "m")
                CampoNumerico(etiqueta: "Suma de coeficientes locales ΣK", texto: $sumaK)
            }
            PanelResultados(renglones: renglones, error: error, advertencias: advertencias)
        }
    }

    private func calcular() {
        guard let q = caudal.valorM3s, let l = longitud.valorMetros,
              let h = Parseo.double(carga), let k = Parseo.double(sumaK) else {
            renglones = []
            error = Errores.datosIncompletos
            advertencias = []
            return
        }
        switch FlujoGravedad.diametro(
            caudalM3s: q,
            longitudM: l,
            rugosidadMm: material.rugosidadMm,
            cargaDisponibleM: h,
            sumaK: k
        ) {
        case .error(let mensaje):
            renglones = []
            error = mensaje
            advertencias = []
        case .exito(let valor, let avisos):
            error = nil
            advertencias = avisos
            let mm = Formato.numero(UnidadLongitud.milimetro.desdeMetros(valor.diametroM), decimales: 2)
            let pulgadas = Formato.numero(UnidadLongitud.pulgada.desdeMetros(valor.diametroM), decimales: 2)
            renglones = [
                Renglon(etiqueta: "Diámetro calculado D", valor: Formato.conUnidad(valor.diametroM, "m"), destacado: true),
                Renglon(etiqueta: "Equivalencias", valor: "\(mm) mm  ·  \(pulgadas) in"),
                Renglon(etiqueta: "Velocidad media V", valor: Formato.conUnidad(valor.velocidad, "m/s")),
                Renglon(etiqueta: "Área hidráulica A", valor: Formato.conUnidad(valor.area, "m²")),
                Renglon(etiqueta: "Número de Reynolds", valor: Formato.cientifico(valor.reynolds)),
                Renglon(etiqueta: "Factor de fricción f", valor: Formato.numero(valor.factorFriccion, decimales: 5)),
                Renglon(etiqueta: "Régimen", valor: etiquetaRegimenFlujo(valor.regimen)),
                Renglon(etiqueta: "Pérdida por fricción", valor: Formato.conUnidad(valor.perdidaFriccionM, "m")),
                Renglon(etiqueta: "Pérdidas locales", valor: Formato.conUnidad(valor.perdidaLocalM, "m")),
                Renglon(etiqueta: "Carga de velocidad V²/2g", valor: Formato.conUnidad(valor.cargaVelocidadM, "m")),
                Renglon(etiqueta: "Iteraciones hasta converger", valor: String(valor.iteraciones)),
            ]
        }
    }
}

private struct ContrasteMetodo: Identifiable {
    let metodo: MetodoFriccion
    let perdida: Double
    var id: String { metodo.rawValue }
}

struct PerdidasFriccionView: View {
    @Environment(\.hidro) private var hidro
    @State private var longitud = EntradaLongitud()
    @State private var diametro = EntradaLongitud(unidad: .milimetro)
    @State private var caudal = EntradaCaudal()
    @State private var material = CatalogoMateriales.porDefecto
    @State private var metodo = MetodoFriccion.darcyWeisbach
    @State private var renglones: [Renglon] = []
    @State private var comparativa: [ContrasteMetodo] = []
    @State private var error: String?
    @State private var advertencias: [String] = []

    private var datosCompletos: Bool {
        longitud.valorMetros != nil && diametro.valorMetros != nil && caudal.valorM3s != nil
    }

    var body: some View {
        PantallaCalculo(
            titulo: "Pérdidas por fricción",
            subtitulo: metodo.etiqueta,
            accion: "Calcular pérdidas",
            accionHabilitada: datosCompletos,
            onCalcular: calcular
        ) {
            SeccionTarjeta(
                titulo: "Método de cálculo",
                simbolo: "arrow.left.arrow.right",
                descripcion: metodo.descripcion
            ) {
                HStack(spacing: 8) {
                    ForEach(MetodoFriccion.allCases) { opcion in
                        Button(opcion.etiquetaCorta) {
                            metodo = opcion
                            if !renglones.isEmpty || error != nil { calcular() }
                        }
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(metodo == opcion ? hidro.primario : hidro.variante.opacity(0.8))
                        )
                        .foregroundStyle(metodo == opcion ? hidro.sobrePrimario : hidro.sobreFondo)
                        .buttonStyle(.plain)
                    }
                }
            }
            SeccionTarjeta(titulo: "Datos de la conducción", simbolo: "slider.horizontal.3") {
                CampoLongitud(etiqueta: "Longitud L", entrada: $longitud)
                CampoLongitud(etiqueta: "Diámetro interior D", entrada: $diametro)
                CampoCaudal(etiqueta: "Gasto Q", entrada: $caudal)
                SelectorMaterial(material: $material)
            }
            PanelResultados(renglones: renglones, error: error, advertencias: advertencias)
            if comparativa.count > 1 {
                tarjetaComparativa
            }
        }
    }

    private var tarjetaComparativa: some View {
        let referencia = comparativa.first { $0.metodo == .darcyWeisbach }?.perdida
        return VStack(alignment: .leading, spacing: 8) {
            Text("Contraste entre métodos")
                .font(.title3.weight(.semibold))
            Text("Mismos datos resueltos por las tres formulaciones.")
                .font(.caption)
            Divider()
            ForEach(comparativa) { item in
                HStack {
                    Text(item.metodo.etiqueta)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(Formato.conUnidad(item.perdida, "m"))
                    if let referencia, referencia > 0, item.metodo != .darcyWeisbach {
                        Text("(\(Formato.numero((item.perdida / referencia - 1) * 100, decimales: 1)) %)")
                            .font(.caption)
                    }
                }
                .font(.subheadline)
            }
        }
        .foregroundStyle(hidro.sobreContenedorTerciario)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(hidro.contenedorTerciario, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func evaluar(_ metodo: MetodoFriccion, l: Double, d: Double, q: Double) -> Resultado<PerdidaFriccion> {
        switch metodo {
        case .darcyWeisbach:
            PerdidasFriccion.darcyWeisbach(longitudM: l, diametroM: d, rugosidadMm: material.rugosidadMm, caudalM3s: q)
        case .hazenWilliams:
            PerdidasFriccion.hazenWilliams(longitudM: l, diametroM: d, coeficienteC: material.coeficienteHazenWilliams, caudalM3s: q)
        case .chezyManning:
            PerdidasFriccion.chezyManning(longitudM: l, diametroM: d, coeficienteN: material.coeficienteManning, caudalM3s: q)
        }
    }

    private func calcular() {
        guard let l = longitud.valorMetros, let d = diametro.valorMetros, let q = caudal.valorM3s else {
            renglones = []
            comparativa = []
            error = Errores.datosIncompletos
            advertencias = []
            return
        }
        comparativa = MetodoFriccion.allCases.compactMap { metodo in
            evaluar(metodo, l: l, d: d, q: q).valor.map { ContrasteMetodo(metodo: metodo, perdida: $0.perdidaM) }
        }
        switch evaluar(metodo, l: l, d: d, q: q) {
        case .error(let mensaje):
            renglones = []
            comparativa = []
            error = mensaje
            advertencias = []
        case .exito(let valor, let avisos):
            error = nil
            advertencias = avisos
            var filas = [
                Renglon(etiqueta: "Pérdida por fricción h_f", valor: Formato.conUnidad(valor.perdidaM, "m", decimales: 4), destacado: true),
                Renglon(etiqueta: "Gradiente hidráulico S", valor: Formato.conUnidad(valor.gradienteHidraulico, "m/m", decimales: 6)),
                Renglon(etiqueta: "Velocidad media V", valor: Formato.conUnidad(valor.velocidad, "m/s")),
                Renglon(etiqueta: "Área hidráulica A", valor: Formato.conUnidad(valor.area, "m²")),
                Renglon(etiqueta: "Carga de velocidad V²/2g", valor: Formato.conUnidad(valor.cargaVelocidad, "m")),
            ]
            if let reynolds = valor.reynolds {
                filas.append(Renglon(etiqueta: "Número de Reynolds", valor: Formato.cientifico(reynolds)))
            }
            if let f = valor.factorFriccion {
                filas.append(Renglon(etiqueta: "Factor de fricción f", valor: Formato.numero(f, decimales: 5)))
            }
            if let regimen = valor.regimen {
                filas.append(Renglon(etiqueta: "Régimen", valor: etiquetaRegimenFlujo(regimen)))
            }
            renglones = filas
        }
    }
}

struct PerdidasLocalesView: View {
    @Environment(\.hidro) private var hidro
    @State private var caudal = EntradaCaudal()
    @State private var diametro = EntradaLongitud(unidad: .milimetro)
    @State private var seleccion = CatalogoAccesorios.seleccionInicial
    @State private var renglones: [Renglon] = []
    @State private var error: String?
    @State private var advertencias: [String] = []

    private var coeficienteKTotal: Double { seleccion.reduce(0) { $0 + $1.aporteK } }
    private var piezasTotales: Int { seleccion.reduce(0) { $0 + $1.cantidad } }
    private var datosCompletos: Bool { caudal.valorM3s != nil && diametro.valorMetros != nil }

    var body: some View {
        PantallaCalculo(
            titulo: "Pérdidas locales",
            subtitulo: "ΣK = \(Formato.numero(coeficienteKTotal, decimales: 2))",
            accion: "Calcular pérdidas locales",
            accionHabilitada: datosCompletos,
            onCalcular: calcular
        ) {
            SeccionTarjeta(titulo: "Condiciones de flujo", simbolo: "slider.horizontal.3") {
                CampoCaudal(etiqueta: "Gasto Q", entrada: $caudal)
                CampoLongitud(etiqueta: "Diámetro interior D", entrada: $diametro)
            }
            SeccionTarjeta(titulo: "Accesorios", simbolo: "wrench.and.screwdriver", descripcion: "h_L = ΣK · V²/2g") {
                HStack {
                    Text("ΣK = \(Formato.numero(coeficienteKTotal, decimales: 2))")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(hidro.contenedorPrimario))
                    Spacer()
                    Button("Limpiar") {
                        seleccion = CatalogoAccesorios.seleccionInicial
                        recalcularSiProcede()
                    }
                    .buttonStyle(.bordered)
                }
                ForEach(CategoriaAccesorio.allCases) { categoria in
                    let piezas = seleccion.filter { $0.accesorio.categoria == categoria }
                    if !piezas.isEmpty {
                        Text(categoria.etiqueta)
                            .font(.headline)
                            .foregroundStyle(hidro.primario)
                            .padding(.top, 4)
                        ForEach(piezas) { pieza in
                            fila(pieza)
                        }
                    }
                }
            }
            PanelResultados(renglones: renglones, error: error, advertencias: advertencias)
        }
    }

    private func fila(_ seleccionado: AccesorioSeleccionado) -> some View {
        let activo = seleccionado.cantidad > 0
        return HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(seleccionado.accesorio.nombre)
                    .font(.subheadline)
                Text(detalleK(seleccionado, activo: activo))
                    .font(.caption)
                    .foregroundStyle(activo ? hidro.primario : .secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                ajustar(seleccionado.accesorio.nombre, delta: -1)
            } label: {
                Image(systemName: "minus")
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.bordered)
            .disabled(!activo)
            Text("\(seleccionado.cantidad)")
                .font(.title3.weight(.semibold))
                .frame(minWidth: 24)
            Button {
                ajustar(seleccionado.accesorio.nombre, delta: 1)
            } label: {
                Image(systemName: "plus")
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.borderedProminent)
            .tint(hidro.primario)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
        )
    }

    private func detalleK(_ seleccionado: AccesorioSeleccionado, activo: Bool) -> String {
        let base = "K = \(Formato.numero(seleccionado.accesorio.coeficienteK, decimales: 2))"
        if activo {
            return base + "   →   aporta \(Formato.numero(seleccionado.aporteK, decimales: 2))"
        }
        return base
    }

    private func ajustar(_ nombre: String, delta: Int) {
        seleccion = seleccion.map { item in
            guard item.accesorio.nombre == nombre else { return item }
            var copia = item
            copia.cantidad = max(0, item.cantidad + delta)
            return copia
        }
        recalcularSiProcede()
    }

    private func recalcularSiProcede() {
        if !renglones.isEmpty || error != nil { calcular() }
    }

    private func calcular() {
        guard let q = caudal.valorM3s, let d = diametro.valorMetros else {
            renglones = []
            error = Errores.datosIncompletos
            advertencias = []
            return
        }
        switch PerdidasLocales.calcular(caudalM3s: q, diametroM: d, coeficienteKTotal: coeficienteKTotal) {
        case .error(let mensaje):
            renglones = []
            error = mensaje
            advertencias = []
        case .exito(let valor, let avisos):
            error = nil
            advertencias = avisos
            renglones = [
                Renglon(etiqueta: "Pérdida local h_L", valor: Formato.conUnidad(valor.perdidaM, "m"), destacado: true),
                Renglon(etiqueta: "Coeficiente total ΣK", valor: Formato.numero(valor.coeficienteKTotal, decimales: 2)),
                Renglon(etiqueta: "Velocidad media V", valor: Formato.conUnidad(valor.velocidad, "m/s")),
                Renglon(etiqueta: "Carga de velocidad V²/2g", valor: Formato.conUnidad(valor.cargaVelocidad, "m")),
                Renglon(etiqueta: "Área hidráulica A", valor: Formato.conUnidad(valor.area, "m²")),
                Renglon(etiqueta: "Piezas seleccionadas", valor: String(piezasTotales)),
            ]
        }
    }
}

struct CeleridadView: View {
    @State private var diametro = EntradaLongitud(unidad: .milimetro)
    @State private var espesor = EntradaLongitud(unidad: .milimetro)
    @State private var material = CatalogoMaterialesElasticos.porDefecto
    @State private var longitud = EntradaLongitud()
    @State private var velocidad = ""
    @State private var renglones: [Renglon] = []
    @State private var error: String?
    @State private var advertencias: [String] = []

    private var datosCompletos: Bool {
        diametro.valorMetros != nil && espesor.valorMetros != nil
    }

    var body: some View {
        PantallaCalculo(
            titulo: "Celeridad",
            subtitulo: "Golpe de ariete · Allievi-Korteweg",
            accion: "Calcular celeridad",
            accionHabilitada: datosCompletos,
            onCalcular: calcular
        ) {
            SeccionTarjeta(
                titulo: "Tubería",
                simbolo: "slider.horizontal.3",
                descripcion: "a = 1 / √( ρ · ( 1/K + D/(E·e) ) )"
            ) {
                CampoLongitud(etiqueta: "Diámetro interior D", entrada: $diametro)
                CampoLongitud(etiqueta: "Espesor de pared e", entrada: $espesor)
                SelectorElastico(material: $material)
            }
            SeccionTarjeta(
                titulo: "Datos opcionales del transitorio",
                simbolo: "bolt",
                descripcion: "Permiten obtener el tiempo crítico y la sobrepresión de Joukowsky."
            ) {
                CampoLongitud(etiqueta: "Longitud de la conducción L", entrada: $longitud)
                CampoNumerico(etiqueta: "Velocidad de régimen V₀", texto: $velocidad, sufijo: "m/s")
            }
            PanelResultados(renglones: renglones, error: error, advertencias: advertencias)
        }
    }

    private func calcular() {
        guard let d = diametro.valorMetros, let e = espesor.valorMetros else {
            renglones = []
            error = Errores.datosIncompletos
            advertencias = []
            return
        }
        switch Celeridad.calcular(
            diametroInteriorM: d,
            espesorM: e,
            moduloYoungPa: material.moduloYoungPa,
            longitudConduccionM: longitud.valorMetros,
            velocidadRegimen: Parseo.double(velocidad)
        ) {
        case .error(let mensaje):
            renglones = []
            error = mensaje
            advertencias = []
        case .exito(let valor, let avisos):
            error = nil
            advertencias = avisos
            var filas = [
                Renglon(etiqueta: "Celeridad a", valor: Formato.conUnidad(valor.celeridad, "m/s", decimales: 2), destacado: true),
                Renglon(
                    etiqueta: "Celeridad en agua libre √(K/ρ)",
                    valor: Formato.conUnidad(valor.celeridadAguaLibre, "m/s", decimales: 2),
                    nota: "Límite superior teórico con pared indeformable"
                ),
                Renglon(
                    etiqueta: "Sobrepresión por 1 m/s (a/g)",
                    valor: Formato.conUnidad(valor.sobrepresionPorMetroSegundo, "m", decimales: 2)
                ),
            ]
            if let tiempo = valor.tiempoCriticoS {
                filas.append(Renglon(
                    etiqueta: "Tiempo crítico 2L/a",
                    valor: Formato.conUnidad(tiempo, "s", decimales: 3),
                    nota: "Cierre más lento que este tiempo ⇒ maniobra lenta"
                ))
            }
            if let sobrepresion = valor.sobrepresionJoukowskyM {
                filas.append(Renglon(
                    etiqueta: "Sobrepresión de Joukowsky",
                    valor: Formato.conUnidad(sobrepresion, "m", decimales: 2),
                    nota: "Δh = a·ΔV/g para cierre instantáneo"
                ))
            }
            filas.append(Renglon(etiqueta: "Material de pared", valor: material.nombre))
            filas.append(Renglon(
                etiqueta: "Módulo de Young E",
                valor: "\(Formato.numero(material.moduloYoungGPa, decimales: 1)) GPa"
            ))
            renglones = filas
        }
    }
}
