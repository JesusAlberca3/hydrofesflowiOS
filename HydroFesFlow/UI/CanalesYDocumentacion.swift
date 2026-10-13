import SwiftUI

/// Dibujo de la sección transversal con el tirante introducido.
struct SeccionCanalView: View {
    @Environment(\.hidro) private var hidro
    let perfil: PerfilSeccion?

    var body: some View {
        ZStack {
            if let perfil {
                Canvas { contexto, tamano in
                    let margen: CGFloat = 12
                    let escala = min(
                        (tamano.width - 2 * margen) / perfil.ancho,
                        (tamano.height - 2 * margen) / perfil.alto
                    )
                    let dx = (tamano.width - perfil.ancho * escala) / 2
                    let dy = (tamano.height - perfil.alto * escala) / 2
                    func aPantalla(_ p: Punto) -> CGPoint {
                        CGPoint(x: dx + p.x * escala, y: tamano.height - dy - p.y * escala)
                    }

                    var agua = Path()
                    agua.addLines(perfil.agua.map(aPantalla))
                    agua.closeSubpath()
                    contexto.fill(agua, with: .color(hidro.acentoSecundario.opacity(0.45)))

                    if let primero = perfil.agua.first, let ultimo = perfil.agua.last {
                        var superficie = Path()
                        superficie.move(to: aPantalla(primero))
                        superficie.addLine(to: aPantalla(ultimo))
                        contexto.stroke(superficie, with: .color(hidro.acentoSecundario), lineWidth: 2)
                    }

                    var contorno = Path()
                    contorno.addLines(perfil.contorno.map(aPantalla))
                    if perfil.cerrado { contorno.closeSubpath() }
                    contexto.stroke(contorno, with: .color(hidro.sobreFondo), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                }
                .accessibilityLabel("Sección con tirante de \(Formato.numero(perfil.tirante, decimales: 3)) m")
            } else {
                VStack(spacing: 6) {
                    Image(systemName: "water.waves")
                        .font(.title2)
                    Text("Completa la geometría para ver la sección")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150)
        .background(hidro.fondo.opacity(0.6), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .animation(.easeInOut(duration: 0.2), value: perfil)
    }
}

struct CanalesView: View {
    @State private var form = FormularioCanal()
    @State private var calculado: FormularioCanal?
    @State private var salida = SalidaCalculo.vacia

    var body: some View {
        PantallaCalculo(
            titulo: "Canales",
            subtitulo: "Flujo uniforme · \(form.geometria.etiqueta)",
            accion: "Calcular",
            accionHabilitada: form.datosCompletos,
            onCalcular: calcular,
            onEjemplo: { form = .ejemplo; calcular() },
            onLimpiar: { form = FormularioCanal(); calculado = nil; salida = .vacia }
        ) {
            SeccionTarjeta(titulo: "Geometría de la sección", simbolo: "square.split.2x1") {
                SelectorCapsulas(opciones: GeometriaCanal.allCases, seleccion: $form.geometria, etiqueta: \.etiqueta, repartirAncho: false)
                SeccionCanalView(perfil: form.datos.flatMap(PerfilSeccion.de))
                switch form.geometria {
                case .rectangular:
                    CampoLongitud(etiqueta: "Ancho de plantilla b", entrada: $form.ancho, aviso: form.avisoAncho)
                case .triangular:
                    CampoNumerico(etiqueta: "Talud z (H:V)", texto: $form.talud, aviso: form.avisoTalud)
                case .trapezoidal:
                    CampoLongitud(etiqueta: "Ancho de plantilla b", entrada: $form.ancho, aviso: form.avisoAncho)
                    CampoNumerico(etiqueta: "Talud z (H:V)", texto: $form.talud, aviso: form.avisoTalud)
                case .circular:
                    CampoLongitud(etiqueta: "Diámetro D", entrada: $form.diametro)
                }
                CampoLongitud(etiqueta: "Tirante y", entrada: $form.tirante, aviso: form.avisoTirante)
            }
            SeccionTarjeta(
                titulo: "Resistencia y pendiente",
                simbolo: "slider.horizontal.3",
                descripcion: "Q = (1/n) · A · R^(2/3) · √S"
            ) {
                CampoNumerico(etiqueta: "Pendiente hidráulica S", texto: $form.pendiente, sufijo: "m/m", aviso: form.avisoPendiente)
                CampoNumerico(
                    etiqueta: "Coeficiente de Manning n",
                    texto: $form.manning,
                    ayuda: "Tierra 0.025 · Concreto 0.014 · PVC 0.009",
                    aviso: form.avisoManning
                )
            }
            PanelResultados(salida: salida, titulo: "Canales", desactualizado: calculado != nil && calculado != form)
                .id(IdentificadorUI.resultados)
        }
        .onChange(of: form.geometria) {
            calculado = nil
            salida = .vacia
        }
    }

    private func calcular() {
        salida = form.calcular()
        calculado = form
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
                "Si un valor no sirve (cero, negativo o vacío a medias), el campo se marca en rojo y explica por qué.",
                "El menú ⋯ de cada pantalla carga un ejemplo resuelto o limpia todos los datos.",
            ],
            abiertaAlInicio: true
        ),
        SeccionDoc(
            titulo: "Caudal y diámetro",
            parrafos: [
                "Caudal: con un diámetro y una carga disponible H, obtiene el gasto que circula.",
                "Diámetro: con un gasto y la misma carga, obtiene el diámetro necesario.",
                "Los dos usan H = (1 + f·L/D + ΣK) · V²/2g. Por eso, si pasas el caudal de un módulo al otro, con el resto de datos iguales, recuperas el diámetro de partida.",
                "ΣK resume las pérdidas en accesorios. Si la tubería no tiene piezas especiales, déjalo en 0. Puedes armarlo en Pérdidas locales y traerlo con el botón que aparece bajo el campo.",
                "El resultado reparte H entre fricción, pérdidas locales y carga de velocidad. Esas tres cifras suman la carga que introdujiste; la barra de reparto lo muestra en porcentaje.",
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
                "La tarjeta azul es el resultado. La magnitud principal va en tamaño grande; los iconos de copiar y compartir envían todas las líneas.",
                "Si cambias un dato después de calcular, la tarjeta se atenúa y avisa que hay que volver a calcular.",
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
