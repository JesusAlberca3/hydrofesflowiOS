import SwiftUI
import UIKit

@main
struct HydroFesFlowApp: App {
    private let argumentos = ProcessInfo.processInfo.arguments

    init() {
        if ProcessInfo.processInfo.arguments.contains("--pruebas-ui") {
            UIView.setAnimationsEnabled(false)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(argumentos.contains("--modo-oscuro") ? .dark : nil)
        }
    }
}
