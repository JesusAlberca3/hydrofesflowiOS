import Foundation

/// Salida de un cálculo: un valor válido o un motivo de fallo.
enum Resultado<T> {
    case exito(T, advertencias: [String])
    case error(String)

    var valor: T? {
        if case .exito(let valor, _) = self { return valor }
        return nil
    }

    var advertencias: [String] {
        if case .exito(_, let advertencias) = self { return advertencias }
        return []
    }

    var mensajeError: String? {
        if case .error(let mensaje) = self { return mensaje }
        return nil
    }

    var esError: Bool {
        if case .error = self { return true }
        return false
    }
}

enum Errores {
    static let datosIncompletos = "Completa todos los campos con valores numéricos válidos."
    static let diametroInvalido = "El diámetro debe ser mayor que cero."
    static let longitudInvalida = "La longitud debe ser mayor que cero."
    static let caudalInvalido = "El caudal debe ser mayor que cero."
    static let cargaInvalida = "La carga disponible debe ser mayor que cero."
    static let espesorInvalido = "El espesor de pared debe ser mayor que cero."
    static let coeficienteInvalido = "El coeficiente del material debe ser mayor que cero."
    static let tiranteInvalido = "El tirante debe ser mayor que cero."
    static let pendienteInvalida = "La pendiente debe ser mayor que cero."
    static let manningInvalido = "El coeficiente de Manning debe ser mayor que cero."
    static let sinConvergencia = "El método iterativo no convergió; revisa los datos de entrada."
    static let kNegativo = "El coeficiente de pérdidas locales no puede ser negativo."
    static let materialInvalido = "Selecciona un material de tubería válido."
    static let anchoInvalido = "El ancho de plantilla debe ser mayor que cero."
    static let taludInvalido = "El talud z debe ser mayor que cero."
    static let trapecioInvalido = "Revisa el ancho de plantilla (≥ 0) y el talud z (> 0)."
    static let tiranteCircular = "En sección circular el tirante debe cumplir 0 < y ≤ D."
    static let geometriaInvalida = "La geometría introducida no define una sección de flujo válida."
}
