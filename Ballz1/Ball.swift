//
//  Ball.swift
//  Ballz1
//
//  Created by Gabriel Busto on 9/13/18.
//  Copyright © 2018 Self. All rights reserved.
//

import SpriteKit
import GameplayKit

class Ball {
    
    // MARK: Public properties
    public var node : SKShapeNode?
    public var isActive = false
    
    // MARK: Private properties
    // Ball radius
    private var radius : CGFloat?
    
    // The bullet's starting point
    private var origin : CGPoint?
    
    // Setting up properties for collisions
    private var collisionBitMask = UInt32(0b0001)
    private var categoryBitMask = UInt32(0b0010)
    private var contactTestBitMask = UInt32(0b0001)
    
    
    // MARK: Public functions
    public func initBall(num: Int, position: CGPoint, radius: CGFloat) {
        self.radius = radius
        let ball = SKShapeNode(circleOfRadius: radius)
        ball.position = position
        ball.fillColor = .yellow
        ball.name = "ball\(num)"
        
        let physBody = SKPhysicsBody(circleOfRadius: radius)
        physBody.angularDamping = 0
        physBody.linearDamping = 0
        physBody.restitution = 1
        physBody.allowsRotation = false
        // This was the key to allowing balls to maintain their angles after impact
        physBody.friction = 0
        physBody.affectedByGravity = false
        physBody.collisionBitMask = collisionBitMask
        physBody.categoryBitMask = categoryBitMask
        physBody.contactTestBitMask = contactTestBitMask
        physBody.usesPreciseCollisionDetection = true
        
        ball.physicsBody = physBody
        origin = position
        node = ball
    }
    
    public func stop() {
        node!.removeAllActions()
        isActive = false
    }
    
    public func returnToOrigin(point: CGPoint) {
        node!.run(SKAction.move(to: point, duration: 0.1))
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
        
        node!.run(SKAction.applyImpulse(CGVector(dx: impulseX, dy: impulseY), duration: 0.00001))
        isActive = true
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
