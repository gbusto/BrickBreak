//
//  HitBlockItem.swift
//  Ballz1
//
//  Created by Gabriel Busto on 9/18/18.
//  Copyright © 2018 Self. All rights reserved.
//

import SpriteKit
import GameplayKit

class HitBlockItem: Item {
    // MARK: Public properties
    public var node : SKSpriteNode?
    public var hitCount : Int?
    
    // MARK: Private properties
    private var size : CGSize?
    private var position : CGPoint?
    
    private var fontName = "KohinoorBangla-Regular"
    private var labelNode : SKLabelNode?
    
    // Setting up properties for collisions
    private var categoryBitMask = UInt32(0b0001)
    private var contactTestBitmask = UInt32(0b0001)
    
    // MARK: Protocol functions
    func initItem(num: Int, size: CGSize) {
        self.size = size
        
        node = SKSpriteNode(color: .gray, size: size)
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
        physBody.categoryBitMask = categoryBitMask
        physBody.contactTestBitMask = contactTestBitmask
        node!.physicsBody = physBody
    }
    
    // This should also handle coloring the item appropriately
    func loadItem(position: CGPoint) -> Bool {
        self.position = position
        node!.position = position
        return true
    }
    
    func hitItem() {
        hitCount! -= 1
        // Don't update the label to zero; it should just disappear
        if hitCount! > 0 {
            labelNode!.text = "\(hitCount!)"
        }
    }
    
    func removeItem() -> Bool {
        // This is where the block bust animation will go
        if hitCount! <= 0 {
            // Give the user some haptic feedback to let them know a block broke
            let lightImpactFeedback = UIImpactFeedbackGenerator(style: .medium)
            lightImpactFeedback.prepare()
            lightImpactFeedback.impactOccurred()
            return true
        }
        return false
    }
    
    func getNode() -> SKNode {
        return node!
    }
    
    // MARK: Public functions
    public func setColor(color: UIColor) {
        node!.color = color
    }
    
    public func setHitCount(count: Int) {
        hitCount = count
        initHitLabel()
        node!.addChild(labelNode!)
    }
    
    public func updateHitCount(count: Int) {
        hitCount = count
        labelNode!.text = "\(hitCount!)"
    }
    
    // MARK: Private functions
    private func initHitLabel() {
        let centerPoint = CGPoint(x: size!.width / 2, y: size!.height / 3)
        labelNode = SKLabelNode(text: "\(hitCount!)")
        labelNode!.fontColor = .black
        labelNode!.position = centerPoint
        labelNode!.fontSize = size!.width / 2
        labelNode!.fontName = fontName
    }
}
