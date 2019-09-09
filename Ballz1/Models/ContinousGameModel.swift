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
    
    public var itemGenerator: ItemGenerator?
    
    public var userWasSaved = false
    
    // False when there is no previous turn data saved; true otherwise
    public var prevTurnSaved = false
    
    public var showedTutorials = false
    
    // MARK: Private properties
    private var persistentData: DataManager.ClassicPersistentData?
    private var gameState: DataManager.ClassicGameState?
    
    private var numberOfItems = Int(8)
    private var numberOfBalls = Int(10)
    private var numberOfRows = Int(0)
    
    private var state = Int(0)
    // READY means the game model is ready to go
    private var READY = Int(0)
    // MID_TURN means it's in the middle of processing a user's turn and waiting for the balls to return and items to be collected
    private var MID_TURN = Int(1)
    // TURN_OVER means the turn ended; this gives the View some time to process everything and perform any end of turn actions
    private var TURN_OVER = Int(2)
    // WAITING means the game model is waiting for item animations to finish (i.e. the view tells the items to shift down one row while in the TURN_OVER state, so we remain in this state until all animations are finished)
    private var WAITING = Int(3)
    
    private var GAME_OVER = Int(255)
    
    // MARK: State handling code

    
    public func saveState(numberOfBalls: Int, originPoint: CGPoint) {
        // If we're in the middle of a turn, we don't want to save the state. Users could exploit this to cheat
        if isReady() || isGameOver() {
            // Handle saving off persistent game data
            // XXX Look into this logic to make sure this is correct.. doesn't seem right unless we do a check somewhere else in the code to update the user's high score accordingly
            if persistentData!.highScore != highScore {
                persistentData!.highScore = highScore
            }
            DataManager.shared.saveClassicPersistentData(highScore: persistentData!.highScore, showedTutorials: persistentData!.showedTutorials)
            
            // Handle saving off game state
            if GAME_OVER == state {
                // If it's a game over, clear the game state so we start fresh next time
                // Don't save any of this stuff after a game over
                DataManager.shared.clearClassicGameState()
                return
            }
            
            DataManager.shared.saveClassicGameState(gameScore: gameScore, userWasSaved: userWasSaved)
            
            // Save off the ball manager state
            // XXX NEEDS WORK
            if false == DataManager.shared.saveClassicBallState(numberOfBalls: numberOfBalls, originPoint: originPoint) {
                print("Failed to save ball manager state for classic mode!")
            }
            else {
                print("Successfully saved ball manager state for classic mode!")
            }
            
            // Save off item generator state
            itemGenerator!.saveState()
        }
    }
    
    // MARK: Initialization functions
    required init(numberOfRows: Int) {
        state = WAITING
        
        // Try to load persistent data
        persistentData = DataManager.shared.loadClassicPeristentData()
        if nil == persistentData {
            // Defaults to load highScore of 0
            persistentData = DataManager.ClassicPersistentData(highScore: highScore, showedTutorials: showedTutorials)
        }
        
        // Try to load game state
        gameState = DataManager.shared.loadClassicGameState()
        if nil == gameState {
            // Defaults to loading gameScore of 0
            gameState = DataManager.ClassicGameState(gameScore: gameScore, userWasSaved: userWasSaved)
        }
        
        // If the load works correctly, these will be initialized to their saved values. Otherwise they'll be loaded to their default values of 0
        highScore = persistentData!.highScore
        showedTutorials = persistentData!.showedTutorials
        gameScore = gameState!.gameScore
        userWasSaved = gameState!.userWasSaved
        self.numberOfRows = numberOfRows
    }
    
    public func initItemGenerator(blockSize: CGSize, ballRadius: CGFloat) {
        // I don't think ItemGenerator should have a clue about the view or ceiling height or any of that
        let igState = DataManager.shared.loadClassicItemGeneratorState()
        itemGenerator = ItemGenerator(blockSize: blockSize, ballRadius: ballRadius,
                                      numberOfRows: numberOfRows,
                                      numItems: numberOfItems,
                                      state: igState)
        if 0 == itemGenerator!.itemArray.count {
            state = TURN_OVER
        }
    }
    
    // MARK: Public functions
    
    // Load the previous turn state
    // XXX NEEDS WORK
    // XXX TEST
    public func loadPreviousTurnState() -> Bool {
        if prevTurnSaved {
            if false == itemGenerator!.loadTurnState() {
                return false
            }
            
            // Undo the scores
            if highScore == gameScore {
                highScore -= 1
            }
            gameScore -= 1
            
            // We need to set this to false to avoid loading old turn state
            prevTurnSaved = false
            
            // Set state to waiting so the game checks to see whether or not to warn the user or end the game
            state = WAITING
            
            return true
        }
        
        return false
    }
    
    public func prepareTurn(point: CGPoint) {
        // Save the item generator's turn state as soon as the user starts the next turn
        itemGenerator!.saveTurnState()
        
        // Reset this to true since we saved state
        prevTurnSaved = true
        
        // Change our state from READY to MID_TURN
        incrementState()
    }

    public func saveUser() -> [Item] {
        state = READY
        userWasSaved = true
        return itemGenerator!.saveUser()
    }

    public func handleTurn() -> [(Item, Int, Int)] {
        // Check to see if the user collected any ball items so far
        let removedItems = itemGenerator!.removeItems()
        
        // XXX NEEDS WORK; need to figure out how to increment our state from MID_TURN to TURN_OVER
        // This happens in isMidTurn in main update loop for scene
        
        return removedItems
    }
    
    // Handles a turn ending; generate a new row, check for new balls, increment the score, etc
    public func handleTurnOver() {
        gameScore += 1
        if gameScore >= highScore {
            highScore = gameScore
        }
        
        // Go from TURN_OVER state to WAITING state
        incrementState()
        
        // Reset the x2 ball hit flag
        itemGenerator!.setOnFireBonus(false)
    }
    
    // MARK: Physics contact functions
    public func handleContact(nameA: String, nameB: String) {
        // XXX NEEDS WORK
        // Items that start with the name bm are ball manager balls. They are named differently from the other items so we can quickly check if a ball manager ball is interacting with an item from the item generator
        // Add any extra cases in here if they need special attention
        var item = ""
        if nameA.starts(with: "bm") {
            item = nameB
        }
        else {
            item = nameA
        }
        
        if itemGenerator!.hit(name: item) {
            // Pass; don't need to do anything here
        }
    }
    
    public func addOnFireBonus() {
        itemGenerator!.setOnFireBonus(true)
    }
    
    public func generateRow() -> [Item] {
        let count = itemGenerator!.getBlockCount()
        // If the user is doing well and there are no items on the screen, generate a harder pattern
        if count <= 6 {
            itemGenerator!.easyPatternPercent = 10
            itemGenerator!.intermediatePatternPercent = 30
            itemGenerator!.hardPatternPercent = 60
        }
        // If they have <= 6 items on the screen, increase the difficult of getting a harder pattern
        else if (count > 6) && (count <= 12) {
            itemGenerator!.easyPatternPercent = 20
            itemGenerator!.intermediatePatternPercent = 40
            itemGenerator!.hardPatternPercent = 40
        }
        // Otherwise reset the pattern difficulty distribution back to defaults
        else {
            itemGenerator!.resetDifficulty()
        }
        return itemGenerator!.generateRow()
    }
    
    public func lossRisk() -> Bool {
        return (itemGenerator!.itemArray.count == numberOfRows - 2)
    }
    
    // The floor of the game scene; if another row doesn't fit
    public func gameOver() -> Bool {
        if (itemGenerator!.itemArray.count == numberOfRows - 1) {
            state = GAME_OVER
            return true
        }
        return false
    }
    
    public func incrementState() {
        if WAITING == state {
            state = READY
            // Don't need to save state after each turn
            return
        }
        else if GAME_OVER == state {
            // Don't change state after the game is over
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
    
    public func isWaiting() -> Bool {
        return (WAITING == state)
    }
    
    public func isGameOver() -> Bool {
        return (GAME_OVER == state)
    }
}
