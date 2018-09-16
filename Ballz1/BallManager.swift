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
    
    private var firstBallReturned = false
    
    private var numBallsActive = 0
    
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
        let ball = ballArray[numBallsActive]
        ball.fire(point: direction!)
        numBallsActive += 1
        
        if numBallsActive == ballArray.count {
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
        if 0 == numBallsActive {
            firstBallReturned = false
            return
        }
                
        for ball in ballArray {
            if ball.isResting {
                continue
            }
            if false == ball.isActive {
                ball.stop()
                if false == firstBallReturned {
                    firstBallReturned = true
                    originPoint = ball.node!.position
                }
                numBallsActive -= 1
            }
        }
        
        if 0 == numBallsActive {
            incrementState()
        }
    }
}
