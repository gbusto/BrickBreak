//
//  HitBlockItemTests.swift
//  Ballz1Tests
//
//  Created by hemingway on 5/5/19.
//  Copyright © 2019 Self. All rights reserved.
//

import XCTest
@testable import Ballz1

class HitBlockItemTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testHitItem() {
        let block = HitBlockItem()
        block.initItem(num: 1, size: CGSize(width: 1, height: 1))
        block.setHitCount(count: 2)
        XCTAssertTrue(block.hitCount == 2, "Hit count is bad value")
        block.hitItem()
        XCTAssertTrue(block.hitCount == 1, "Hit count not decremented properly")
        block.hitItem()
        XCTAssertTrue(block.hitCount == 0, "Hit count should be zero")
    }
    
    func testRemoveItem() {
        let block = HitBlockItem()
        block.initItem(num: 1, size: CGSize(width: 1, height: 1))
        block.setHitCount(count: 1)
        XCTAssertTrue(block.hitCount == 1, "Initial hit block count is wrong")
        let result1 = block.removeItem()
        XCTAssertFalse(result1, "Item should not be remove at this point but was")
        
        block.hitItem()
        XCTAssertTrue(block.hitCount == 0, "Hit count should be zero")
        let result2 = block.removeItem()
        XCTAssertTrue(result2, "Item should have been removed at this point but wasn't")
    }
    
    func testSetHitCount() {
        let block = HitBlockItem()
        block.initItem(num: 1, size: CGSize(width: 1, height: 1))
        block.setHitCount(count: 1)
        XCTAssertTrue(block.hitCount == 1, "Initial hit block count is wrong")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
