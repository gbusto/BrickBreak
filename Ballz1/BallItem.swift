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
    public var isActive = false
    public var isResting = true
    
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
    
    
    // MARK: Protocol functions
    public func initItem(num: Int, size: CGSize) {
        radius = size.width
        let ball = SKShapeNode(circleOfRadius: radius!)
        ball.zPosition = 100
        ball.fillColor = .white
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
    
    public func loadItem(position: CGPoint) -> Bool {
        origin = position
        node!.position = position
        
        // May need to change this for the BallManager
        node!.physicsBody!.contactTestBitMask = categoryBitMask
        return true
    }
    
    public func hitItem() {
        // Generate feedback for the user here
        let lightImpactFeedback = UIImpactFeedbackGenerator(style: .light)
        lightImpactFeedback.prepare()
        lightImpactFeedback.impactOccurred()
        
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
    public func stop(point: CGPoint) {
        if node!.hasActions() {
            // If the node is currently executing any actions, just stop them so we can stop the ball now
            node!.removeAllActions()
        }
        // Now with all actions stopped, we can tell the ball to return to this point
        node!.run(SKAction.move(to: point, duration: 0.2)) {
            self.resetBall()
        }
        node!.physicsBody?.isResting = true
        isResting = true
    }
    
    public func resetBall() {
        node!.physicsBody!.collisionBitMask = collisionBitMask
        node!.physicsBody!.categoryBitMask = categoryBitMask
        node!.physicsBody!.contactTestBitMask = contactTestBitMask
        node!.fillColor = .white
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
        
        node!.run(SKAction.applyImpulse(CGVector(dx: impulseX, dy: impulseY), duration: 0.01))
        isActive = true
        isResting = false
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
