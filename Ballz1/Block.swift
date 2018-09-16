//
//  Block.swift
//  Ballz1
//
//  Created by Gabriel Busto on 9/15/18.
//  Copyright © 2018 Self. All rights reserved.
//

import SpriteKit
import GameplayKit

class Block {
    
    // MARK: Public properties
    public var node : SKSpriteNode?
    
    // MARK: Private properties
    private var size : CGSize?
    private var position : CGPoint?
    private var hitCount : Int?
    
    private var labelNode : SKLabelNode?
    
    // Setting up properties for collisions
    private var categoryBitMask = UInt32(0b0001)
    private var contactTestBitmask = UInt32(0b0001)

    // MARK: Init function
    public func initBlock(num: Int, size: CGSize, position: CGPoint, hitCount: Int) {
        self.size = size
        self.position = position
        self.hitCount = hitCount
        
        node = SKSpriteNode(color: .gray, size: size)
        node!.position = position
        node!.anchorPoint = CGPoint(x: 0, y: 0)
        node!.zPosition = 100
        node!.name = "block\(num)"
        let centerPoint = CGPoint(x: size.width / 2, y: size.height / 2)
        let physBody = SKPhysicsBody(rectangleOf: size, center: centerPoint)
        physBody.affectedByGravity = false
        physBody.isDynamic = false
        physBody.angularDamping = 0
        physBody.linearDamping = 0
        physBody.restitution = 1
        physBody.friction = 0
        node!.physicsBody = physBody
        
        initHitLabel()
        
        node!.addChild(labelNode!)
    }
    
    public func hit() {
        hitCount! -= 1
        
        labelNode!.text = "\(hitCount!)"
    }
    
    public func isDead() -> Bool {
        return (hitCount! <= 0)
    }
    
    // MARK: Private functions
    private func initHitLabel() {
        let centerPoint = CGPoint(x: size!.width / 2, y: size!.height / 3)
        labelNode = SKLabelNode(text: "\(hitCount!)")
        labelNode!.position = centerPoint
        labelNode!.fontSize = size!.width / 2
    }
}
