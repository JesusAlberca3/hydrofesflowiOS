import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let paleta = HidroPaleta.de(scheme)
        NavigationStack {
            InicioView()
                .navigationDestination(for: Ruta.self) { ruta in
                    switch ruta {
                    case .conductos: MenuConductosView()
                    case .perdidas: MenuPerdidasView()
                    case .caudal: CaudalView()
                    case .diametro: DiametroView()
                    case .friccion: PerdidasFriccionView()
                    case .locales: PerdidasLocalesView()
                    case .celeridad: CeleridadView()
                    case .canales: CanalesView()
                    case .documentacion: DocumentacionView()
                    }
                }
        }
        .environment(\.hidro, paleta)
        .tint(paleta.primario)
    }
}

#Preview {
    ContentView()
}
