import SwiftUI

/// Botón bajo el campo ΣK que trae el valor armado en Pérdidas locales.
private struct UsarSumaK: View {
    @Environment(SesionHidraulica.self) private var sesion
    @Binding var sumaK: String

    var body: some View {
        if let k = sesion.sumaKLocales, abs((Parseo.double(sumaK) ?? -1) - k) >= 0.005 {
            Button {
                sumaK = Formato.numero(k, decimales: 2)
            } label: {
                Label("Usar ΣK = \(Formato.numero(k, decimales: 2)) de Pérdidas locales", systemImage: "arrow.down.doc")
                    .font(.footnote.weight(.medium))
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("accion.usarSumaK")
        }
    }
}

struct CaudalView: View {
    @State private var form = FormularioCaudal()
    @State private var calculado: FormularioCaudal?
    @State private var salida = SalidaCalculo.vacia

    var body: some View {
        PantallaCalculo(
            titulo: "Caudal",
            subtitulo: "Conducción por gravedad",
            accion: "Calcular caudal",
            accionHabilitada: form.datosCompletos,
            onCalcular: calcular,
            onEjemplo: { form = .ejemplo; calcular() },
            onLimpiar: { form = FormularioCaudal(); calculado = nil; salida = .vacia }
        ) {
            SeccionTarjeta(titulo: "Geometría de la conducción", simbolo: "slider.horizontal.3") {
                CampoLongitud(etiqueta: "Diámetro interior", entrada: $form.diametro)
                CampoLongitud(etiqueta: "Longitud de la tubería", entrada: $form.longitud)
                SelectorMaterial(material: $form.material)
            }
            SeccionTarjeta(
                titulo: "Condiciones hidráulicas",
                simbolo: "flask",
                descripcion: "H = (1 + f·L/D + ΣK) · V²/2g"
            ) {
                CampoNumerico(etiqueta: "Carga total disponible H", texto: $form.carga, sufijo: "m", aviso: form.avisoCarga)
                CampoNumerico(
                    etiqueta: "Suma de coeficientes locales ΣK",
                    texto: $form.sumaK,
                    ayuda: "Usa el módulo de pérdidas locales para obtenerlo",
                    aviso: form.avisoSumaK
                )
                UsarSumaK(sumaK: $form.sumaK)
            }
            PanelResultados(salida: salida, titulo: "Caudal", desactualizado: calculado != nil && calculado != form)
                .id(IdentificadorUI.resultados)
            if salida.hayResultado, !salida.reparto.isEmpty {
                RepartoCargaView(segmentos: salida.reparto)
            }
        }
    }

    private func calcular() {
        salida = form.calcular()
        calculado = form
    }
}

struct DiametroView: View {
    @State private var form = FormularioDiametro()
    @State private var calculado: FormularioDiametro?
    @State private var salida = SalidaCalculo.vacia

    var body: some View {
        PantallaCalculo(
            titulo: "Diámetro",
            subtitulo: "Conducción por gravedad",
            accion: "Calcular diámetro",
            accionHabilitada: form.datosCompletos,
            onCalcular: calcular,
            onEjemplo: { form = .ejemplo; calcular() },
            onLimpiar: { form = FormularioDiametro(); calculado = nil; salida = .vacia }
        ) {
            SeccionTarjeta(titulo: "Datos del proyecto", simbolo: "slider.horizontal.3") {
                CampoCaudal(etiqueta: "Gasto de diseño Q", entrada: $form.caudal)
                CampoLongitud(etiqueta: "Longitud de la tubería", entrada: $form.longitud)
                SelectorMaterial(material: $form.material)
            }
            SeccionTarjeta(
                titulo: "Condiciones hidráulicas",
                simbolo: "flask",
                descripcion: "Se itera sobre D hasta que la ecuación de la energía cierra."
            ) {
                CampoNumerico(etiqueta: "Carga total disponible H", texto: $form.carga, sufijo: "m", aviso: form.avisoCarga)
                CampoNumerico(etiqueta: "Suma de coeficientes locales ΣK", texto: $form.sumaK, aviso: form.avisoSumaK)
                UsarSumaK(sumaK: $form.sumaK)
            }
            PanelResultados(salida: salida, titulo: "Diámetro", desactualizado: calculado != nil && calculado != form)
                .id(IdentificadorUI.resultados)
            if salida.hayResultado, !salida.reparto.isEmpty {
                RepartoCargaView(segmentos: salida.reparto)
            }
        }
    }

    private func calcular() {
        salida = form.calcular()
        calculado = form
    }
}

struct PerdidasFriccionView: View {
    @Environment(\.hidro) private var hidro
    @State private var form = FormularioFriccion()
    @State private var calculado: FormularioFriccion?
    @State private var salida = SalidaCalculo.vacia

