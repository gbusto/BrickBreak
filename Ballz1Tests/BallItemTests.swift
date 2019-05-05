//
//  BallItemTests.swift
//  Ballz1Tests
//
//  Created by hemingway on 5/5/19.
//  Copyright © 2019 Self. All rights reserved.
//

import XCTest
@testable import Ballz1

class BallItemTests: XCTestCase {
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testFire() {
        let ballItem = BallItem()
        ballItem.initItem(num: 1, size: CGSize(width: 1, height: 1))
        ballItem.loadItem(position: CGPoint(x: 0, y: 0))
        XCTAssertTrue(ballItem.isResting, "Ball item was not resting to begin with")
        ballItem.fire(point: CGPoint(x: 1, y: 1))
        XCTAssertTrue(ballItem.isResting == false, "Ball item is still at rest after firing")
    }
    
    func testStop() {
        let ballItem = BallItem()
        ballItem.initItem(num: 1, size: CGSize(width: 1, height: 1))
        ballItem.loadItem(position: CGPoint(x: 0, y: 0))
        XCTAssertTrue(ballItem.isResting, "Ball item was not resting to begin with")
        ballItem.fire(point: CGPoint(x: 1, y: 1))
        XCTAssertTrue(ballItem.isResting == false, "Ball item is still at rest after firing")
        ballItem.stop()
        XCTAssertTrue(ballItem.isResting, "Ball item is not at rest after stopping")
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
