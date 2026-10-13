import Observation

/// Datos que un módulo deja disponibles para otro durante la sesión.
@Observable
final class SesionHidraulica {
    /// ΣK armado en Pérdidas locales, para llevarlo a Caudal o Diámetro.
    var sumaKLocales: Double?
}
