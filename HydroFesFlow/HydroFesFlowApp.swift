import SwiftUI
import UIKit

@main
struct HydroFesFlowApp: App {
    init() {
        if ProcessInfo.processInfo.arguments.contains("--pruebas-ui") {
            UIView.setAnimationsEnabled(false)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
