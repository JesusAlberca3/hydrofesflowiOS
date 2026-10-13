import SwiftUI

struct CanalesView: View {
    @Environment(\.hidro) private var hidro
    @State private var geometria = GeometriaCanal.rectangular
    @State private var pendiente = ""
    @State private var manning = ""
    @State private var tirante = EntradaLongitud()
    @State private var ancho = EntradaLongitud()
    @State private var talud = ""
    @State private var diametro = EntradaLongitud()
    @State private var renglones: [Renglon] = []
    @State private var error: String?
    @State private var advertencias: [String] = []

    private var datosCompletos: Bool {
        let comunes = Parseo.double(pendiente) != nil && Parseo.double(manning) != nil && tirante.valorMetros != nil
        guard comunes else { return false }
        switch geometria {
        case .rectangular: return ancho.valorMetros != nil
        case .triangular: return Parseo.double(talud) != nil
        case .trapezoidal: return ancho.valorMetros != nil && Parseo.double(talud) != nil
        case .circular: return diametro.valorMetros != nil
        }
    }

    var body: some View {
        PantallaCalculo(
            titulo: "Canales",
            subtitulo: "Flujo uniforme · \(geometria.etiqueta)",
            accion: "Calcular",
            accionHabilitada: datosCompletos,
            onCalcular: calcular
        ) {
            SeccionTarjeta(titulo: "Geometría de la sección", simbolo: "square.split.2x1") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(GeometriaCanal.allCases) { opcion in
                            Button(opcion.etiqueta) {
                                geometria = opcion
                                renglones = []
                                error = nil
                                advertencias = []
                            }
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(geometria == opcion ? hidro.primario : hidro.variante.opacity(0.9)))
                            .foregroundStyle(geometria == opcion ? hidro.sobrePrimario : hidro.sobreFondo)
                            .buttonStyle(.plain)
                        }
                    }
                }
                switch geometria {
                case .rectangular:
                    CampoLongitud(etiqueta: "Ancho de plantilla b", entrada: $ancho)
                case .triangular:
                    CampoNumerico(etiqueta: "Talud z (H:V)", texto: $talud)
                case .trapezoidal:
                    CampoLongitud(etiqueta: "Ancho de plantilla b", entrada: $ancho)
                    CampoNumerico(etiqueta: "Talud z (H:V)", texto: $talud)
                case .circular:
                    CampoLongitud(etiqueta: "Diámetro D", entrada: $diametro)
                }
                CampoLongitud(etiqueta: "Tirante y", entrada: $tirante)
            }
            SeccionTarjeta(
                titulo: "Resistencia y pendiente",
                simbolo: "slider.horizontal.3",
                descripcion: "Q = (1/n) · A · R^(2/3) · √S"
            ) {
                CampoNumerico(etiqueta: "Pendiente hidráulica S", texto: $pendiente, sufijo: "m/m")
                CampoNumerico(
                    etiqueta: "Coeficiente de Manning n",
                    texto: $manning,
                    ayuda: "Tierra 0.025 · Concreto 0.014 · PVC 0.009"
                )
            }
            PanelResultados(renglones: renglones, error: error, advertencias: advertencias)
        }
    }

    private func calcular() {
        guard let s = Parseo.double(pendiente), let n = Parseo.double(manning), let y = tirante.valorMetros else {
            renglones = []
            error = Errores.datosIncompletos
            advertencias = []
            return
        }
        let datos = DatosCanal(
            geometria: geometria,
            pendiente: s,
            manning: n,
            tirante: y,
            anchoPlantilla: ancho.valorMetros ?? 0,
            talud: Parseo.double(talud) ?? 0,
            diametro: diametro.valorMetros ?? 0
        )
        switch Canales.calcular(datos) {
        case .error(let mensaje):
            renglones = []
            error = mensaje
            advertencias = []
        case .exito(let valor, let avisos):
            error = nil
            advertencias = avisos
            var filas = [
                Renglon(
                    etiqueta: "Caudal Q",
                    valor: Formato.conUnidad(valor.caudal, "m³/s"),
                    destacado: true,
                    nota: "\(Formato.numero(UnidadCaudal.litroSegundo.desdeM3s(valor.caudal), decimales: 1)) L/s"
                ),
                Renglon(etiqueta: "Velocidad media V", valor: Formato.conUnidad(valor.velocidad, "m/s")),
                Renglon(etiqueta: "Área hidráulica A", valor: Formato.conUnidad(valor.area, "m²")),
                Renglon(etiqueta: "Perímetro mojado P", valor: Formato.conUnidad(valor.perimetroMojado, "m")),
                Renglon(etiqueta: "Radio hidráulico R", valor: Formato.conUnidad(valor.radioHidraulico, "m")),
                Renglon(etiqueta: "Espejo de agua T", valor: Formato.conUnidad(valor.espejoAgua, "m")),
            ]
            if let profundidad = valor.profundidadHidraulica {
                filas.append(Renglon(etiqueta: "Profundidad hidráulica A/T", valor: Formato.conUnidad(profundidad, "m")))
            }
            filas.append(Renglon(etiqueta: "Energía específica E", valor: Formato.conUnidad(valor.energiaEspecifica, "m")))
            if let froude = valor.numeroFroude {
                filas.append(Renglon(etiqueta: "Número de Froude Fr", valor: Formato.numero(froude, decimales: 4)))
                if let regimen = valor.regimen {
                    let color: Color = switch regimen {
                    case .subcritico: hidro.subcritico
                    case .critico: hidro.critico
                    case .supercritico: hidro.supercritico
                    }
                    filas.append(Renglon(etiqueta: "Régimen", valor: regimen.etiqueta, nota: regimen.nota, acento: color))
                }
            } else {
                filas.append(Renglon(etiqueta: "Número de Froude Fr", valor: "no definido", nota: "T → 0, sección llena"))
            }
            if let yc = valor.tiranteCritico {
                filas.append(Renglon(
                    etiqueta: "Tirante crítico y_c",
                    valor: Formato.conUnidad(yc, "m"),
                    nota: "Resuelto por bisección sobre Q²T/(gA³) = 1"
                ))
            }
            if let llenado = valor.relacionLlenado {
                filas.append(Renglon(etiqueta: "Relación de llenado y/D", valor: Formato.numero(llenado, decimales: 3)))
            }
            renglones = filas
        }
    }
}

