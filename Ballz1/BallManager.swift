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
    // READY state means that all balls are at rest, all animations are complete
    // Changes from this state by GameScene when the user touches the screen to fire balls
    private var READY = Int(0)
    // SHOOTING state is when it's firing balls
    // Changes from this state by itself after all balls have been shot to notify GameScene to stop calling shootBall()
    private var SHOOTING = Int(1)
    // WAITING state is when all the balls have been fired and we're waiting for balls to return to the ground
    // Changes from this state by itself after all balls are at rest again to notify GameScene
    private var WAITING = Int(2)
    // DONE state tells GameScene that the BallManager is done and all balls are at rest again
    // Changes from this state by GameScene and used to tell when a "turn" is over and to add another row to the game scene
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
        if isReady() || isDone() {
            return
        }
                
        for ball in ballArray {
            if ball.isResting {
                continue
            }
            if false == ball.isActive {
                if false == firstBallReturned {
                    firstBallReturned = true
                    originPoint = ball.node!.position
                }
                ball.stop(point: originPoint!)
                numBallsActive -= 1
            }
        }
        
        if 0 == numBallsActive {
            incrementState()
            firstBallReturned = false
        }
    }
}
