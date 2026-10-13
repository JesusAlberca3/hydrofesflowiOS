import Foundation

/// Constantes físicas del agua a 20 °C, en unidades del SI.
/// Mismos valores que `domain/Constantes.kt` de CalculoTuberias.
enum Constantes {
    /// Aceleración de la gravedad [m/s²].
    static let gravedad = 9.81

    /// Densidad del agua a 20 °C [kg/m³].
    static let densidadAgua = 998.0

    /// Viscosidad cinemática del agua a 20 °C [m²/s].
    static let viscosidadCinematica = 1.004e-6

    /// Módulo de compresibilidad volumétrica del agua a 20 °C [Pa].
    static let moduloVolumetricoAgua = 2.19e9
}
