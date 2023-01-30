//
//  Ballz1UITests.swift
//  Ballz1UITests
//
//  Created by Gabriel Busto on 9/13/18.
//  Copyright © 2018 Self. All rights reserved.
//

import XCTest

class Ballz1UITests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_ContinousGameMode_statusBarExists() {
        let app = XCUIApplication()

        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        app.buttons["Classic"].tap()
                
        XCTAssert(app.staticTexts["continuousStatusBarHighScoreLabelId"].exists)
        
        XCTAssert(app.staticTexts["continuousStatusBarGameScoreLabelId"].exists)
        
        XCTAssert(app.buttons["continuousStatusBarUndoButton"].exists)
        
        XCTAssert(app.images["continuousStatusBarHeartImageView"].exists)
    }
    
    func test_LevelsGameMode_statusBarExists() {
        let app = XCUIApplication()

        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        app.buttons["Levels"].tap()
                
        XCTAssert(app.staticTexts["levelsStatusBarLevelCountLabelId"].exists)
        
        XCTAssert(app.staticTexts["levelsStatusBarLevelScoreLabelId"].exists)
        
        XCTAssert(app.staticTexts["levelsStatusBarRowCountLabelId"].exists)
        
        XCTAssert(app.images["levelsStatusBarHeartImageView"].exists)
    }

}
