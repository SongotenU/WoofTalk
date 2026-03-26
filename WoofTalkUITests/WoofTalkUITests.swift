//
//  WoofTalkUITests.swift
//  WoofTalkUITests
//
//  Created by vandopha on 11/3/26.
//

import XCTest

final class WoofTalkUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testSettingsModeToggle() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Wait for settings button
        let settingsButton = app.buttons["settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.tap()
        
        // Settings presented; find the translation mode segmented control
        let segmentedControl = app.segmentedControls["translationModeControl"]
        XCTAssertTrue(segmentedControl.waitForExistence(timeout: 2))
        
        // Toggle to AI mode
        segmentedControl.buttons["AI"].tap()
        XCTAssertEqual(segmentedControl.value as? String, "AI")
        
        // Toggle to Auto mode
        segmentedControl.buttons["Auto"].tap()
        XCTAssertEqual(segmentedControl.value as? String, "Auto")
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
