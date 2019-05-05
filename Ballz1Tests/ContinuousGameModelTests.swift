//
//  ContinuousGameModelTests.swift
//  Ballz1Tests
//
//  Created by hemingway on 5/5/19.
//  Copyright © 2019 Self. All rights reserved.
//

import XCTest
@testable import Ballz1

class ContinuousGameModelTests: XCTestCase {
    
    private var model: ContinuousGameModel?

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        model = ContinuousGameModel(numberOfRows: 10)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testIncrementState() {
        // The reason it starts in the WAITING state is because we need to update the view and shift items down; the state we want to start in is essentially the same state that the game is in after a turn has completed but before the user can shoot balls to perform all the necessary actions during that window of time.
        // Once the item generator is initialized, if there are items in it it sets the model to the TURN_OVER state (right before the WAITING state) to simulate a turn ending and performing all of those actions before the WAITING state.
        XCTAssertTrue(model!.isWaiting(), "CGM started in wrong state")
        model!.incrementState()
        XCTAssertTrue(model!.isReady(), "CGM should be in ready state but isn't")
        model!.incrementState()
        XCTAssertTrue(model!.isMidTurn(), "CGM should be in the midTurn state but isn't")
        model!.incrementState()
        XCTAssertTrue(model!.isTurnOver(), "CGM should be in turnOver state but isn't")
        model!.incrementState()
        XCTAssertTrue(model!.isWaiting(), "CGM should be in waiting state but isn't")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
