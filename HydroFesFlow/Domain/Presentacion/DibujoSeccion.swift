import Foundation

struct Punto: Equatable {
    let x: Double
    let y: Double
}

/// Contorno del canal y área mojada en metros, con el origen abajo a la izquierda.
struct PerfilSeccion: Equatable {
    let contorno: [Punto]
    let agua: [Punto]
    let ancho: Double
    let alto: Double
    /// Altura de la superficie libre.
    let tirante: Double
    /// Si el contorno se cierra (sección circular).
    let cerrado: Bool

    /// Bordo libre dibujado sobre el tirante en secciones abiertas.
    static let bordoLibre = 1.35
    private static let muestrasCirculo = 96

    static func de(_ datos: DatosCanal) -> PerfilSeccion? {
        let y = datos.tirante
        guard Validacion.positivo(y) else { return nil }

        switch datos.geometria {
        case .rectangular:
            let b = datos.anchoPlantilla
            guard Validacion.positivo(b) else { return nil }
            return trapecio(b: b, z: 0, y: y)
        case .triangular:
            guard Validacion.positivo(datos.talud) else { return nil }
            return trapecio(b: 0, z: datos.talud, y: y)
        case .trapezoidal:
            guard Validacion.noNegativo(datos.anchoPlantilla), Validacion.positivo(datos.talud) else { return nil }
            return trapecio(b: datos.anchoPlantilla, z: datos.talud, y: y)
        case .circular:
            let d = datos.diametro
            guard Validacion.positivo(d), y <= d else { return nil }
            return circulo(d: d, y: y)
        }
    }

    private static func trapecio(b: Double, z: Double, y: Double) -> PerfilSeccion? {
        let alto = y * bordoLibre
        let corrimiento = z * alto
        let ancho = b + 2 * corrimiento
        guard Validacion.positivo(ancho), ancho.isFinite, alto.isFinite else { return nil }
        let contorno = [
            Punto(x: 0, y: alto),
            Punto(x: corrimiento, y: 0),
            Punto(x: corrimiento + b, y: 0),
            Punto(x: ancho, y: alto),
        ]
        let agua = [
            Punto(x: corrimiento - z * y, y: y),
            Punto(x: corrimiento, y: 0),
            Punto(x: corrimiento + b, y: 0),
            Punto(x: corrimiento + b + z * y, y: y),
        ]
        return PerfilSeccion(contorno: contorno, agua: agua, ancho: ancho, alto: alto, tirante: y, cerrado: false)
    }

    private static func circulo(d: Double, y: Double) -> PerfilSeccion {
        let r = d / 2
        func punto(_ t: Double) -> Punto { Punto(x: r + r * cos(t), y: r + r * sin(t)) }

        let contorno = (0..<muestrasCirculo).map { i in
            punto(2 * Double.pi * Double(i) / Double(muestrasCirculo))
        }
        let phi = asin(min(1, max(-1, (y - r) / r)))
        let inicio = Double.pi - phi
        let barrido = Double.pi + 2 * phi
        let agua = (0...muestrasCirculo).map { i in
            punto(inicio + barrido * Double(i) / Double(muestrasCirculo))
        }
        return PerfilSeccion(contorno: contorno, agua: agua, ancho: d, alto: d, tirante: y, cerrado: true)
    }
}