    var body: some View {
        PantallaCalculo(
            titulo: "Pérdidas por fricción",
            subtitulo: form.metodo.etiqueta,
            accion: "Calcular pérdidas",
            accionHabilitada: form.datosCompletos,
            onCalcular: calcular,
            onEjemplo: { form = .ejemplo; calcular() },
            onLimpiar: { form = FormularioFriccion(); calculado = nil; salida = .vacia }
        ) {
            SeccionTarjeta(
                titulo: "Método de cálculo",
                simbolo: "arrow.left.arrow.right",
                descripcion: form.metodo.descripcion
            ) {
                SelectorCapsulas(opciones: MetodoFriccion.allCases, seleccion: $form.metodo, etiqueta: \.etiquetaCorta)
            }
            SeccionTarjeta(titulo: "Datos de la conducción", simbolo: "slider.horizontal.3") {
                CampoLongitud(etiqueta: "Longitud L", entrada: $form.longitud)
                CampoLongitud(etiqueta: "Diámetro interior D", entrada: $form.diametro)
                CampoCaudal(etiqueta: "Gasto Q", entrada: $form.caudal)
                SelectorMaterial(material: $form.material)
            }
            PanelResultados(salida: salida, titulo: "Pérdidas por fricción", desactualizado: calculado != nil && calculado != form)
                .id(IdentificadorUI.resultados)
            if salida.hayResultado, !salida.comparativa.isEmpty {
                tarjetaComparativa
            }
        }
        .onChange(of: form.metodo) {
            if calculado != nil { calcular() }
        }
    }

    private var tarjetaComparativa: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Contraste entre métodos")
                .font(.title3.weight(.semibold))
            Text("Mismos datos resueltos por las tres formulaciones.")
                .font(.caption)
            Divider()
            ForEach(salida.comparativa) { item in
                HStack {
                    if item.metodo == form.metodo {
                        Image(systemName: "checkmark.circle.fill")
                    }
                    Text(item.metodo.etiqueta)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(Formato.conUnidad(item.perdida, "m"))
                        .monospacedDigit()
                    if let diferencia = item.diferenciaPorcentual {
                        Text("(\(diferencia >= 0 ? "+" : "")\(Formato.numero(diferencia, decimales: 1)) %)")
                            .font(.caption.monospacedDigit())
                    }
                }
                .font(.subheadline.weight(item.metodo == form.metodo ? .semibold : .regular))
                .accessibilityElement(children: .combine)
            }
        }
        .foregroundStyle(hidro.sobreContenedorTerciario)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(hidro.contenedorTerciario, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func calcular() {
        salida = form.calcular()
        calculado = form
    }
}

struct PerdidasLocalesView: View {
    @Environment(\.hidro) private var hidro
    @Environment(SesionHidraulica.self) private var sesion
    @State private var form = FormularioLocales()
    @State private var salida = SalidaCalculo.vacia
    @State private var abiertas: Set<CategoriaAccesorio> = Set(CategoriaAccesorio.allCases)

