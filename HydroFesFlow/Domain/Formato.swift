import Foundation

/// Formateo numérico con locale fijo en punto decimal, igual que la app Android.
enum Formato {
    private static let locale = Locale(identifier: "en_US_POSIX")

    static func numero(_ valor: Double, decimales: Int = 4) -> String {
        if valor.isNaN { return "—" }
        if valor.isInfinite { return "∞" }
        return String(format: "%.\(decimales)f", locale: locale, valor)
    }

    static func cientifico(_ valor: Double, decimales: Int = 3) -> String {
        if valor.isNaN { return "—" }
        if valor.isInfinite { return "∞" }
        return String(format: "%.\(decimales)e", locale: locale, valor)
    }

    /// Elige notación fija o científica según la magnitud del valor.
    static func auto(_ valor: Double, decimales: Int = 4) -> String {
        if valor.isNaN || valor.isInfinite { return numero(valor) }
        let magnitud = abs(valor)
        if magnitud != 0 && (magnitud < 1e-3 || magnitud >= 1e6) {
            return cientifico(valor)
        }
        return numero(valor, decimales: decimales)
    }

    static func conUnidad(_ valor: Double, _ unidad: String, decimales: Int = 4) -> String {
        "\(auto(valor, decimales: decimales)) \(unidad)"
    }
}
