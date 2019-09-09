//
//  LevelsGameModelTests.swift
//  Ballz1Tests
//
//  Created by Gabriel Busto on 9/7/19.
//  Copyright © 2019 Self. All rights reserved.
//

import XCTest
@testable import Ballz1

class LevelsGameModelTests: XCTestCase {
    
    private var numberOfRows = 10
    private var model: LevelsGameModel?
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        model = LevelsGameModel(blockSize: CGSize(width: 0, height: 0), ballRadius: CGFloat(0), numberOfRows: self.numberOfRows)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        
        model = nil
    }
    
    func testGetActualRowCount() {
        model!.rowNumber = 12
        XCTAssertTrue(model!.getActualRowCount() == 6, "getActualRowCount should have returned 6 but did not")
        
        model!.rowNumber = 10
        XCTAssertTrue(model!.getActualRowCount() == 8, "getActualRowCount should have returned 8 but did not")
        
        model!.rowNumber = 8
        XCTAssertTrue(model!.getActualRowCount() == 10, "getActualRowCount should have returned 10, but did not")
    }
    
    func testLossRisk() {
        var itemArray1: [[Item]] = []
        var itemArray2: [[Item]] = []
        var itemArray3: [[Item]] = []
        
        // We don't TECHNICALLY count the 1st row (row 0) in the game to leave space for balls to go above blocks and break them, so we should start the count at 1 instead of 0 for this test
        for _ in 1...(self.numberOfRows - 3) {
            itemArray1.append([SpacerItem()])
        }
        for _ in 1...(self.numberOfRows - 2) {
            itemArray2.append([SpacerItem()])
        }
        for _ in 1...(self.numberOfRows - 1) {
            itemArray3.append([SpacerItem()])
        }
        
        self.model!.itemGenerator!.itemArray = itemArray1
        XCTAssertFalse(model!.lossRisk(), "Loss risk should be false but isn't")
        
        self.model!.itemGenerator!.itemArray = itemArray2
        XCTAssertTrue(model!.lossRisk(), "Loss risk should be true but isn't")
        
        self.model!.itemGenerator!.itemArray = itemArray3
        XCTAssertFalse(model!.lossRisk(), "Loss risk should be false but isn't")
    }
    
    func testGameOver() {
        var itemArray1: [[Item]] = []
        var itemArray2: [[Item]] = []
        let itemArray3: [[Item]] = []
        
        // We don't TECHNICALLY count the 1st row (row 0) in the game to leave space for balls to go above blocks and break them, so we should start the count at 1 instead of 0 for this test
        for _ in 1...(self.numberOfRows - 2) {
            itemArray1.append([SpacerItem()])
        }
        for _ in 1...(self.numberOfRows - 1) {
            itemArray2.append([SpacerItem()])
        }
        
        self.model!.itemGenerator!.itemArray = itemArray1
        XCTAssertEqual(model!.gameOver(), LevelsGameModel.GAMEOVER_NONE, "Gameover should be GAMEOVER_NONE, but was not")
        
        self.model!.itemGenerator!.itemArray = itemArray2
        XCTAssertEqual(model!.gameOver(), LevelsGameModel.GAMEOVER_LOSS, "Gameover should be GAMEOVER_LOSS but was not")
        
        self.model!.itemGenerator!.itemArray = itemArray3
        XCTAssertEqual(model!.gameOver(), LevelsGameModel.GAMEOVER_WIN, "Gameover should be GAMEOVER_WIN but was not")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
}
