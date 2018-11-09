//
//  StoneHitBlockItem.swift
//  Ballz1
//
//  Created by Gabriel Busto on 10/13/18.
//  Copyright © 2018 Self. All rights reserved.
//

import SpriteKit

class StoneHitBlockItem: Item {
    // MARK: Public properties
    public var node : SKSpriteNode?
    public var hitCount : Int?
    
    // MARK: Private properties
    private var size : CGSize?
    private var position : CGPoint?
    
    private var fontName = "Courier"
    private var labelNode : SKLabelNode?
    
    // true if the item is currently stone
    private var isStone = true
    
    private var originalColor: UIColor = .white
    private var originalTexture: SKTexture?
    private var stoneTexture: SKTexture?
    
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
        
        stoneTexture = SKTexture(imageNamed: "stone_texture")
        
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
        // If the block isn't stone, it can be hit
        if false == isStone {
            hitCount! -= 1
            // Don't update the label to zero; it should just disappear
            if hitCount! > 0 {
                labelNode!.text = "\(hitCount!)"
            }
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
    public func setColor(blockColor: UIColor, textColor: UIColor) {
        node!.color = blockColor
        originalColor = blockColor
        labelNode!.fontColor = textColor
    }
    
    public func setTexture(blockTexture: SKTexture, textColor: UIColor) {
        node!.texture = blockTexture
        originalTexture = blockTexture
        labelNode!.fontColor = textColor
    }
    
    public func changeState(duration: TimeInterval) {
        // When it changes to stone, it should also be animated to change to a grey color
        // When it changes back to normal, it should go back to its normal color
        isStone = !isStone
        
        let action1 = SKAction.fadeAlpha(to: 0.3, duration: duration / 2)
        let action2 = SKAction.fadeIn(withDuration: duration / 2)
        
        if isStone {
            // Change back to normal
            node!.run(action1) {
                self.node!.texture = self.stoneTexture!
                self.node!.run(action2)
            }
        }
        else {
            // Change to stone
            node!.run(action1) {
                self.node!.texture = self.originalTexture!
                self.node!.run(action2)
            }
        }
    }
    
    /*
    public func changeState(duration: TimeInterval) {
        // When it changes to stone, it should also be animated to change to a grey color
        // When it changes back to normal, it should go back to its normal color
        isStone = !isStone
        
        if isStone {
            let action = SKAction.colorize(with: .gray, colorBlendFactor: 1.0, duration: duration)
            node!.run(action)
        }
        else {
            let action = SKAction.colorize(with: originalColor, colorBlendFactor: 1.0, duration: duration)
            node!.run(action)
        }
    }
    */
    
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
        labelNode!.fontSize = size!.width / 2.4
        labelNode!.fontName = fontName
        labelNode!.zPosition = 100
    }
}
