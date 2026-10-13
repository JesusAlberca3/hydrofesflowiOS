# HidroFES Flow para iOS

Calculadora hidráulica de conductos a presión y canales. Es la versión en SwiftUI de [CalculoTuberias](https://github.com/JesusAlberca3/CalculoTuberias) (Android) y usa las mismas fórmulas, constantes y catálogos. Proyecto académico de la UNAM FES Aragón.

## Estructura

| Carpeta | Contenido |
|---|---|
| `HydroFesFlow/Domain` | Motor de cálculo. Solo depende de Foundation. |
| `HydroFesFlow/Domain/Presentacion` | Formularios, validación de campos y renglones de resultado. |
| `HydroFesFlow/UI` | Vistas SwiftUI. |
| `HydroFesFlowTests` | Pruebas unitarias (Swift Testing). |
| `HydroFesFlowUITests` | Pruebas de interfaz (XCUITest). |

La app se abre con `HydroFesFlow.xcodeproj`. `Package.swift` existe solo para correr las pruebas del motor sin simulador.

## Pruebas

En Xcode: esquema **HydroFesFlow**, `⌘U`.

Desde la terminal:

```bash
# Motor y presentación, en macOS o Linux
swift test

# App completa en el simulador
xcodebuild test \
  -project HydroFesFlow.xcodeproj \
  -scheme HydroFesFlow \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

Las pruebas cubren:

- Los ejemplos de comprobación de `docs/CALCULOS.md` del proyecto Android (214.185 L/s, D = 0.300 m, pérdidas de 0.9242 / 0.9849 / 1.1139 m).
- Valores extremos en todos los módulos: cero, negativos, 1e-300, 1e300, infinito y NaN. Ningún cálculo debe devolver éxito con NaN o ∞.
- Lectura de campos (coma decimal, textos inválidos, longitud máxima) y avisos en línea.
- Flujos de interfaz: ejemplo en cada módulo, error por diámetro cero, cambio de método, ΣK compartido, limpiar y modo oscuro.

## Integración continua

`.github/workflows/pruebas.yml` corre en cada pull request y en cada push a `main`:

1. **Motor de cálculo**: `swift test` en Linux.
2. **App iOS**: compila con Xcode 26.5, falla si hay advertencias de Swift, y corre las pruebas unitarias y de interfaz en un iPhone 17 con iOS 26.5.

Los resultados (`.xcresult` con capturas) quedan como artefacto del job durante 7 días.
