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
    private var start = false
    
    private var view : SKView?
    private var width : CGFloat?
    
    private var ceilingHeight : CGFloat?
    private var groundHeight : CGFloat?
    
    private var numBalls : Int?
    private var maxHitCount : Int?
    private var numBlocksPerRow : Int?
    
    private var blockArray : [Block] = []

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
                var posY = CGFloat(0)
                if false == start {
                    posY = CGFloat(ceilingHeight! - (width! * 1))
                }
                else {
                    posY = CGFloat(ceilingHeight!)
                }
                let pos = CGPoint(x: posX, y: posY)
                let block = Block()
                let size = CGSize(width: width!, height: width!)
                let hitCount = Int.random(in: 1...maxHitCount!)
                block.initBlock(num: i, size: size, position: pos, hitCount: hitCount)
                blockArray.append(block)
                scene.addChild(block.node!)
            }
        }
        
        if false == start {
            start = true
        }
        
        for block in blockArray {
            block.node!.run(SKAction.moveBy(x: 0, y: -width!, duration: 1))
        }
    }
    
    public func hit(name: String) {
        for block in blockArray {
            if block.node!.name == name {
                block.hit()
            }
        }
    }
    
    public func removeBlocks(scene: SKScene) {
        var iterator = blockArray.makeIterator()
        var index = 0
        
        while let block = iterator.next() {
            if block.isDead() {
                scene.removeChildren(in: [block.node!])
                blockArray.remove(at: index)
            }
            index += 1
        }
    }
}
