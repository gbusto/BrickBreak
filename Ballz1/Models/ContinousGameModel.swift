//
//  ContinousGameModel.swift
//  Ballz1
//
//  The model for continous game play
//
//  Created by Gabriel Busto on 10/6/18.
//  Copyright © 2018 Self. All rights reserved.
//

import SpriteKit

class ContinuousGameModel {
    
    // MARK: Public properties
    public var gameScore = Int(0)
    public var highScore = Int(0)
    
    public var ballManager: BallManager?
    public var itemGenerator: ItemGenerator?
    
    // MARK: Private properties
    private var ceilingHeight: CGFloat?
    private var groundHeight: CGFloat?
    
    private var numberOfItems = Int(8)
    private var numberOfBalls = Int(10)
    
    private var state = Int(0)
    private var READY = Int(0)
    private var MID_TURN = Int(1)
    private var TURN_OVER = Int(2)
    
    // MARK: Initialization functions
    required init(view: SKView, blockSize: CGSize, ballRadius: CGFloat, ceilingHeight: CGFloat, groundHeight: CGFloat) {
        // State should always be initialized to READY
        state = TURN_OVER
        
        self.ceilingHeight = ceilingHeight
        self.groundHeight = groundHeight
        
        // I don't think ItemGenerator should have a clue about the view or ceiling height or any of that
        itemGenerator = ItemGenerator()
        itemGenerator!.initGenerator(blockSize: blockSize, ballRadius: ballRadius, numBalls: numberOfBalls, numItems: numberOfItems,
                                      ceiling: ceilingHeight, ground: groundHeight)
        
        ballManager = BallManager()
        ballManager!.initBallManager(generator: itemGenerator!, numBalls: numberOfBalls, radius: ballRadius)
    }
    
    // MARK: Public functions
    public func getBalls() -> [BallItem] {
        return ballManager!.ballArray
    }
    
    public func prepareTurn(point: CGPoint) {
        ballManager!.setDirection(point: point)
        // Change the ball manager's state from READY to SHOOTING
        ballManager!.incrementState()
        // Change our state from READY to MID_TURN
        incrementState()
    }
    
    public func shootBall() -> Bool {
        if ballManager!.isShooting() {
            ballManager!.shootBall()
            return true
        }
        
        return false
    }

    public func handleTurn() -> [Item] {
        // Check to see if the user collected any ball items so far
        let removedItems = itemGenerator!.removeItems()
        for item in removedItems {
            if item.getNode().name!.starts(with: "ball") {
                let ball = item as! BallItem
                ballManager!.addBall(ball: ball)
                print("Added ball \(ball.getNode().name!) to ball manager")
            }
        }
        
        // Check for inactive balls and stop them
        ballManager!.stopInactiveBalls()
        
        // Wait for the ball manager to finish
        if ballManager!.isDone() {
            // Increment state from MID_TURN to TURN_OVER
            incrementState()
            
            // Increment the ball manager's state from DONE to READY
            ballManager!.incrementState()
        }
        
        return removedItems
    }
    
    // Handles a turn ending; generate a new row, check for new balls, increment the score, etc
    public func handleTurnOver() {
        ballManager!.checkNewArray()
        
        gameScore += 1
        if gameScore >= highScore {
            highScore = gameScore
        }
        
        // Go from TURN_OVER state to READY state
        incrementState()
    }
    
    // MARK: Physics contact functions
    public func handleContact(nameA: String, nameB: String) {
        // This could be improved by renaming items based on who owns them
        // For example, items in ball manager start with bm; items in item generator start with ig
        if nameA.starts(with: "bm") {
            if "ground" == nameB {
                ballManager!.markBallInactive(name: nameA)
                print("Ball hit the ground")
            }
            else if nameB.starts(with: "block") {
                itemGenerator!.hit(name: nameB)
            }
            else if nameB.starts(with: "ball") {
                itemGenerator!.hit(name: nameB)
            }
        }
        
        if nameB.starts(with: "bm") {
            if "ground" == nameA {
                ballManager!.markBallInactive(name: nameB)
                print("Ball hit the ground")
            }
            else if nameA.starts(with: "block") {
                itemGenerator!.hit(name: nameA)
            }
            else if nameA.starts(with: "ball") {
                itemGenerator!.hit(name: nameA)
            }
        }
    }
    
    public func generateRow() -> [Item] {
        return itemGenerator!.generateRow()
    }
    
    public func animateItems(action: SKAction) {
        itemGenerator!.animateItems(action)
    }
    
    // The floor of the game scene; if another row doesn't fit
    public func gameOver(floor: CGFloat, rowHeight: CGFloat) -> Bool {
        return itemGenerator!.canAddRow(floor, rowHeight)
    }
    
    public func incrementState() {
        if TURN_OVER == state {
            state = READY
            return
        }
        
        state += 1
    }
    
    public func isReady() -> Bool {
        // State when ball manager and item generator are ready
        return (READY == state)
    }
    
    public func isMidTurn() -> Bool {
        // This state is when ball manager is in SHOOTING || WAITING state
        return (MID_TURN == state)
    }
    
    public func isTurnOver() -> Bool {
        return (TURN_OVER == state)
    }
}
