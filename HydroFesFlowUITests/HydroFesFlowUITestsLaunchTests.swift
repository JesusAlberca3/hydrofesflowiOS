//
//  HydroFesFlowUITestsLaunchTests.swift
//  HydroFesFlowUITests
//
//  Created by Jesús Alberto López Alonso on 10/13/26.
//

import XCTest

final class HydroFesFlowUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--pruebas-ui"]
        app.launch()
        XCTAssertTrue(app.buttons["inicio.conductos"].waitForExistence(timeout: 10))

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
