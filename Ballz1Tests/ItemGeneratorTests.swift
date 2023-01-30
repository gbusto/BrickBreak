//
//  ItemGeneratorTests.swift
//  Ballz1Tests
//
//  Created by Gabriel Busto on 1/29/23.
//  Copyright © 2023 Self. All rights reserved.
//

import XCTest
@testable import Ballz1

class ItemGeneratorTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func test_ItemGenerator_initializeWithoutStateWorks() {
        let blockSize = CGSize(width: 10, height: 10)
        let ballRadius = CGFloat(2)
        let ig = ItemGenerator(blockSize: blockSize,
                               ballRadius: ballRadius,
                               numberOfRows: 5,
                               numItems: 8,
                               state: nil)
        
        XCTAssertEqual(blockSize, ig.blockSize)
        XCTAssertEqual(ballRadius, ig.ballRadius)
        XCTAssertEqual(5, ig.numberOfRows)
        XCTAssertEqual(8, ig.numItemsPerRow)
        XCTAssertEqual(10, ig.numberOfBalls)
    }
    
    func test_ItemGenerator_initializeWithStateWorks() {
        // A lot of this stuff is contained in the ItemGenerator igState property;
        // Write separate tests for that.
        let itemTypeDict: [Int: Int] = [:]
        let itemArray = [[0, 0, 0, 1, 1, 0, 0, 0]]
        let itemHitCountArray = [[0, 0, 0, 10, 9, 0, 0, 0]]
        let blockTypeArray = [1, 1, 1, 1, 1, 3, 3, 5]
        let nonBlockTypeArray = [2, 2, 2, 2, 4]
        let state = DataManager.ItemGeneratorState(
            numberOfBalls: 12,
            itemTypeDict: itemTypeDict,
            itemArray: itemArray,
            itemHitCountArray: itemHitCountArray,
            blockTypeArray: blockTypeArray,
            nonBlockTypeArray: nonBlockTypeArray
        )
        
        let blockSize = CGSize(width: 10, height: 10)
        let ballRadius = CGFloat(2)
        let ig = ItemGenerator(blockSize: blockSize,
                               ballRadius: ballRadius,
                               numberOfRows: 5,
                               numItems: 8,
                               state: state)
        
        XCTAssertEqual(blockSize, ig.blockSize)
        XCTAssertEqual(ballRadius, ig.ballRadius)
        XCTAssertEqual(5, ig.numberOfRows)
        XCTAssertEqual(8, ig.numItemsPerRow)
        XCTAssertEqual(12, ig.numberOfBalls)
    }
    
    func test_ItemGenerator_loadItemsWorks() {
        let blockSize = CGSize(width: 10, height: 10)
        let ballRadius = CGFloat(2)
        let ig = ItemGenerator(blockSize: blockSize,
                               ballRadius: ballRadius,
                               numberOfRows: 5,
                               numItems: 8,
                               state: nil)
        
        let itemsArray = [[1, 0, 1, 0, 3, 0, 5, 0]]
        let hitCounts = [[21, 0, 5, 0, 50, 0, 11, 0]]
        
        let items: [[Item]] = ig.loadItems(
            items: itemsArray,
            itemHitCounts: hitCounts,
            numberOfBalls: 20
        )
        
        let block1 = HitBlockItem()
        block1.initItem(num: 1, size: blockSize)
        block1.setHitCount(count: 21)
        
        let block2 = HitBlockItem()
        block2.initItem(num: 2, size: blockSize)
        block2.setHitCount(count: 5)
        
        let block3 = StoneHitBlockItem()
        block3.initItem(num: 3, size: blockSize)
        block3.setHitCount(count: 50)
        
        let block4 = MysteryBlockItem()
        block4.initItem(num: 4, size: blockSize)
        block4.setHitCount(count: 11)
        
        let finalItemsArray: [[Item]] = [
            [block1, block2, block3, block4],
        ]
        
        XCTAssertEqual(20, ig.numberOfBalls)
        XCTAssertEqual(items.count, finalItemsArray.count)
    }

}


