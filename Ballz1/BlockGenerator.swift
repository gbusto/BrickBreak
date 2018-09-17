//
//  BlockGenerator.swift
//  Ballz1
//
//  Created by Gabriel Busto on 9/15/18.
//  Copyright © 2018 Self. All rights reserved.
//

import SpriteKit
import GameplayKit

class BlockGenerator {
    
    // MARK: Private properties
    private var view : SKView?
    private var width : CGFloat?
    
    private var ceilingHeight : CGFloat?
    private var groundHeight : CGFloat?
    
    private var numBalls : Int?
    private var maxHitCount : Int?
    private var numBlocksPerRow : Int?
    
    private var blockArray : [Block] = []
    
    private var actionsStarted = 0
    private var blockCount = 0

    public func initBlockGenerator(view: SKView, numBalls: Int, numBlocks: Int,
                                   ceiling: CGFloat, ground: CGFloat) {
        
        update(numBalls: numBalls)
        numBlocksPerRow = numBlocks
        self.view = view
        ceilingHeight = ceiling
        groundHeight = ground
        
        width = view.frame.width / CGFloat(numBlocksPerRow!)
        print("Block width will be \(width!)")
    }
    
    public func update(numBalls: Int) {
        self.numBalls = numBalls
        self.maxHitCount = numBalls * 2
    }
    
    public func generateRow(scene: SKScene) {
        for i in 0...(numBlocksPerRow! - 1) {
            if Bool.random() {
                let posX = CGFloat(i) * width!
                let posY = CGFloat(ceilingHeight! - (width! * 1))
                let pos = CGPoint(x: posX, y: posY)
                let block = Block()
                let size = CGSize(width: width!, height: width!)
                let hitCount = Int.random(in: 1...maxHitCount!)
                block.initBlock(num: blockCount, size: size, position: pos, hitCount: hitCount)
                blockArray.append(block)
                block.node!.alpha = 0
                blockCount += 1
                scene.addChild(block.node!)
            }
        }
        
        // Set this value to be the number of items in the array that are going to be animated
        actionsStarted = blockArray.count
        
        for block in blockArray {
            let action1 = SKAction.fadeIn(withDuration: 1)
            let action2 = SKAction.moveBy(x: 0, y: -width!, duration: 1)
            block.node!.run(SKAction.group([action1, action2])) {
                // Remove one from the count each time an action completes
                self.actionsStarted -= 1
            }
        }
    }
    
    public func isReady() -> Bool {
        // This is used to prevent the user from shooting while the block manager isn't ready yet
        return (0 == actionsStarted)
    }
    
    public func hit(name: String) {
        for block in blockArray {
            if block.node!.name == name {
                block.hit()
            }
        }
    }
    
    public func removeBlocks(scene: SKScene) {
        let newBlockArray = blockArray.filter {
            if $0.isDead() {
                scene.removeChildren(in: [$0.node!])
            }
            return !$0.isDead()
        }
        
        blockArray = newBlockArray
    }
    
    public func canAddRow(groundHeight: CGFloat) -> Bool {
        for block in blockArray {
            if (block.node!.position.y - width!) < groundHeight {
                return false
            }
        }
        
        return true
    }
}
