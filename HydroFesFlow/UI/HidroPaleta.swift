import SwiftUI

struct HidroPaleta: Equatable {
    var primario: Color
    var sobrePrimario: Color
    var contenedorPrimario: Color
    var sobreContenedorPrimario: Color
    var contenedorSecundario: Color
    var sobreContenedorSecundario: Color
    var contenedorTerciario: Color
    var sobreContenedorTerciario: Color
    var fondo: Color
    var sobreFondo: Color
    var variante: Color
    var sobreVariante: Color
    var errorContenedor: Color
    var sobreError: Color
    var textoError: Color
    var acentoSecundario: Color
    var acentoTerciario: Color
    var subcritico: Color
    var critico: Color
    var supercritico: Color

    static let clara = HidroPaleta(
        primario: Color(red: 0 / 255, green: 73 / 255, blue: 125 / 255),
        sobrePrimario: .white,
        contenedorPrimario: Color(red: 207 / 255, green: 229 / 255, blue: 255 / 255),
        sobreContenedorPrimario: Color(red: 0 / 255, green: 29 / 255, blue: 52 / 255),
        contenedorSecundario: Color(red: 197 / 255, green: 231 / 255, blue: 255 / 255),
        sobreContenedorSecundario: Color(red: 0 / 255, green: 30 / 255, blue: 46 / 255),
        contenedorTerciario: Color(red: 156 / 255, green: 241 / 255, blue: 246 / 255),
        sobreContenedorTerciario: Color(red: 0 / 255, green: 32 / 255, blue: 34 / 255),
        fondo: Color(red: 247 / 255, green: 249 / 255, blue: 255 / 255),
        sobreFondo: Color(red: 25 / 255, green: 28 / 255, blue: 32 / 255),
        variante: Color(red: 221 / 255, green: 227 / 255, blue: 234 / 255),
        sobreVariante: Color(red: 65 / 255, green: 71 / 255, blue: 77 / 255),
        errorContenedor: Color(red: 255 / 255, green: 218 / 255, blue: 214 / 255),
        sobreError: Color(red: 65 / 255, green: 0 / 255, blue: 2 / 255),
        textoError: Color(red: 186 / 255, green: 26 / 255, blue: 26 / 255),
        acentoSecundario: Color(red: 0 / 255, green: 101 / 255, blue: 142 / 255),
        acentoTerciario: Color(red: 0 / 255, green: 150 / 255, blue: 136 / 255),
        subcritico: Color(red: 27 / 255, green: 108 / 255, blue: 58 / 255),
        critico: Color(red: 138 / 255, green: 83 / 255, blue: 0 / 255),
        supercritico: Color(red: 155 / 255, green: 34 / 255, blue: 38 / 255)
    )

    static let oscura = HidroPaleta(
        primario: Color(red: 155 / 255, green: 203 / 255, blue: 255 / 255),
        sobrePrimario: Color(red: 0 / 255, green: 51 / 255, blue: 85 / 255),
        contenedorPrimario: Color(red: 0 / 255, green: 74 / 255, blue: 120 / 255),
        sobreContenedorPrimario: Color(red: 207 / 255, green: 229 / 255, blue: 255 / 255),
        contenedorSecundario: Color(red: 0 / 255, green: 76 / 255, blue: 108 / 255),
        sobreContenedorSecundario: Color(red: 197 / 255, green: 231 / 255, blue: 255 / 255),
        contenedorTerciario: Color(red: 0 / 255, green: 79 / 255, blue: 83 / 255),
        sobreContenedorTerciario: Color(red: 156 / 255, green: 241 / 255, blue: 246 / 255),
        fondo: Color(red: 17 / 255, green: 20 / 255, blue: 24 / 255),
        sobreFondo: Color(red: 225 / 255, green: 226 / 255, blue: 232 / 255),
        variante: Color(red: 65 / 255, green: 71 / 255, blue: 77 / 255),
        sobreVariante: Color(red: 193 / 255, green: 199 / 255, blue: 206 / 255),
        errorContenedor: Color(red: 147 / 255, green: 0 / 255, blue: 10 / 255),
        sobreError: Color(red: 255 / 255, green: 218 / 255, blue: 214 / 255),
        textoError: Color(red: 255 / 255, green: 180 / 255, blue: 171 / 255),
        acentoSecundario: Color(red: 133 / 255, green: 207 / 255, blue: 255 / 255),
        acentoTerciario: Color(red: 128 / 255, green: 212 / 255, blue: 218 / 255),
        subcritico: Color(red: 125 / 255, green: 216 / 255, blue: 150 / 255),
        critico: Color(red: 255 / 255, green: 185 / 255, blue: 92 / 255),
        supercritico: Color(red: 255 / 255, green: 180 / 255, blue: 171 / 255)
    )

    static func de(_ scheme: ColorScheme) -> HidroPaleta {
        scheme == .dark ? .oscura : .clara
    }
}

private struct HidroKey: EnvironmentKey {
    static let defaultValue = HidroPaleta.clara
}

extension EnvironmentValues {
    var hidro: HidroPaleta {
        get { self[HidroKey.self] }
        set { self[HidroKey.self] = newValue }
    }
}