private struct SeccionDoc: Identifiable {
    let titulo: String
    let parrafos: [String]
    let abiertaAlInicio: Bool
    var id: String { titulo }
}

struct DocumentacionView: View {
    @Environment(\.hidro) private var hidro
    @State private var abiertas: Set<String> = ["Cómo introducir los datos"]

    private let secciones: [SeccionDoc] = [
        SeccionDoc(
            titulo: "Cómo introducir los datos",
            parrafos: [
                "Longitud y caudal llevan su propia unidad. Debajo del campo aparece el valor ya convertido a metros o a m³/s, que es el que entra al cálculo.",
                "El separador decimal puede ser punto o coma. El botón de calcular se activa cuando todos los campos obligatorios tienen un número.",
                "El material trae juntos la rugosidad, el coeficiente C de Hazen-Williams y el n de Manning. PVC queda seleccionado al abrir la pantalla.",
            ],
            abiertaAlInicio: true
        ),
        SeccionDoc(
            titulo: "Caudal y diámetro",
            parrafos: [
                "Caudal: con un diámetro y una carga disponible H, obtiene el gasto que circula.",
                "Diámetro: con un gasto y la misma carga, obtiene el diámetro necesario.",
                "Los dos usan H = (1 + f·L/D + ΣK) · V²/2g. Por eso, si pasas el caudal de un módulo al otro, con el resto de datos iguales, recuperas el diámetro de partida.",
                "ΣK resume las pérdidas en accesorios. Si la tubería no tiene piezas especiales, déjalo en 0. Puedes armarlo en Pérdidas locales.",
                "El resultado reparte H entre fricción, pérdidas locales y carga de velocidad. Esas tres cifras suman la carga que introdujiste.",
            ],
            abiertaAlInicio: false
        ),
        SeccionDoc(
            titulo: "Pérdidas por fricción",
            parrafos: [
                "Darcy-Weisbach usa la rugosidad del material y cubre régimen laminar y turbulento. Es la referencia general.",
                "Hazen-Williams usa el coeficiente C. Está pensado para agua, diámetros de al menos 50 mm y velocidades entre 0.6 y 3 m/s. Fuera de ese intervalo el cálculo sigue y aparece una advertencia.",
                "Chézy-Manning usa el coeficiente n, con el tubo trabajando lleno.",
                "La tarjeta de contraste resuelve los tres métodos con los mismos datos y muestra cuánto se apartan Hazen-Williams y Manning de Darcy-Weisbach.",
            ],
            abiertaAlInicio: false
        ),
        SeccionDoc(
            titulo: "Pérdidas locales",
            parrafos: [
                "Cada accesorio tiene un coeficiente K. La pérdida es h_L = ΣK · V²/2g.",
                "Suma las piezas con el botón de cada fila. El ΣK del subtítulo se actualiza al momento y es el valor que puedes llevar a Caudal o a Diámetro.",
                "Sin ninguna pieza seleccionada la pérdida es cero y la app lo indica.",
            ],
            abiertaAlInicio: false
        ),
        SeccionDoc(
            titulo: "Celeridad y golpe de ariete",
            parrafos: [
                "Calcula la velocidad de la onda de presión, a = 1 / √(ρ · (1/K + D/(E·e))). El material fija el módulo de Young.",
                "La longitud de la conducción es opcional y sirve para el tiempo crítico 2L/a: un cierre más lento que ese tiempo es una maniobra lenta.",
                "La velocidad de régimen es opcional y sirve para la sobrepresión de Joukowsky, Δh = a·ΔV/g, correspondiente a un cierre instantáneo.",
            ],
            abiertaAlInicio: false
        ),
        SeccionDoc(
            titulo: "Canales",
            parrafos: [
                "Flujo uniforme de Manning: Q = (1/n) · A · R^(2/3) · √S. La pendiente S va en m/m.",
                "Rectangular pide el ancho de plantilla. Triangular, el talud z (horizontal entre vertical). Trapezoidal, los dos. Circular, el diámetro, con un tirante menor o igual a ese diámetro.",
                "El número de Froude usa la profundidad hidráulica A/T. Menor que 1 es subcrítico y el control está aguas abajo; mayor que 1 es supercrítico y el control está aguas arriba.",
                "Con la sección circular llena el espejo de agua se anula y el Froude se reporta como no definido. Por encima de y/D ≈ 0.94 el gasto disminuye al subir el tirante.",
                "El tirante crítico se obtiene por bisección y sirve para comparar el tirante de trabajo con el estado de energía mínima.",
            ],
            abiertaAlInicio: false
        ),
        SeccionDoc(
            titulo: "Cómo leer el resultado",
            parrafos: [
                "La tarjeta gris indica que todavía no hay cálculo. La roja describe qué dato falta o qué valor no es válido.",
                "La tarjeta azul es el resultado. La magnitud principal va en tamaño grande y el icono de copiar la pasa al portapapeles.",
                "La tarjeta verde es una advertencia: el número es válido y hay una condición del método que conviene revisar.",
            ],
            abiertaAlInicio: false
        ),
        SeccionDoc(
            titulo: "Alcance",
            parrafos: [
                "Todo el cálculo supone agua a 20 °C. Para otro fluido o otra temperatura cambian la viscosidad, la densidad y el módulo de compresibilidad.",
                "Los coeficientes de los materiales son los de las tablas de este proyecto. El n del hierro dúctil (0.022) y el del acero remachado (0.010) se apartan de los valores más citados en los manuales.",
            ],
            abiertaAlInicio: false
        ),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("HidroFES Flow 2.0")
                    .font(.title2.weight(.semibold))
                Text("Calculadora de conductos a presión y canales a superficie libre. Proyecto académico de la UNAM FES Aragón.")
                    .font(.body)
                ForEach(secciones) { seccion in
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { abiertas.contains(seccion.titulo) },
                            set: { abierta in
                                if abierta { abiertas.insert(seccion.titulo) } else { abiertas.remove(seccion.titulo) }
                            }
                        )
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(seccion.parrafos, id: \.self) { parrafo in
                                Text(parrafo)
                                    .font(.body)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(.top, 8)
                    } label: {
                        Text(seccion.titulo)
                            .font(.headline)
                            .foregroundStyle(hidro.sobreFondo)
                    }
                    .padding(16)
                    .background(hidro.variante.opacity(0.45), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                Text("Los cálculos se hacen en el SI. Agua a 20 °C:  g = 9.81 m/s²,  ρ = 998 kg/m³,  ν = 1.004×10⁻⁶ m²/s,  K = 2.19×10⁹ Pa.")
                    .font(.footnote)
                    .foregroundStyle(hidro.sobreVariante)
                    .padding(.bottom, 16)
            }
            .padding(16)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .background(hidro.fondo.ignoresSafeArea())
        .navigationTitle("Documentación")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(hidro.contenedorPrimario, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}
