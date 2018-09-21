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
    private var scene : SKScene?
    private var numberOfBalls : Int?
    
    private var ballRadius : CGFloat?
    private var ballArray : [BallItem] = []
    // Balls that have just been added from the ItemGenerator
    private var newBallArray : [BallItem] = []
    
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
    
    private var labelNode : SKLabelNode?
    
    
    // MARK: Public functions
    public func initBallManager(scene: SKScene, generator: ItemGenerator, numBalls: Int, position: CGPoint, radius: CGFloat) {
        numberOfBalls = numBalls
        originPoint = position
        self.scene = scene
        ballRadius = radius
        
        for i in 1...numBalls {
            let ball = BallItem()
            let size = CGSize(width: radius, height: radius)
            ball.initItem(generator: generator, num: i, size: size, position: position)
            ballArray.append(ball)
        }
        
        labelNode = SKLabelNode()

        state = READY
    }
    
    public func incrementState() {
        if DONE == state {
            state = READY
            return
        }
        
        state += 1
    }
    
    public func checkNewArray() {
        let array = newBallArray.filter {
            $0.setBitmasks()
            $0.returnToOrigin(point: originPoint!)
            self.ballArray.append($0)
            self.updateLabel()
            return false
        }
        newBallArray = array
        numberOfBalls = ballArray.count
    }
    
    public func getOriginPoint() -> CGPoint {
        return originPoint!
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
    
    // This is only called once
    public func addBalls() {
        for ball in ballArray {
            scene!.addChild(ball.node!)
        }
        addLabel()
    }
    
    public func addBall(ball: BallItem, atPoint: CGPoint) {
        newBallArray.append(ball)
        ball.getNode().run(SKAction.move(to: atPoint, duration: 0.5))
    }
    
    public func shootBall() {
        let ball = ballArray[numBallsActive]
        ball.fire(point: direction!)
        numBallsActive += 1
        
        if numBallsActive == ballArray.count {
            incrementState()
            removeLabel()
        }
        else {
            updateLabel()
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
                    print("First ball returned at point \(ball.node!.position)")
                    firstBallReturned = true
                    originPoint = ball.node!.position
                    // originPoint needs to be set before calling addLabel()
                    addLabel()
                }
                print("Telling ball to stop at origin point \(originPoint!)")
                ball.stop(point: originPoint!)
                numBallsActive -= 1
                updateLabel()
            }
        }
        
        if 0 == numBallsActive {
            incrementState()
            firstBallReturned = false
        }
    }
    
    // MARK: Private functions
    private func addLabel() {
        let newPoint = CGPoint(x: originPoint!.x, y: (originPoint!.y + (ballRadius! * 1.5)))
        labelNode!.position = newPoint
        labelNode!.fontSize = ballRadius! * 3
        labelNode!.color = .white
        updateLabel()
        scene!.addChild(labelNode!)
    }
    
    private func updateLabel() {
        labelNode!.text = "Balls: \(ballArray.count - numBallsActive)"
    }
    
    private func removeLabel() {
        scene!.removeChildren(in: [labelNode!])
    }
}
