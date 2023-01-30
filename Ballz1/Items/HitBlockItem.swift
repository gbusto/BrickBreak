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
    
    public var bottomColor: SKColor?
    public var topColor: SKColor?
    
    // MARK: Private properties
    private var size : CGSize?
    private var position : CGPoint?
    
    private var fontName = "Verdana"
    private var labelNode : SKLabelNode?
    private var shadowLabel: SKLabelNode?
    
    // Setting up properties for collisions
    private var categoryBitMask = UInt32(0b0001)
    private var contactTestBitmask = UInt32(0b0001)
    
    // MARK: Protocol functions
    func initItem(num: Int, size: CGSize) {
        self.size = size
        
        node = SKSpriteNode(color: .gray, size: size)
        node!.anchorPoint = CGPoint(x: 0, y: 0)
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
    // TODO: If this needs to return something, it should be more useful than a boolean
    func loadItem(position: CGPoint) -> Bool {
        self.position = position
        node!.position = position
        return true
    }
    
    func hitItem() {
        if let hn = node!.childNode(withName: "hitNode") {
            self.node!.removeChildren(in: [hn])
        }
        
        let hitNode = SKSpriteNode(color: .white, size: size!)
        hitNode.name = "hitNode"
        hitNode.alpha = 0
        hitNode.zPosition = 103
        hitNode.position = CGPoint(x: size!.width / 2, y: size!.height / 2)
        node!.addChild(hitNode)
        let action1 = SKAction.fadeAlpha(to: 0.5, duration: 0.05)
        let action2 = SKAction.fadeOut(withDuration: 0.05)
        hitNode.run(SKAction.sequence([action1, action2])) {
            hitNode.removeFromParent()
        }
        
        hitCount! -= 1
        // Don't update the label to zero; it should just disappear
        if hitCount! > 0 {
            labelNode!.text = "\(hitCount!)"
            shadowLabel!.text = labelNode!.text
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
    public func setAttributes(bottomColor: SKColor, topColor: SKColor, textColor: UIColor, fontName: String) {
        let newTexture = SKTexture(size: size!, startColor: bottomColor, endColor: topColor)
        self.bottomColor = bottomColor
        self.topColor = topColor
        node!.texture = newTexture
        labelNode!.fontColor = textColor
        labelNode!.fontName = fontName
        shadowLabel!.fontName = fontName
    }
    
    public func setHitCount(count: Int) {
        hitCount = count
        initHitLabel()
        initShadowLabel()
        node!.addChild(labelNode!)
        node!.addChild(shadowLabel!)
    }
    
    public func updateHitCount(count: Int) {
        hitCount = count
        labelNode!.text = "\(hitCount!)"
        shadowLabel!.text = labelNode!.text
    }
    
    // MARK: Private functions
    private func initHitLabel() {
        let centerPoint = CGPoint(x: size!.width / 2, y: size!.height / 3)
        labelNode = SKLabelNode(text: "\(hitCount!)")
        labelNode!.position = centerPoint
        labelNode!.fontSize = size!.width / 2.4
        labelNode!.fontName = fontName
        labelNode!.zPosition = 99
    }
    
    private func initShadowLabel() {
        let centerPoint = CGPoint(x: labelNode!.position.x + 1, y: labelNode!.position.y - 1)
        shadowLabel = SKLabelNode(text: labelNode!.text)
        shadowLabel!.position = centerPoint
        shadowLabel!.fontSize = labelNode!.fontSize
        shadowLabel!.fontName = fontName
        shadowLabel!.fontColor = UIColor.gray
        shadowLabel!.zPosition = labelNode!.zPosition - 1
        shadowLabel!.alpha = 0.4
    }
}
