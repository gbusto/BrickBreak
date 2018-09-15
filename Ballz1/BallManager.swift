//
//  BallManager.swift
//  Ballz1
//
//  Created by Gabriel Busto on 9/14/18.
//  Copyright © 2018 Self. All rights reserved.
//

import SpriteKit
import GameplayKit

class BallManager {
    
    // MARK: Private properties
    private var numberOfBalls : Int?
    private var ballArray : [Ball] = []
    private var activeBallArray : [Ball] = []
    
    private var firstBallReturned = false
    
    private var originPoint : CGPoint?
    
    // MARK: State values
    private var READY = Int(0)
    private var SHOOTING = Int(1)
    private var WAITING = Int(2)
    private var DONE = Int(3)
    
    private var state = Int(0)
    
    private var direction : CGPoint?
    
    
    // MARK: Public functions
    public func initBallManager(numBalls: Int, position: CGPoint, radius: CGFloat) {
        numberOfBalls = numBalls
        originPoint = position
        
        for i in 1...numBalls {
            let ball = Ball()
            ball.initBall(num: i, position: position, radius: radius)
            ballArray.append(ball)
        }
        
        state = READY
    }
    
    public func incrementState() {
        if DONE == state {
            state = READY
            return
        }
        
        state += 1
    }
    
    public func isReady() -> Bool {
        return (state == READY)
    }
    
    public func isShooting() -> Bool {
        return (state == SHOOTING)
    }
    
    public func isWaiting() -> Bool {
        return (state == WAITING)
    }
    
    public func isDone() -> Bool {
        return (state == DONE)
    }
    
    public func setDirection(point: CGPoint) {
        direction = point
    }
    
    public func addBalls(scene: SKScene) {
        for ball in ballArray {
            scene.addChild(ball.node!)
        }
    }
    
    public func shootBall() {
        let ball = ballArray[activeBallArray.count]
        ball.fire(point: direction!)
        activeBallArray.append(ball)
        
        if activeBallArray.count == ballArray.count {
            incrementState()
        }
    }
    
    public func markBallInactive(name: String) {
        for ball in ballArray {
            if ball.node!.name == name {
                ball.isActive = false
            }
        }
    }
    
    public func stopInactiveBalls() {
        if 0 == activeBallArray.count {
            firstBallReturned = false
            return
        }
        
        var indices : [Int] = []
        
        for i in 0...(activeBallArray.count - 1) {
            let ball = activeBallArray[i]
            if false == ball.isActive {
                ball.stop()
                indices.append(i)
                if false == firstBallReturned {
                    firstBallReturned = true
                    // Might need to change this; not sure if position updates depending on where it is
                    originPoint = ball.node!.position
                }
            }
        }
        
        for index in indices {
            activeBallArray.remove(at: index)
        }
        
        if 0 == activeBallArray.count {
            incrementState()
        }
    }
}
