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
    // TODO: Remove the global reference for this
    private var radius = CGFloat(0)
    
    private var ceilingHeight: CGFloat?
    private var groundHeight: CGFloat?
    
    private var numberOfItems = Int(8)
    private var numberOfBalls = Int(10)
    
    private var state = Int(0)
    private var READY = Int(0)
    private var MID_TURN = Int(1)
    private var TURN_OVER = Int(2)
    
    // MARK: Initialization functions
    required init(scene: SKScene, view: SKView, ceilingHeight: CGFloat, groundHeight: CGFloat) {
        // State should always be initialized to READY
        state = TURN_OVER
        
        self.ceilingHeight = ceilingHeight
        self.groundHeight = groundHeight
        
        // I don't think ItemGenerator should have a clue about the view or ceiling height or any of that
        itemGenerator = ItemGenerator()
        itemGenerator!.initGenerator(scene: scene, view: view, numBalls: numberOfBalls, numItems: numberOfItems,
                                      ceiling: ceilingHeight, ground: groundHeight)
        
        // BallManager shouldn't display the balls; that's the view's job. Also, ball manager doesn't need an instance of the item generator
        // TODO: (Read above)
        radius = CGFloat(view.frame.width * 0.018)
        let position = CGPoint(x: view.frame.midX, y: groundHeight + radius)
        ballManager = BallManager()
        ballManager!.initBallManager(scene: scene, generator: itemGenerator!, numBalls: numberOfBalls, position: position, radius: radius)
        // TODO: I think this code should be in the view, not in the model
        ballManager!.addBalls()
    }
    
    // MARK: Public functions
    public func incrementState() {
        if TURN_OVER == state {
            state = READY
            return
        }
        
        state += 1
    }
    
    public func prepareTurn(point: CGPoint) {
        ballManager!.setDirection(point: point)
        // Change the ball manager's state from READY to SHOOTING
        ballManager!.incrementState()
        // Change our state from READY to MID_TURN
        incrementState()
    }

    public func handleTurn(shootBall: Bool) {
        if shootBall && ballManager!.isShooting() {
            ballManager!.shootBall()
        }
        
        // Check to see if the user collected any ball items so far
        let removedItems = itemGenerator!.removeItems()
        for item in removedItems {
            if item.getNode().name!.starts(with: "ball") {
                let ball = item as! BallItem
                let newPoint = CGPoint(x: ball.getNode().position.x, y: groundHeight! + radius)
                ballManager!.addBall(ball: ball, atPoint: newPoint)
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
    }
    
    // MARK: Physics contact functions
    public func handleContact(nameA: String, nameB: String) {
        // This could be improved by renaming items based on who owns them
        // For example, items in ball manager start with bm; items in item generator start with ig
        if nameA.starts(with: "ball") {
            if "ground" == nameB {
                ballManager!.markBallInactive(name: nameA)
            }
            else if nameB.starts(with: "block") {
                itemGenerator!.hit(name: nameB)
            }
            else if nameB.starts(with: "ball") {
                itemGenerator!.hit(name: nameB)
            }
        }
        
        if nameB.starts(with: "ball") {
            if "ground" == nameA {
                ballManager!.markBallInactive(name: nameB)
            }
            else if nameA.starts(with: "block") {
                itemGenerator!.hit(name: nameA)
            }
            else if nameA.starts(with: "ball") {
                itemGenerator!.hit(name: nameA)
            }
        }
    }
    
    // Handles a turn ending; generate a new row, check for new balls, increment the score, etc
    public func handleTurnOver() {
        ballManager!.checkNewArray()
        itemGenerator!.generateRow()
        
        gameScore += 1
        if gameScore >= highScore {
            highScore = gameScore
        }
        // Go from TURN_OVER state to READY state
        incrementState()
    }
    
    public func gameOver() -> Bool {
        return itemGenerator!.canAddRow(groundHeight: groundHeight!)
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
