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
    
    // MARK: Private properties
    private var generator : ItemGenerator?
    
    private var size : CGSize?
    private var position : CGPoint?
    private var hitCount : Int?
    
    private var fontName = "KohinoorBangla-Regular"
    private var labelNode : SKLabelNode?
    
    // Setting up properties for collisions
    private var categoryBitMask = UInt32(0b0001)
    private var contactTestBitmask = UInt32(0b0001)
    
    private var color : BlockColor?
    
    // MARK: Protocol functions
    func initItem(generator: ItemGenerator, num: Int, size: CGSize, position: CGPoint) {
        self.size = size
        self.position = position
        self.generator = generator
        hitCount = Int.random(in: 1...generator.maxHitCount!)
        
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
    
    func loadItem() -> Bool {
        return true
    }
    
    func hitItem() {
        hitCount! -= 1
        labelNode!.text = "\(hitCount!)"
    }
    
    func removeItem(scene: SKScene) -> Bool {
        // This is where the block bust animation will go
        if hitCount! <= 0 {
            // Give the user some haptic feedback to let them know a block broke
            let lightImpactFeedback = UIImpactFeedbackGenerator(style: .medium)
            lightImpactFeedback.prepare()
            lightImpactFeedback.impactOccurred()
            scene.removeChildren(in: [node!])
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
