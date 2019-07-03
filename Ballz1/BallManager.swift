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
    public var ballArray: [BallItem] = []
    
    // MARK: Private properties
    private var ballRadius: CGFloat?
    // Balls that have just been added from the ItemGenerator
    private var newBallArray: [BallItem] = []
    
    // This isn't ideal because it shouldn't be aware of any view attributes
    private var groundHeight = CGFloat(0)
    
    private var firstBallReturned = false
    
    private var numBallsActive = 0
    
    private var originPoint: CGPoint?
    
    private var bmState: DataManager.BallManagerState?
    static let BallManagerPath = "BallManager"
    
    private var prevTurnState = DataManager.BallManagerState(numberOfBalls: 0, originPoint: CGPoint(x: 0, y: 0))
    
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
    
    private var ballsOnFire = false
    
    private var swipedDown = false
    
    private var stoppedBalls: [BallItem] = []
    
    
    // MARK: State handling code
    
    public func saveTurnState() {
        // Save the ball manager's turn state
        prevTurnState.numberOfBalls = numberOfBalls
        prevTurnState.originPoint = originPoint!
    }
    
    public func loadTurnState() -> Bool {
        if prevTurnState.numberOfBalls == 0 {
            return false
        }
        
        // Remove any new balls from the ball array
        let diff = numberOfBalls - prevTurnState.numberOfBalls
        if diff > 0 {
            for _ in 0...(diff - 1) {
                let _ = ballArray.popLast()
            }
        }
        
        // Load the ball manager's turn state
        numberOfBalls = prevTurnState.numberOfBalls
        originPoint! = prevTurnState.originPoint!
        
        // Reset the values so we don't try to reload the turn state again
        prevTurnState.numberOfBalls = 0
        prevTurnState.originPoint = CGPoint(x: 0, y: 0)
        
        return true
    }
    
    public func setBallsOnFire() {
        // Sets the balls on fire
        ballsOnFire = true
        for ball in ballArray {
            if false == ball.isResting {
                ball.setOnFire()
            }
        }
    }
    
    
    // MARK: Public functions
    required init(numBalls: Int, radius: CGFloat) {
        // XXX It shouldn't need to know ball radius... that should be something only the view knows
        ballRadius = radius
        
        bmState = DataManager.BallManagerState(numberOfBalls: numBalls, originPoint: nil)

        numberOfBalls = bmState!.numberOfBalls
        originPoint = bmState!.originPoint
        
        for i in 1...numberOfBalls {
            let ball = BallItem()
            let size = CGSize(width: radius, height: radius)
            ball.initItem(num: i, size: size)
            ball.getNode().name! = "bm\(i)"
            ballArray.append(ball)
        }

        state = READY
    }
    
    required init() {
        // Empty constructor
    }
    
    // XXX This class shouldn't be aware of groundHeight! Only the view should
    public func setGroundHeight(height: CGFloat) {
        groundHeight = height
    }
    
    public func incrementState() {
        if DONE == state {
            state = READY
            // Reset this boolean to false
            ballsOnFire = false
            // Reset this boolean letting the shootBalls() function know whether or not the user swiped down and we should stop shooting
            swipedDown = false
            return
        }
        
        state += 1
    }
    
    /*  XXX
        Maybe rewrite this function to accept an array as the parameter for easier testing?
        Also, maybe separate the visual logic of moving the balls to the origin point into the view.
        I think it'll make testing easier if I separate all the logic that does anything visually into the view file and keep all of this other logic as non-view. I think it'll make everything more testable and then I can even run through game scenarios more quickly than if I needed to have the game view up.
    */
    public func checkNewArray() {
        let array = newBallArray.filter {
            // Tell the ball to return to the origin point and reset its physics bitmasks
            $0.stop()
            $0.moveBallTo(originPoint!)
            // Add the new ball to the ball manager's array
            self.ballArray.append($0)
            // This tells the filter to remove the ball from newBallArray
            return false
        }
        // Set the global newBallArray to an empty array now
        newBallArray = array
        
        // Update the number of balls the manager has
        numberOfBalls = ballArray.count
    }
    
    // XXX Is this necessary?
    public func setOriginPoint(point: CGPoint) {
        originPoint = point
    }
    
    // XXX Write a unit test for this. This may have/introduce bugs; it seems kind of weird
    public func getOriginPoint() -> CGPoint {
        if let op = originPoint {
            return op
        }
        originPoint = ballArray[0].getNode().position
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
    
    // XXX Is this necessary?
    public func setDirection(point: CGPoint) {
        direction = point
    }
    
    // XXX Could this be rewritten or added to something else?
    public func addBall(ball: BallItem) {
        newBallArray.append(ball)
        // Update the ball name to avoid name collisions in the ball manager
        ball.getNode().name! = "bm\(ballArray.count + newBallArray.count)"
    }
    
    public func numRestingBalls() -> Int {
        return numberOfBalls - numBallsActive
    }
    
    public func shootBall() {
        let ball = ballArray[numBallsActive]
        ball.fire(point: direction!)
        if ballsOnFire {
            // If balls are already on fire then this ball needs to be on fire too
            ball.setOnFire()
        }
        numBallsActive += 1
    }
    
    /*  XXX
        Based on my comment above, I think this is visual logic that should maybe be moved into the view? It originally was then I moved it into the BallManager file.
    */
    public func shootBalls() {
        // Make sure that before we start shooting balls there aren't any lingering in this list
        /*
            There was a weird bug after refactoring BallManager: the game scene (ContinuousGameScene) would place balls from the
            ball manager on the ground (which the game would record as a collision) and the chain of events would fire and all
            balls in the BallManager's list would end up in the stoppedBalls list. When firing balls for the first time, it would
            process that list (in handleStoppedBalls) and tell them to stop and return to their origin point.
            This fixes that bug by ensuring that the stoppedBalls list is empty when starting to shoot balls.
        */
        stoppedBalls = []
        let _ = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            // Check to see if the user swiped down while we were still shooting; we need to stop shooting if they did
            if self.allBallsFired() || self.swipedDown {
                timer.invalidate()
                // Increment state from SHOOTING to WAITING
                self.incrementState()
            }
            else {
                self.shootBall()
            }
        }
    }
    
    private func allBallsFired() -> Bool {
        return (false == ballArray[numberOfBalls - 1].isResting)
    }
    
    /*  XXX
        Also contains some logic for the visual part of the game... might move it back into the view file.
    */
    public func returnAllBalls() {
        if false == firstBallReturned {
            firstBallReturned = true
        }
        
        swipedDown = true
        
        for ball in ballArray {
            ball.getNode().physicsBody!.collisionBitMask = 0
            ball.getNode().physicsBody!.categoryBitMask = 0
            ball.getNode().physicsBody!.contactTestBitMask = 0
            ball.stop()
            ball.moveBallTo(originPoint!)
        }
        
        // shootBalls() will increment the ball manager's state if it's shooting
    }
    
    public func markBallInactive(name: String) {
        for ball in ballArray {
            if ball.node!.name == name {
                stoppedBalls.append(ball)
                ball.stop()
            }
        }
    }
    
    // This function should be called in the model's MID_TURN state
    // XXX This function seems like it's kind of doing a lot... maybe some of this should be broken up and the .moveBallTo() should be back in the view.
    // XXX I definitely think that only the view should move items around and determine where to move them to, then tell the BallManager where it moved them to (i.e. the originPoint)
    // The view should be responsible for enforcing that the balls actually land and stay on the ground, not the BallManager
    public func handleStoppedBalls() {
        if stoppedBalls.count > 0 {
            // Pop this ball off the front of thel ist
            let ball = stoppedBalls.removeFirst()
            //ball.stop() // REMOVE ME
            if false == firstBallReturned {
                // The first ball hasn't been returned yet
                firstBallReturned = true
                var ballPosition = ball.node!.position
                if ballPosition.y > groundHeight {
                    // Ensure the ball is on the ground and not above it
                    ballPosition.y = groundHeight
                }
                originPoint = ball.node!.position
            }
            ball.moveBallTo(originPoint!)
        }
    }
    
    // This function should be called in the model's
    // XXX I should also rewrite this to make it easier to unit test.
    public func waitForBalls() {
        var activeBallInPlay = false
        for ball in ballArray {
            if false == ball.isResting {
                activeBallInPlay = true
                break
            }
        }
        if false == activeBallInPlay {
            // Increment state from WAITING to DONE
            incrementState()
            firstBallReturned = false
            numBallsActive = 0
            // Done waiting for balls
        }
        // Still waiting for balls
    }
}
