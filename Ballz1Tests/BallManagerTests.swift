//
//  BallManagerTests.swift
//  Ballz1Tests
//
//  Created by hemingway on 5/3/19.
//  Copyright © 2019 Self. All rights reserved.
//

import XCTest
@testable import Ballz1

class BallManagerTests: XCTestCase {
    
    private var ballManager: BallManager?

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        ballManager = BallManager(numBalls: 10, radius: 1, restorationURL: URL(fileURLWithPath: "x"))
        ballManager!.setOriginPoint(point: CGPoint(x: 0, y: 0))
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testIncrementState() {
        XCTAssertTrue(ballManager!.isReady(), "Ball manager initial state is incorrect")
        ballManager!.incrementState()
        XCTAssertTrue(ballManager!.isShooting(), "Ball manager second state should be SHOOTING")
        ballManager!.incrementState()
        XCTAssertTrue(ballManager!.isWaiting(), "Ball manager third state should be WAITING")
        ballManager!.incrementState()
        XCTAssertTrue(ballManager!.isDone(), "Ball manager final state should be DONE")
        ballManager!.incrementState()
        XCTAssertTrue(ballManager!.isReady(), "Ball manager doesn't transition from DONE to READY")
    }
    
    func testCheckNewArray() {
        let currentBallCount = ballManager!.ballArray.count
        
        let ball1 = BallItem()
        ball1.initItem(num: 0, size: CGSize(width: 1, height: 1))
        ballManager!.addBall(ball: ball1)
        ballManager!.checkNewArray()
        
        XCTAssertTrue(ballManager!.ballArray.count == (currentBallCount + 1), "checkNewArray didn't correctly add a ball")
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
