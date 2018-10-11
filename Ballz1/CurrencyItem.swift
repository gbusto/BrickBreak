//
//  CurrencyItem.swift
//  Ballz1
//
//  Created by Gabriel Busto on 10/11/18.
//  Copyright © 2018 Self. All rights reserved.
//

import SpriteKit

class CurrencyItem: Item {
    
    // MARK: Public properties
    public var node: SKSpriteNode?
    
    // MARK: Private properties
    private var wasHit = false
    
    private var categoryBitMask = UInt32(0b0000)
    private var contactTestBitmask = UInt32(0b0010)
    
    // MARK: Protocol functions
    func initItem(num: Int, size: CGSize) {
        node = SKSpriteNode(imageNamed: "money_coin")
        node!.size = size
        node!.name = "$$$\(num)"
        
        let centerPoint = CGPoint(x: size.width / 2, y: size.height / 2)
        let physBody = SKPhysicsBody(circleOfRadius: size.width / 2, center: centerPoint)
        physBody.affectedByGravity = false
        physBody.isDynamic = false
        physBody.angularDamping = 0
        physBody.linearDamping = 0
        physBody.restitution = 1
        physBody.friction = 0
        physBody.categoryBitMask = categoryBitMask
        physBody.contactTestBitMask = contactTestBitmask
        
        node!.physicsBody = physBody
    }
    
    func loadItem(position: CGPoint) -> Bool {
        node!.position = position
        node!.anchorPoint = CGPoint(x: 0, y: 0)
        return true
    }
    
    func hitItem() {
        // Generate feedback for the user here
        let lightImpactFeedback = UIImpactFeedbackGenerator(style: .light)
        lightImpactFeedback.prepare()
        lightImpactFeedback.impactOccurred()
        
        wasHit = true
    }
    
    func removeItem() -> Bool {
        // Have the view perform some kind of action
        return wasHit
    }
    
    func getNode() -> SKNode {
        return node!
    }
    
}
