import SwiftUI
import UIKit

enum Parseo {
    static func double(_ texto: String) -> Double? {
        let limpio = texto.replacingOccurrences(of: ",", with: ".")
        if limpio.isEmpty { return nil }
        return Double(limpio)
    }
}

enum Sanear {
    /// Acepta dígitos y un solo punto. La coma se convierte en punto.
    static func numero(_ entrada: String) -> String? {
        let texto = entrada.replacingOccurrences(of: ",", with: ".")
        let coincide = texto.range(of: #"^\d*\.?\d*$"#, options: .regularExpression) != nil
        return coincide ? texto : nil
    }
}

struct EntradaLongitud: Equatable {
    var texto: String = ""
    var unidad: UnidadLongitud = .metro

    var valorMetros: Double? {
        guard let valor = Parseo.double(texto) else { return nil }
        return unidad.aMetros(valor)
    }
}

struct EntradaCaudal: Equatable {
    var texto: String = ""
    var unidad: UnidadCaudal = .litroSegundo

    var valorM3s: Double? {
        guard let valor = Parseo.double(texto) else { return nil }
        return unidad.aM3s(valor)
    }
}

struct Renglon: Identifiable, Equatable {
    let etiqueta: String
    let valor: String
    var destacado: Bool = false
    var nota: String?
    var acento: Color?

    var id: String { etiqueta }
}

struct CampoNumerico: View {
    var etiqueta: String
    @Binding var texto: String
    var sufijo: String?
    var ayuda: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(etiqueta)
                .font(.subheadline.weight(.medium))
            HStack {
                TextField(etiqueta, text: Binding(
                    get: { texto },
                    set: { nuevo in
                        if let limpio = Sanear.numero(nuevo) { texto = limpio }
                    }
                ))
                .keyboardType(.decimalPad)
                .textFieldStyle(.plain)
                if let sufijo {
                    Text(sufijo)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.secondary.opacity(0.35), lineWidth: 1)
            )
            if let ayuda {
                Text(ayuda)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct CampoLongitud: View {
    var etiqueta: String
    @Binding var entrada: EntradaLongitud

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(etiqueta)
                .font(.subheadline.weight(.medium))
            HStack(spacing: 8) {
                TextField(etiqueta, text: Binding(
                    get: { entrada.texto },
                    set: { nuevo in
                        if let limpio = Sanear.numero(nuevo) { entrada.texto = limpio }
                    }
                ))
                .keyboardType(.decimalPad)
                .textFieldStyle(.plain)
                Menu {
                    ForEach(UnidadLongitud.allCases) { unidad in
                        Button(unidad.etiqueta) { entrada.unidad = unidad }
                    }
                } label: {
                    Text(entrada.unidad.etiqueta)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.secondary.opacity(0.15)))
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.secondary.opacity(0.35), lineWidth: 1)
            )
            if let metros = entrada.valorMetros {
                Text("= \(String(format: "%.6g", locale: Locale(identifier: "en_US_POSIX"), metros)) m")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct CampoCaudal: View {
    var etiqueta: String
    @Binding var entrada: EntradaCaudal

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(etiqueta)
                .font(.subheadline.weight(.medium))
            HStack(spacing: 8) {
                TextField(etiqueta, text: Binding(
                    get: { entrada.texto },
                    set: { nuevo in
                        if let limpio = Sanear.numero(nuevo) { entrada.texto = limpio }
                    }
                ))
                .keyboardType(.decimalPad)
                .textFieldStyle(.plain)
                Menu {
                    ForEach(UnidadCaudal.allCases) { unidad in
                        Button(unidad.etiqueta) { entrada.unidad = unidad }
                    }
                } label: {
                    Text(entrada.unidad.etiqueta)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.secondary.opacity(0.15)))
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.secondary.opacity(0.35), lineWidth: 1)
            )
            if let caudal = entrada.valorM3s {
                Text("= \(String(format: "%.6g", locale: Locale(identifier: "en_US_POSIX"), caudal)) m³/s")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct SelectorMaterial: View {
    @Binding var material: MaterialTuberia

    var body: some View {
        Menu {
            ForEach(CatalogoMateriales.todos) { opcion in
                Button(opcion.nombre) { material = opcion }
            }
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text("Material")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(material.nombre)
                            .foregroundStyle(.primary)
                        Text(descripcionMaterial(material))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.secondary.opacity(0.35), lineWidth: 1)
            )
        }
    }
}

struct SelectorElastico: View {
    @Binding var material: MaterialElastico

