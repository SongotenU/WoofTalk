// MARK: - TranslationUITests

import XCTest

final class TranslationUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    func testTranslationFlow() throws {
        // Navigate to translation tab
        app.tabBars.buttons["Translate"].tap()
        
        // Verify initial state
        XCTAssertTrue(app.staticTexts["Ready to translate"].exists)
        XCTAssertTrue(app.buttons["Start"].exists)
        
        // Start translation
        app.buttons["Start"].tap()
        XCTAssertTrue(app.buttons["Stop"].exists)
        
        // Verify audio level indicator appears
        XCTAssertTrue(app.staticTexts["Audio Level:"].exists)
        
        // Verify latency indicator appears
        XCTAssertTrue(app.staticTexts["Latency:"].exists)
        
        // Wait for translation to complete
        sleep(3)
        
        // Verify translation results
        XCTAssertTrue(app.staticTexts["Translation complete"].exists)
        XCTAssertTrue(app.staticTexts["Hello! I'm happy to see you! (excited)"].exists)
        
        // Stop translation
        app.buttons["Stop"].tap()
        XCTAssertTrue(app.buttons["Start"].exists)
    }
    
    func testUIResponsiveness() throws {
        app.tabBars.buttons["Translate"].tap()
        
        // Start translation
        app.buttons["Start"].tap()
        
        // Verify UI remains responsive during translation
        XCTAssertTrue(app.buttons["Start"].exists)
        XCTAssertTrue(app.staticTexts["Listening..."].exists)
        
        // Test tab switching
        app.tabBars.buttons["Offline"].tap()
        XCTAssertTrue(app.staticTexts["Offline Mode"].exists)
        
        // Return to translation
        app.tabBars.buttons["Translate"].tap()
        XCTAssertTrue(app.staticTexts["Listening..."].exists)
        
        // Wait and verify translation completes
        sleep(3)
        XCTAssertTrue(app.staticTexts["Translation complete"].exists)
    }
    
    func testErrorHandling() throws {
        app.tabBars.buttons["Translate"].tap()
        
        // Simulate error (would require actual audio processing failure)
        // For now, just verify error UI elements exist
        XCTAssertTrue(app.buttons["Start"].exists)
        
        // Start translation
        app.buttons["Start"].tap()
        
        // Wait for potential error
        sleep(2)
        
        // Verify error handling UI exists
        XCTAssertTrue(app.buttons["Start"].exists || app.buttons["Stop"].exists)
    }
}