import SwiftUI
import UIKit

private let localeNumerico = Locale(identifier: "en_US_POSIX")

enum IdentificadorUI {
    static let resultados = "panel.resultados"
}

/// Marco común de los campos: borde, aviso en rojo y ayuda opcional.
private struct MarcoCampo<Content: View>: View {
    @Environment(\.hidro) private var hidro
    var etiqueta: String
    var aviso: String?
    var ayuda: String?
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(etiqueta)
                .font(.subheadline.weight(.medium))
            HStack(spacing: 8) {
                content
            }
            .padding(12)
            .background(hidro.fondo.opacity(0.6), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(aviso == nil ? Color.secondary.opacity(0.35) : hidro.textoError, lineWidth: aviso == nil ? 1 : 1.5)
            )
            if let aviso {
                Label(aviso, systemImage: "exclamationmark.circle")
                    .font(.caption)
                    .foregroundStyle(hidro.textoError)
            } else if let ayuda {
                Text(ayuda)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: aviso)
    }
}

private struct CampoTexto: View {
    let etiqueta: String
    @Binding var texto: String

    var body: some View {
        TextField(etiqueta, text: Binding(
            get: { texto },
            set: { nuevo in
                if let limpio = Sanear.numero(nuevo) { texto = limpio }
            }
        ))
        .keyboardType(.decimalPad)
        .textFieldStyle(.plain)
        .accessibilityIdentifier("campo.\(etiqueta)")
    }
}

private struct SelectorUnidad<Unidad: Identifiable & Hashable>: View {
    let actual: String
    let opciones: [Unidad]
    let etiquetaDe: (Unidad) -> String
    let seleccionar: (Unidad) -> Void

    var body: some View {
        Menu {
            ForEach(opciones) { unidad in
                Button(etiquetaDe(unidad)) { seleccionar(unidad) }
            }
        } label: {
            HStack(spacing: 2) {
                Text(actual)
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.bold))
            }
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.secondary.opacity(0.15)))
        }
        .accessibilityLabel("Unidad: \(actual)")
    }
}

struct CampoNumerico: View {
    var etiqueta: String
    @Binding var texto: String
    var sufijo: String?
    var ayuda: String?
    var aviso: String?