    var body: some View {
        Menu {
            ForEach(CatalogoMaterialesElasticos.todos) { opcion in
                Button(opcion.nombre) { material = opcion }
            }
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text("Material de la tubería")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(material.nombre)
                            .foregroundStyle(.primary)
                        Text(descripcionMaterialElastico(material))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.secondary.opacity(0.35), lineWidth: 1)
            )
        }
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
            if let descripcion {
                Text(descripcion)
                    .font(.footnote)
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
    var renglones: [Renglon]
    var error: String?
    var advertencias: [String] = []
    var mensajeVacio: String = "Introduce los datos y pulsa calcular."
    @State private var copiado = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let error {
                tarjetaMensaje(error, simbolo: "exclamationmark.circle", fondo: hidro.errorContenedor, tinta: hidro.sobreError)
            } else if renglones.isEmpty {
                tarjetaMensaje(mensajeVacio, simbolo: "info.circle", fondo: hidro.variante, tinta: hidro.sobreVariante)
            } else {
                tarjetaValores
            }

            if error == nil {
                ForEach(advertencias, id: \.self) { aviso in
                    tarjetaMensaje(aviso, simbolo: "exclamationmark.triangle", fondo: hidro.contenedorTerciario, tinta: hidro.sobreContenedorTerciario)
                }
            }
        }
    }

    private var tarjetaValores: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Resultados")
                    .font(.title3.weight(.semibold))
                Spacer()
                Button {
                    UIPasteboard.general.string = renglones
                        .map { "\($0.etiqueta): \($0.valor)" }
                        .joined(separator: "\n")
                    copiado = true
                } label: {
                    Image(systemName: copiado ? "checkmark" : "doc.on.doc")
                }
                .accessibilityLabel("Copiar resultados")
            }
            .foregroundStyle(hidro.sobreContenedorPrimario)
            Divider().overlay(hidro.sobreContenedorPrimario.opacity(0.2))
            ForEach(renglones) { renglon in
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(renglon.etiqueta)
                            .font(.subheadline)
                            .foregroundStyle(hidro.sobreContenedorPrimario.opacity(0.85))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(renglon.valor)
                            .font(renglon.destacado ? .title2.weight(.semibold) : .body)
                            .foregroundStyle(renglon.acento ?? hidro.sobreContenedorPrimario)
                            .multilineTextAlignment(.trailing)
                    }
                    if let nota = renglon.nota {
                        Text(nota)
                            .font(.caption)
                            .foregroundStyle(hidro.sobreContenedorPrimario.opacity(0.7))
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(hidro.contenedorPrimario, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
        .tint(hidro.primario)
        .disabled(!habilitado)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(hidro.fondo)
    }
}

struct PantallaCalculo<Content: View>: View {
    @Environment(\.hidro) private var hidro
    @Environment(\.colorScheme) private var scheme
    var titulo: String
    var subtitulo: String?
    var accion: String?
    var accionHabilitada: Bool = false
    var onCalcular: (() -> Void)?
    @ViewBuilder var content: Content

    var body: some View {
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
                    }
                }
                .foregroundStyle(hidro.sobreContenedorPrimario)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Listo") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let accion, let onCalcular {
                BarraCalcular(texto: accion, habilitado: accionHabilitada, accion: onCalcular)
            }
        }
    }
}
