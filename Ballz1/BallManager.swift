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
    
    private var firstBallReturned = false
    
    private var numBallsActive = 0
    
    private var originPoint: CGPoint?
    
    private var bmState: BallManagerState?
    static let BallManagerPath = "BallManager"
    
    private var prevTurnState = BallManagerState(numberOfBalls: 0, originPoint: CGPoint(x: 0, y: 0))
    
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
    
    
    // MARK: State handling code
    struct BallManagerState: Codable {
        var numberOfBalls: Int
        var originPoint: CGPoint?
        
        enum CodingKeys: String, CodingKey {
            case numberOfBalls
            case originPoint
        }
    }
    
    public func saveState(restorationURL: URL) {
        let url = restorationURL.appendingPathComponent(BallManager.BallManagerPath)
        
        do {
            // Update the ball manager's state before we save it
            bmState!.numberOfBalls = numberOfBalls
            bmState!.originPoint = originPoint
            
            let data = try PropertyListEncoder().encode(self.bmState!)
            try data.write(to: url)
            print("Saved ball manager state")
        }
        catch {
            print("Error saving ball manager state: \(error)")
        }
    }
    
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
    
    public func loadState(restorationURL: URL) -> Bool {
        do {
            let data = try Data(contentsOf: restorationURL)
            bmState = try PropertyListDecoder().decode(BallManagerState.self, from: data)
            print("Loaded ball manager state")
            return true
        }
        catch {
            print("Error loading ball manager state: \(error)")
            return false
        }
    }
    
    
    // MARK: Public functions
    required init(numBalls: Int, radius: CGFloat, restorationURL: URL) {
        ballRadius = radius
        
        let url = restorationURL.appendingPathComponent(BallManager.BallManagerPath)
        if false == loadState(restorationURL: url) {
            bmState = BallManagerState(numberOfBalls: numBalls, originPoint: nil)
        }

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
    
    public func incrementState() {
        if DONE == state {
            state = READY
            return
        }
        
        state += 1
    }
    
    public func checkNewArray() {
        let array = newBallArray.filter {
            // Tell the ball to return to the origin point and reset its physics bitmasks
            $0.stop(point: originPoint!)
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
    
    public func setOriginPoint(point: CGPoint) {
        originPoint = point
    }
    
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
    
    public func setDirection(point: CGPoint) {
        direction = point
    }
    
    public func addBall(ball: BallItem) {//, atPoint: CGPoint) {
        newBallArray.append(ball)
        // Update the ball name to avoid name collisions in the ball manager
        ball.getNode().name! = "bm\(ballArray.count + newBallArray.count)"
    }
    
    public func shootBall() {
        let ball = ballArray[numBallsActive]
        ball.fire(point: direction!)
        numBallsActive += 1
        
        if numBallsActive == ballArray.count {
            // Increment state from SHOOTING to WAITING
            incrementState()
        }
    }
    
    public func returnAllBalls() {
        if false == firstBallReturned {
            firstBallReturned = true
        }
        
        for ball in ballArray {
            ball.isActive = false
            ball.getNode().physicsBody!.collisionBitMask = 0
            ball.getNode().physicsBody!.categoryBitMask = 0
            ball.getNode().physicsBody!.contactTestBitMask = 0
            ball.stop(point: originPoint!)
        }
        
        // Set numBallsActivet to the array size so that in stopInactiveBalls() the code will change state from WAITING to DONE
        numBallsActive = ballArray.count
        
        if isShooting() {
            // Only change our state if we're in SHOOTING state to the WAITING state
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
                // Increment state from WAITING to DONE
                incrementState()
                firstBallReturned = false
                numBallsActive = 0
            }
        }
    }
}
