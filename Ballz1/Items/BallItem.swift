//
//  BallItem.swift
//  Ballz1
//
//  Created by Gabriel Busto on 9/18/18.
//  Copyright © 2018 Self. All rights reserved.
//

import SpriteKit
import GameplayKit

class BallItem: Item {
    
    // MARK: Public properties
    public var node : SKShapeNode?
    public var isResting = true
    
    public var outOfBounds = false
    
    // MARK: Private functions
    // Only used in the hitItem() function
    private var wasHit = false
    
    // Ball radius
    private var radius : CGFloat?
    
    // The bullet's starting point
    private var origin : CGPoint?
    
    private var hitBallColor: UIColor?
    
    // Setting up properties for collisions
    private var collisionBitMask = UInt32(0b0001)
    private var categoryBitMask = UInt32(0b0010)
    private var contactTestBitMask = UInt32(0b0001)
    
    private var defaultColor: UIColor = .white
    
    
    // MARK: Protocol functions
    public func initItem(num: Int, size: CGSize) {
        radius = size.width
        let ball = SKShapeNode(circleOfRadius: radius!)
        ball.zPosition = 100
        ball.fillColor = defaultColor
        ball.name = "ball\(num)"
        
        let physBody = SKPhysicsBody(circleOfRadius: radius!)
        physBody.restitution = 0
        physBody.angularDamping = 0
        physBody.linearDamping = 0
        physBody.allowsRotation = false
        // This was the key to allowing balls to maintain their angles after impact
        physBody.friction = 0
        physBody.affectedByGravity = false
        physBody.collisionBitMask = collisionBitMask
        physBody.categoryBitMask = categoryBitMask
        physBody.contactTestBitMask = contactTestBitMask
        physBody.usesPreciseCollisionDetection = true
        
        ball.physicsBody = physBody
        node = ball
    }
    
    public func startAnimation() {
        let circleNode = SKShapeNode(circleOfRadius: radius! * 0.5)
        circleNode.lineWidth = CGFloat(1)
        circleNode.strokeColor = defaultColor
        circleNode.fillColor = .clear
        circleNode.position = CGPoint(x: 0, y: 0)
        circleNode.zPosition = node!.zPosition - 1
        
        let action1 = SKAction.scale(to: radius!, duration: 2)
        let action2 = SKAction.fadeOut(withDuration: 2)
        let action = SKAction.group([action1, action2])
        circleNode.run(action) {
            circleNode.removeFromParent()
            self.startAnimation()
        }
        
        node!.addChild(circleNode)
    }
    
    public func loadItem(position: CGPoint) -> Bool {
        origin = position
        node!.position = position
        
        startAnimation()
        
        // May need to change this for the BallManager
        node!.physicsBody!.contactTestBitMask = categoryBitMask
        return true
    }
    
    public func hitItem() {
        // Generate feedback for the user here
        let lightImpactFeedback = UIImpactFeedbackGenerator(style: .light)
        lightImpactFeedback.prepare()
        lightImpactFeedback.impactOccurred()
        
        node!.removeAllActions()
        node!.removeAllChildren()
        
        // This will be used by the ItemGenerator, not the BallManager
        // This will be called when a ball that was shot hits a ball that is in an item row
        // Remove all collision bit maskes
        node!.physicsBody!.contactTestBitMask = UInt32(0b0100)
        node!.physicsBody!.categoryBitMask = 0
        node!.physicsBody!.collisionBitMask = UInt32(0b0100)
        node!.fillColor = hitBallColor!
        wasHit = true
    }
    
    public func removeItem() -> Bool {
        // This will be used by the ItemGenerator, not the BallManager
        // This gets called every tick of the scene so this needs to be enclosed
        return wasHit
    }
    
    public func getNode() -> SKNode {
        return node!
    }
    
    public func setColor(color: UIColor) {
        hitBallColor = color
    }
    
    // MARK: Public functions
    public func stop() {
        if node!.hasActions() {
            // If the node is currently executing any actions, just stop them so we can stop the ball now
            node!.removeAllActions()
        }
        
        node!.physicsBody?.isResting = true
        isResting = true
        
        // Put ourselves out
        self.extinguish()
    }
    
    public func moveBallTo(_ point: CGPoint) {
        // Now with all actions stopped, we can tell the ball to return to this point
        node!.run(SKAction.move(to: point, duration: 0.2)) {
            // Reset this variable
            self.outOfBounds = false
            
            self.resetBall()
        }
    }
    
    public func resetBall() {
        node!.physicsBody!.collisionBitMask = collisionBitMask
        node!.physicsBody!.categoryBitMask = categoryBitMask
        node!.physicsBody!.contactTestBitMask = contactTestBitMask
        node!.fillColor = defaultColor
        node!.physicsBody!.affectedByGravity = false
        
        node!.removeAllChildren()
    }
    
    public func fire(point: CGPoint) {
        // Take the origin point and create a "box" around it
        let originPoint = node!.position
        // The "box" we create around the origin point
        let maxX = originPoint.x + 20
        let maxY = originPoint.y + 20
        let minX = originPoint.x - 20
        
        // 1. Calculate the slope
        let slope = calcSlope(originPoint: originPoint, touchPoint: point)
        
        // 2. Calculate the intercept
        let intercept = calcYIntercept(point: point, slope: slope)
        
        var newX = CGFloat(0)
        var newY = CGFloat(0)
        
        // 3a. If slope is >= 1 or <= -1, use maxY and solve for x using slope and intercept
        if (slope >= 1) || (slope <= -1) {
            // y = mx + b <- Solve for X
            // (y / m) - b = x
            newY = maxY
            newX = (newY - intercept) / slope
        }
            // 3b. If slope is between -1 and 1, use maxX and solve for y using slope and intercept
        else if (slope < 1) && (slope > -1) {
            // y = mx + b <- Solve for y
            if (slope < 0) {
                newX = minX
            }
            else if (slope > 0) {
                newX = maxX
            }
            newY = (slope * newX) + intercept
        }
        
        let impulseX = (newX - originPoint.x) / 5
        let impulseY = (newY - originPoint.y) / 5
        
        node!.physicsBody!.applyImpulse(CGVector(dx: impulseX, dy: impulseY))
        isResting = false
    }
    
    public func setOnFire() {
        let emitterNode = SKEmitterNode(fileNamed: "Fire.sks")
        if let emNode = emitterNode {
            emNode.name = "fireChild"
            node!.addChild(emNode)
        }
    }
    
    public func extinguish() {
        // Put out the fire
        for child in node!.children {
            if let name = child.name {
                if name == "fireChild" {
                    node!.removeChildren(in: [child])
                }
            }
        }
    }
    
    
    // MARK: Private functions
    private func calcSlope(originPoint: CGPoint, touchPoint: CGPoint) -> CGFloat {
        let rise = touchPoint.y - originPoint.y
        let run  = touchPoint.x - originPoint.x
        
        return CGFloat(rise / run)
    }
    
    private func calcYIntercept(point: CGPoint, slope: CGFloat) -> CGFloat {
        // y = mx + b <- We want to find 'b'
        // (point.y - (point.x * slope)) = b
        let intercept = point.y - (point.x * slope)
        
        return intercept
    }
}