    var body: some View {
        MarcoCampo(etiqueta: etiqueta, aviso: aviso, ayuda: ayuda) {
            CampoTexto(etiqueta: etiqueta, texto: $texto)
            if let sufijo {
                Text(sufijo)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct CampoLongitud: View {
    var etiqueta: String
    @Binding var entrada: EntradaLongitud
    var aviso: String?

    var body: some View {
        MarcoCampo(etiqueta: etiqueta, aviso: aviso ?? entrada.avisoPositivo, ayuda: conversion) {
            CampoTexto(etiqueta: etiqueta, texto: $entrada.texto)
            SelectorUnidad(
                actual: entrada.unidad.etiqueta,
                opciones: UnidadLongitud.allCases,
                etiquetaDe: \.etiqueta,
                seleccionar: { entrada.unidad = $0 }
            )
        }
    }

    private var conversion: String? {
        guard let metros = entrada.valorMetros, entrada.unidad != .metro else { return nil }
        return "= \(String(format: "%.6g", locale: localeNumerico, metros)) m"
    }
}

struct CampoCaudal: View {
    var etiqueta: String
    @Binding var entrada: EntradaCaudal

    var body: some View {
        MarcoCampo(etiqueta: etiqueta, aviso: entrada.avisoPositivo, ayuda: conversion) {
            CampoTexto(etiqueta: etiqueta, texto: $entrada.texto)
            SelectorUnidad(
                actual: entrada.unidad.etiqueta,
                opciones: UnidadCaudal.allCases,
                etiquetaDe: \.etiqueta,
                seleccionar: { entrada.unidad = $0 }
            )
        }
    }

    private var conversion: String? {
        guard let caudal = entrada.valorM3s, entrada.unidad != .metro3Segundo else { return nil }
        return "= \(String(format: "%.6g", locale: localeNumerico, caudal)) m³/s"
    }
}

private struct SelectorCatalogo<Opcion: Identifiable & Hashable>: View {
    let etiqueta: String
    let opciones: [Opcion]
    @Binding var seleccion: Opcion
    let nombre: (Opcion) -> String
    let detalle: (Opcion) -> String

    var body: some View {
        Menu {
            Picker(etiqueta, selection: $seleccion) {
                ForEach(opciones) { opcion in
                    Text(nombre(opcion)).tag(opcion)
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(etiqueta)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(nombre(seleccion))
                            .foregroundStyle(.primary)
                        Text(detalle(seleccion))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.secondary.opacity(0.35), lineWidth: 1)
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityIdentifier("selector.\(etiqueta)")
    }
}

struct SelectorMaterial: View {
    @Binding var material: MaterialTuberia

    var body: some View {
        SelectorCatalogo(
            etiqueta: "Material",
            opciones: CatalogoMateriales.todos,
            seleccion: $material,
            nombre: \.nombre,
            detalle: descripcionMaterial
        )
    }
}

struct SelectorElastico: View {
    @Binding var material: MaterialElastico

    var body: some View {
        SelectorCatalogo(
            etiqueta: "Material de la tubería",
            opciones: CatalogoMaterialesElasticos.todos,
            seleccion: $material,
            nombre: \.nombre,
            detalle: descripcionMaterialElastico
        )
    }
}

/// Botones de opción en forma de cápsula (métodos de fricción y geometrías).
struct SelectorCapsulas<Opcion: Identifiable & Hashable>: View {
    @Environment(\.hidro) private var hidro
    let opciones: [Opcion]
    @Binding var seleccion: Opcion
    let etiqueta: (Opcion) -> String
    var repartirAncho: Bool = true

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(opciones) { opcion in
                    let activa = seleccion == opcion
                    Button {
                        withAnimation(.snappy) { seleccion = opcion }
                    } label: {
                        Text(etiqueta(opcion))
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .frame(minWidth: repartirAncho ? 92 : nil)
                            .background(Capsule().fill(activa ? hidro.primario : hidro.variante.opacity(0.9)))
                            .foregroundStyle(activa ? hidro.sobrePrimario : hidro.sobreFondo)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(activa ? .isSelected : [])
                    .accessibilityIdentifier("opcion.\(etiqueta(opcion))")
                }
            }
        }
        .sensoryFeedback(.selection, trigger: seleccion)
    }
}

struct SeccionTarjeta<Content: View>: View {
    @Environment(\.hidro) private var hidro
    var titulo: String
    var simbolo: String
    var descripcion: String?
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: simbolo)
                    .foregroundStyle(hidro.primario)
                Text(titulo)
                    .font(.title3.weight(.semibold))
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            if let descripcion {
                Text(descripcion)
                    .font(.footnote.monospaced())
                    .foregroundStyle(hidro.sobreVariante)
            }
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(hidro.variante.opacity(0.45), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct PanelResultados: View {
    @Environment(\.hidro) private var hidro
    private let salida: SalidaCalculo
    private let titulo: String
    private let desactualizado: Bool
    private let mensajeVacio: String
    @State private var copiado = false

    init(
        salida: SalidaCalculo,
        titulo: String,
        desactualizado: Bool = false,
        mensajeVacio: String = "Introduce los datos y pulsa calcular."
    ) {
        self.salida = salida
        self.titulo = titulo
        self.desactualizado = desactualizado
        self.mensajeVacio = mensajeVacio
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let error = salida.error {
                tarjetaMensaje(error, simbolo: "exclamationmark.octagon", fondo: hidro.errorContenedor, tinta: hidro.sobreError)
                    .accessibilityIdentifier("resultado.error")
            } else if salida.renglones.isEmpty {
                tarjetaMensaje(mensajeVacio, simbolo: "info.circle", fondo: hidro.variante, tinta: hidro.sobreVariante)
            } else {
                tarjetaValores
            }

            if salida.error == nil {
                ForEach(salida.advertencias, id: \.self) { aviso in
                    tarjetaMensaje(aviso, simbolo: "exclamationmark.triangle", fondo: hidro.contenedorTerciario, tinta: hidro.sobreContenedorTerciario)
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: salida)
        .sensoryFeedback(trigger: salida) { _, nueva in
            if nueva.error != nil { return .error }
            return nueva.hayResultado ? .success : nil
        }
        .onChange(of: salida) { copiado = false }
    }

    private var texto: String { salida.textoCompartible(titulo: titulo) }

    private var tarjetaValores: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Resultados")
                    .font(.title3.weight(.semibold))
                Spacer()
                Button {
                    UIPasteboard.general.string = texto
                    copiado = true
                } label: {
                    Image(systemName: copiado ? "checkmark" : "doc.on.doc")
                        .contentTransition(.symbolEffect(.replace))
                }
                .accessibilityLabel(copiado ? "Resultados copiados" : "Copiar resultados")
                ShareLink(item: texto) {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Compartir resultados")
            }
            .foregroundStyle(hidro.sobreContenedorPrimario)

            if desactualizado {
                Label("Cambiaste los datos. Pulsa calcular para actualizar.", systemImage: "arrow.clockwise")
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(hidro.sobreContenedorPrimario.opacity(0.12)))
                    .foregroundStyle(hidro.sobreContenedorPrimario)
                    .accessibilityIdentifier("resultado.desactualizado")
            }

            if let principal = salida.principal {
                VStack(alignment: .leading, spacing: 2) {
                    Text(principal.etiqueta)
                        .font(.subheadline)
                        .foregroundStyle(hidro.sobreContenedorPrimario.opacity(0.8))
                    Text(principal.valor)
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                        .foregroundStyle(hidro.sobreContenedorPrimario)
                        .accessibilityIdentifier("resultado.principal")
                        .contentTransition(.numericText())
                    if let nota = principal.nota {
                        Text(nota)
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(hidro.sobreContenedorPrimario.opacity(0.75))
                    }
                }
            }

            Divider().overlay(hidro.sobreContenedorPrimario.opacity(0.2))

            ForEach(salida.renglones.filter { !$0.destacado }) { renglon in
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(renglon.etiqueta)
                            .font(.subheadline)
                            .foregroundStyle(hidro.sobreContenedorPrimario.opacity(0.85))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(renglon.valor)
                            .font(.body.monospacedDigit().weight(renglon.tono == .normal ? .regular : .semibold))
                            .foregroundStyle(color(renglon.tono))
                            .multilineTextAlignment(.trailing)
                    }
                    if let nota = renglon.nota {
                        Text(nota)
                            .font(.caption)
                            .foregroundStyle(hidro.sobreContenedorPrimario.opacity(0.7))
                    }
                }
                .padding(.vertical, 1)
                .accessibilityElement(children: .combine)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(hidro.contenedorPrimario, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .opacity(desactualizado ? 0.7 : 1)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private func color(_ tono: Tono) -> Color {
        switch tono {
        case .normal: hidro.sobreContenedorPrimario
        case .subcritico: hidro.subcritico
        case .critico: hidro.critico
        case .supercritico: hidro.supercritico
        }
    }

    private func tarjetaMensaje(_ texto: String, simbolo: String, fondo: Color, tinta: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: simbolo)
            Text(texto)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(tinta)
        .padding(16)
        .background(fondo, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// Barra que reparte la carga H entre fricción, pérdidas locales y carga de velocidad.
struct RepartoCargaView: View {
    @Environment(\.hidro) private var hidro
    let segmentos: [SegmentoCarga]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Reparto de la carga H")
                .font(.headline)
            GeometryReader { geo in
                HStack(spacing: 2) {
                    ForEach(segmentos) { segmento in
                        Rectangle()
                            .fill(color(segmento.tipo))
                            .frame(width: max(0, geo.size.width - CGFloat(segmentos.count - 1) * 2) * segmento.fraccion)
                    }
                }
                .clipShape(Capsule())
            }
            .frame(height: 14)
            .accessibilityHidden(true)
            ForEach(segmentos) { segmento in
                HStack(spacing: 8) {
                    Circle()
                        .fill(color(segmento.tipo))
                        .frame(width: 10, height: 10)
                    Text(segmento.tipo.rawValue)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(Formato.conUnidad(segmento.metros, "m"))
                        .font(.subheadline.monospacedDigit())
                    Text("\(Formato.numero(segmento.fraccion * 100, decimales: 1)) %")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 52, alignment: .trailing)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(hidro.variante.opacity(0.45), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func color(_ tipo: SegmentoCarga.Tipo) -> Color {
        switch tipo {
        case .friccion: hidro.primario
        case .locales: hidro.acentoSecundario
        case .velocidad: hidro.acentoTerciario
        }
    }
}

struct BarraCalcular: View {
    @Environment(\.hidro) private var hidro
    var texto: String
    var habilitado: Bool
    var accion: () -> Void

    var body: some View {
        Button(action: accion) {
            Label(texto, systemImage: "function")
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.roundedRectangle(radius: 14))
        .tint(hidro.primario)
        .disabled(!habilitado)
        .accessibilityIdentifier("accion.calcular")
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .frame(maxWidth: 720)
        .frame(maxWidth: .infinity)
        .background(.bar)
    }
}

private func ocultarTeclado() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

/// Armazón de las pantallas de cálculo: barra superior, desplazamiento,
/// menú de acciones y botón de calcular anclado abajo.
struct PantallaCalculo<Content: View>: View {
    @Environment(\.hidro) private var hidro
    @Environment(\.colorScheme) private var scheme
    var titulo: String
    var subtitulo: String?
    var accion: String
    var accionHabilitada: Bool
    var onCalcular: () -> Void
    var onEjemplo: () -> Void
    var onLimpiar: () -> Void
    @ViewBuilder var content: Content

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    content
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(hidro.fondo.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                BarraCalcular(texto: accion, habilitado: accionHabilitada) {
                    ocultarTeclado()
                    onCalcular()
                    DispatchQueue.main.async {
                        withAnimation(.easeInOut) {
                            proxy.scrollTo(IdentificadorUI.resultados, anchor: .top)
                        }
                    }
                }
            }
        }
        .navigationTitle(titulo)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(hidro.contenedorPrimario, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(scheme == .dark ? .dark : .light, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 0) {
                    Text(titulo)
                        .font(.headline)
                        .lineLimit(1)
                    if let subtitulo, !subtitulo.isEmpty {
                        Text(subtitulo)
                            .font(.caption)
                            .lineLimit(1)
                            .contentTransition(.numericText())
                    }
                }
                .foregroundStyle(hidro.sobreContenedorPrimario)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Cargar ejemplo", systemImage: "wand.and.stars") {
                        withAnimation { onEjemplo() }
                    }
                    Button("Limpiar datos", systemImage: "eraser", role: .destructive) {
                        withAnimation { onLimpiar() }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Acciones")
                .accessibilityIdentifier("menu.acciones")
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Listo", action: ocultarTeclado)
            }
        }
    }
}