    var body: some View {
        PantallaCalculo(
            titulo: "Pérdidas locales",
            subtitulo: "ΣK = \(Formato.numero(form.coeficienteKTotal, decimales: 2))",
            accion: "Calcular pérdidas locales",
            accionHabilitada: form.datosCompletos,
            onCalcular: calcular,
            onEjemplo: { form = .ejemplo; calcular() },
            onLimpiar: { form = FormularioLocales(); salida = .vacia }
        ) {
            SeccionTarjeta(titulo: "Condiciones de flujo", simbolo: "slider.horizontal.3") {
                CampoCaudal(etiqueta: "Gasto Q", entrada: $form.caudal)
                CampoLongitud(etiqueta: "Diámetro interior D", entrada: $form.diametro)
            }
            SeccionTarjeta(titulo: "Accesorios", simbolo: "wrench.and.screwdriver", descripcion: "h_L = ΣK · V²/2g") {
                HStack {
                    Text("ΣK = \(Formato.numero(form.coeficienteKTotal, decimales: 2))")
                        .font(.headline.monospacedDigit())
                        .contentTransition(.numericText())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(hidro.contenedorPrimario))
                        .foregroundStyle(hidro.sobreContenedorPrimario)
                        .accessibilityIdentifier("locales.sumaK")
                    Text("\(form.piezasTotales) piezas")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Limpiar") {
                        withAnimation { form.limpiarSeleccion() }
                    }
                    .buttonStyle(.bordered)
                    .disabled(form.piezasTotales == 0)
                }
                ForEach(CategoriaAccesorio.allCases) { categoria in
                    let piezas = form.seleccion.filter { $0.accesorio.categoria == categoria }
                    if !piezas.isEmpty {
                        DisclosureGroup(isExpanded: abierta(categoria)) {
                            VStack(spacing: 8) {
                                ForEach(piezas) { pieza in
                                    fila(pieza)
                                }
                            }
                            .padding(.top, 8)
                        } label: {
                            HStack {
                                Text(categoria.etiqueta)
                                    .font(.headline)
                                    .foregroundStyle(hidro.primario)
                                let cuenta = piezas.reduce(0) { $0 + $1.cantidad }
                                if cuenta > 0 {
                                    Text("\(cuenta)")
                                        .font(.caption.weight(.bold))
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(hidro.primario))
                                        .foregroundStyle(hidro.sobrePrimario)
                                }
                            }
                        }
                        .tint(hidro.primario)
                    }
                }
            }
            PanelResultados(salida: salida, titulo: "Pérdidas locales")
                .id(IdentificadorUI.resultados)
        }
        .onChange(of: form) {
            if salida.hayResultado || salida.error != nil { calcular() }
        }
        .onChange(of: form.coeficienteKTotal, initial: true) {
            sesion.sumaKLocales = form.coeficienteKTotal > 0 ? form.coeficienteKTotal : nil
        }
    }

    private func abierta(_ categoria: CategoriaAccesorio) -> Binding<Bool> {
        Binding(
            get: { abiertas.contains(categoria) },
            set: { valor in
                if valor { abiertas.insert(categoria) } else { abiertas.remove(categoria) }
            }
        )
    }

    private func fila(_ seleccionado: AccesorioSeleccionado) -> some View {
        let activo = seleccionado.cantidad > 0
        let nombre = seleccionado.accesorio.nombre
        return HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(nombre)
                    .font(.subheadline)
                Text(detalleK(seleccionado, activo: activo))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(activo ? hidro.primario : .secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                form.ajustar(nombre, delta: -1)
            } label: {
                Image(systemName: "minus")
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.bordered)
            .disabled(!activo)
            .accessibilityLabel("Quitar \(nombre)")
            Text("\(seleccionado.cantidad)")
                .font(.title3.weight(.semibold).monospacedDigit())
                .contentTransition(.numericText())
                .frame(minWidth: 28)
                .accessibilityIdentifier("cantidad.\(nombre)")
            Button {
                form.ajustar(nombre, delta: 1)
            } label: {
                Image(systemName: "plus")
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.borderedProminent)
            .tint(hidro.primario)
            .disabled(seleccionado.cantidad >= FormularioLocales.maximoPorPieza)
            .accessibilityLabel("Añadir \(nombre)")
            .accessibilityIdentifier("accesorio.mas.\(nombre)")
        }
        .padding(10)
        .background(activo ? hidro.contenedorPrimario.opacity(0.35) : Color.clear, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(activo ? hidro.primario.opacity(0.5) : Color.secondary.opacity(0.3), lineWidth: 1)
        )
        .sensoryFeedback(.increase, trigger: seleccionado.cantidad)
    }

    private func detalleK(_ seleccionado: AccesorioSeleccionado, activo: Bool) -> String {
        let base = "K = \(Formato.numero(seleccionado.accesorio.coeficienteK, decimales: 2))"
        return activo ? base + "   →   aporta \(Formato.numero(seleccionado.aporteK, decimales: 2))" : base
    }

    private func calcular() {
        salida = form.calcular()
    }
}

struct CeleridadView: View {
    @State private var form = FormularioCeleridad()
    @State private var calculado: FormularioCeleridad?
    @State private var salida = SalidaCalculo.vacia

    var body: some View {
        PantallaCalculo(
            titulo: "Celeridad",
            subtitulo: "Golpe de ariete · Allievi-Korteweg",
            accion: "Calcular celeridad",
            accionHabilitada: form.datosCompletos,
            onCalcular: calcular,
            onEjemplo: { form = .ejemplo; calcular() },
            onLimpiar: { form = FormularioCeleridad(); calculado = nil; salida = .vacia }
        ) {
            SeccionTarjeta(
                titulo: "Tubería",
                simbolo: "slider.horizontal.3",
                descripcion: "a = 1 / √( ρ · ( 1/K + D/(E·e) ) )"
            ) {
                CampoLongitud(etiqueta: "Diámetro interior D", entrada: $form.diametro)
                CampoLongitud(etiqueta: "Espesor de pared e", entrada: $form.espesor)
                SelectorElastico(material: $form.material)
            }
            SeccionTarjeta(
                titulo: "Datos opcionales del transitorio",
                simbolo: "bolt",
                descripcion: "Permiten obtener el tiempo crítico y la sobrepresión de Joukowsky."
            ) {
                CampoLongitud(etiqueta: "Longitud de la conducción L", entrada: $form.longitud)
                CampoNumerico(etiqueta: "Velocidad de régimen V₀", texto: $form.velocidad, sufijo: "m/s", aviso: form.avisoVelocidad)
            }
            PanelResultados(salida: salida, titulo: "Celeridad", desactualizado: calculado != nil && calculado != form)
                .id(IdentificadorUI.resultados)
        }
    }

    private func calcular() {
        salida = form.calcular()
        calculado = form
    }
}
