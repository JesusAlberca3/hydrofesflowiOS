import Foundation

enum Parseo {
    /// Número finito escrito por el usuario, con punto o coma decimal.
    static func double(_ texto: String) -> Double? {
        let limpio = texto
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ",", with: ".")
        guard !limpio.isEmpty, let valor = Double(limpio), valor.isFinite else { return nil }
        return valor
    }
}

enum Sanear {
    /// Longitud máxima de un campo; evita magnitudes que desbordan Double al convertir unidades.
    static let longitudMaxima = 16

    /// Devuelve el texto aceptado o nil si la pulsación rompería el número.
    /// Acepta dígitos y un solo separador; la coma se convierte en punto.
    static func numero(_ entrada: String) -> String? {
        let texto = entrada.replacingOccurrences(of: ",", with: ".")
        guard texto.count <= longitudMaxima else { return nil }
        let coincide = texto.range(of: #"^\d*\.?\d*$"#, options: .regularExpression) != nil
        return coincide ? texto : nil
    }
}

/// Mensaje bajo el campo cuando lo escrito no sirve para calcular.
enum AvisoCampo {
    static let noNumerico = "Escribe un número válido."
    static let mayorQueCero = "Debe ser mayor que cero."
    static let noNegativo = "No puede ser negativo."

    static func positivo(_ texto: String) -> String? {
        if texto.trimmingCharacters(in: .whitespaces).isEmpty { return nil }
        guard let valor = Parseo.double(texto) else { return noNumerico }
        return valor > 0 ? nil : mayorQueCero
    }

    static func noNegativo(_ texto: String) -> String? {
        if texto.trimmingCharacters(in: .whitespaces).isEmpty { return nil }
        guard let valor = Parseo.double(texto) else { return noNumerico }
        return valor >= 0 ? nil : noNegativo
    }
}

struct EntradaLongitud: Equatable {
    var texto: String = ""
    var unidad: UnidadLongitud = .metro

    var valorMetros: Double? {
        guard let valor = Parseo.double(texto) else { return nil }
        let metros = unidad.aMetros(valor)
        return metros.isFinite ? metros : nil
    }

    var avisoPositivo: String? { AvisoCampo.positivo(texto) }
    var avisoNoNegativo: String? { AvisoCampo.noNegativo(texto) }
}

struct EntradaCaudal: Equatable {
    var texto: String = ""
    var unidad: UnidadCaudal = .litroSegundo

    var valorM3s: Double? {
        guard let valor = Parseo.double(texto) else { return nil }
        let m3s = unidad.aM3s(valor)
        return m3s.isFinite ? m3s : nil
    }

    var avisoPositivo: String? { AvisoCampo.positivo(texto) }
}
