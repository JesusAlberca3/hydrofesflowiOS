import SwiftUI

enum Ruta: Hashable {
    case conductos
    case perdidas
    case caudal
    case diametro
    case friccion
    case locales
    case celeridad
    case canales
    case documentacion
}

struct InicioView: View {
    @Environment(\.hidro) private var hidro

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("HidroFES Flow")
                        .font(.title.weight(.semibold))
                    Text("Cálculo de conductos a presión y canales a superficie libre")
                        .font(.body)
                }
                .foregroundStyle(hidro.sobreContenedorSecundario)
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(hidro.contenedorSecundario, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                NavigationLink(value: Ruta.conductos) {
                    tarjetaAcceso(
                        titulo: "Conductos a presión",
                        descripcion: "Caudal, diámetro, pérdidas de carga y golpe de ariete",
                        simbolo: "drop"
                    )
                }
                .buttonStyle(.plain)

                NavigationLink(value: Ruta.canales) {
                    tarjetaAcceso(
                        titulo: "Canales",
                        descripcion: "Flujo uniforme por Manning en cuatro geometrías",
                        simbolo: "water.waves"
                    )
                }
                .buttonStyle(.plain)

                Image("Cintillo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .accessibilityLabel("UNAM FES Aragón")
            }
            .padding(16)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .background(hidro.fondo.ignoresSafeArea())
        .navigationTitle("Calculadora Hidráulica")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: Ruta.documentacion) {
                    Image(systemName: "info.circle")
                }
                .accessibilityLabel("Documentación")
            }
        }
        .toolbarBackground(hidro.contenedorPrimario, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private func tarjetaAcceso(titulo: String, descripcion: String, simbolo: String) -> some View {
        HStack(spacing: 20) {
            Image(systemName: simbolo)
                .font(.system(size: 36))
                .foregroundStyle(hidro.primario)
                .frame(width: 48)
            VStack(alignment: .leading, spacing: 4) {
                Text(titulo)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(hidro.sobreFondo)
                Text(descripcion)
                    .font(.subheadline)
                    .foregroundStyle(hidro.sobreVariante)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
        .background(hidro.variante.opacity(0.55), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct MenuConductosView: View {
    var body: some View {
        ListaOpciones(opciones: [
            OpcionMenu(
                titulo: "Caudal",
                descripcion: "Gasto que circula por un diámetro conocido bajo una carga disponible",
                simbolo: "water.waves",
                ruta: .caudal
            ),
            OpcionMenu(
                titulo: "Diámetro",
                descripcion: "Diámetro necesario para conducir un gasto por gravedad",
                simbolo: "ruler",
                ruta: .diametro
            ),
            OpcionMenu(
                titulo: "Pérdidas de carga",
                descripcion: "Por fricción (Darcy, Hazen-Williams, Manning) y por accesorios",
                simbolo: "chart.line.downtrend.xyaxis",
                ruta: .perdidas
            ),
            OpcionMenu(
                titulo: "Celeridad",
                descripcion: "Velocidad de la onda de presión y golpe de ariete",
                simbolo: "bolt",
                ruta: .celeridad
            ),
        ])
        .navigationTitle("Conductos a presión")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MenuPerdidasView: View {
    var body: some View {
        ListaOpciones(opciones: [
            OpcionMenu(
                titulo: "Por fricción",
                descripcion: "Pérdidas primarias a lo largo de la conducción",
                simbolo: "chart.line.downtrend.xyaxis",
                ruta: .friccion
            ),
            OpcionMenu(
                titulo: "Locales o menores",
                descripcion: "Pérdidas secundarias por válvulas, codos y piezas especiales",
                simbolo: "function",
                ruta: .locales
            ),
        ])
        .navigationTitle("Pérdidas de carga")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct OpcionMenu: Identifiable {
    let titulo: String
    let descripcion: String
    let simbolo: String
    let ruta: Ruta
    var id: String { titulo }
}

struct ListaOpciones: View {
    @Environment(\.hidro) private var hidro
    var opciones: [OpcionMenu]

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(opciones) { opcion in
                    NavigationLink(value: opcion.ruta) {
                        HStack(spacing: 16) {
                            Image(systemName: opcion.simbolo)
                                .font(.title2)
                                .foregroundStyle(hidro.sobreContenedorSecundario)
                                .frame(width: 36)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(opcion.titulo)
                                    .font(.title3.weight(.semibold))
                                Text(opcion.descripcion)
                                    .font(.footnote)
                                    .multilineTextAlignment(.leading)
                            }
                            .foregroundStyle(hidro.sobreContenedorSecundario)
                            Spacer(minLength: 0)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(hidro.contenedorSecundario, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .background(hidro.fondo.ignoresSafeArea())
        .toolbarBackground(hidro.contenedorPrimario, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}
