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
    
    // MARK: Public properties
    public var numberOfBalls = Int(0)
    
    // MARK: Private properties
    private var scene : SKScene?
    
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
    
    private var fontName = "KohinoorBangla-Regular"
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
        let numNewBalls = newBallArray.count
        
        // This is code to add a floating indicator saying how many balls you acquired last turn
        // It generates a little label that fades in, floats up, and fades out saying +3 if you got 3 new balls that turn
        if numNewBalls > 0 {
            print("Adding floating label!")
            let fontSize = CGFloat(20)
            let pos = CGPoint(x: originPoint!.x, y: originPoint!.y + fontSize)
            let label = SKLabelNode()
            label.text = "+\(numNewBalls)"
            label.fontSize = fontSize
            label.fontName = fontName
            label.position = pos
            label.alpha = 0
            
            let vect = CGVector(dx: 0, dy: fontSize * 3)
            let action1 = SKAction.fadeIn(withDuration: 0.5)
            let action2 = SKAction.move(by: vect, duration: 1)
            let action3 = SKAction.fadeOut(withDuration: 0.5)
            scene!.addChild(label)
            label.run(action2)
            label.run(SKAction.sequence([action1, action3])) {
                self.scene!.removeChildren(in: [label])
            }
        }
        
        let array = newBallArray.filter {
            // Reset the ball's contact bitmasks and other things
            $0.resetBall()
            // Tell the ball to return to the origin point
            $0.returnToOrigin(point: originPoint!)
            // Add the new ball to the ball manager's array
            self.ballArray.append($0)
            // Update the label showing how many balls are collected at the origin point
            self.updateLabel()
            // This tells the filter to remove the ball from newBallArray
            return false
        }
        // Set the global newBallArray to an empty array now
        newBallArray = array
        
        // Update the number of balls the manager has
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
        // Update the ball name to avoid name collisions in the ball manager
        ball.getNode().name! = "ball\(ballArray.count + newBallArray.count)"
        ball.getNode().run(SKAction.move(to: atPoint, duration: 0.5))
    }
    
    public func shootBall() {
        let ball = ballArray[numBallsActive]
        ball.fire(point: direction!)
        numBallsActive += 1
        
        if numBallsActive == ballArray.count {
            // Increment state from SHOOTING to WAITING
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
                }
                print("Telling ball to stop at origin point \(originPoint!)")
                ball.stop(point: originPoint!)
            }
        }
        
        if isWaiting() {
            var numBallsDone = 0
            for ball in ballArray {
                if (false == ball.isActive) && (ball.isResting) {
                    numBallsDone += 1
                }
            }
            if numBallsDone == numBallsActive {
                incrementState()
                firstBallReturned = false
                numBallsActive = 0
                addLabel()
            }
        }
    }
    
    // MARK: Private functions
    private func addLabel() {
        var newPoint = CGPoint(x: originPoint!.x, y: (originPoint!.y + (ballRadius! * 1.5)))
        // This is to prevent the ball count label from going off the screen
        if let view = scene!.view {
            // If we're close to the far left side, add a small amount to the x value
            if newPoint.x < view.frame.width * 0.03 {
                newPoint.x += view.frame.width * 0.03
            }
            // Opposite of the above comment
            else if newPoint.x > view.frame.width * 0.97 {
                newPoint.x -= view.frame.width * 0.03
            }
        }
        labelNode!.position = newPoint
        labelNode!.fontSize = ballRadius! * 3
        labelNode!.fontName = fontName
        labelNode!.color = .white
        updateLabel()
        scene!.addChild(labelNode!)
    }
    
    private func updateLabel() {
        labelNode!.text = "x\(ballArray.count - numBallsActive)"
    }
    
    private func removeLabel() {
        scene!.removeChildren(in: [labelNode!])
    }
}
