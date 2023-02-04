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

enum ContinuousGameState {
    case gameStateReady
    case gameStateMidTurn
    case gameStateTurnOver
    case gameStateWaiting
    case gameStateGameOver
}

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
    
    private var state: ContinuousGameState = .gameStateReady
    
    var dataManager: DataManager = DataManager.shared
    
    /*
     Main things for which this class should be responsible:
     - Managing the full model, including number of balls, items, rows, etc
     - The ItemGenerator for this instance
     - Previous turn data for undo
     - User saved boolean
     
     "state" should be moved OUT of the model, and into the ViewController for this model.
     */
    
    // MARK: State handling code

    /*
     Saves the full game state so it can be retrieved later.
     Accesses current state to prevent cheating.
     Accesses the high score to save that.
     If the current state is "GAME_OVER", then clear the saved data
     Try to save the data
     Save the item generator's state
     4 different data save functions:
     - One to save the high score and whether or not the player was shown the tutorials
     - One to save the game state (i.e. current game score and whether the user was saved)
     - One to save the ball state (i.e. number of balls and their current origin point)
     - Then tell the ItemGenerator to save its state
     */
    // Improvement: Maybe all game state should be able to be loaded at once; it’s weird that high score, game score, item generator, etc all load separately. What happens if one can load but not the others?
    public func saveState(numberOfBalls: Int, originPoint: CGPoint) {
        // If we're in the middle of a turn, we don't want to save the state. Users could exploit this to cheat
        if isReady() || isGameOver() {
            // Handle saving off persistent game data
            // XXX Look into this logic to make sure this is correct.. doesn't seem right unless we do a check somewhere else in the code to update the user's high score accordingly
            if persistentData!.highScore != highScore {
                persistentData!.highScore = highScore
            }
            dataManager.saveClassicPersistentData(highScore: persistentData!.highScore, showedTutorials: persistentData!.showedTutorials)
            
            // Handle saving off game state
            if .gameStateGameOver == state {
                // If it's a game over, clear the game state so we start fresh next time
                // Don't save any of this stuff after a game over
                dataManager.clearClassicGameState()
                return
            }
            
            dataManager.saveClassicGameState(gameScore: gameScore, userWasSaved: userWasSaved)
            
            // Save off the ball manager state
            // XXX NEEDS WORK
            if false == dataManager.saveClassicBallState(numberOfBalls: numberOfBalls, originPoint: originPoint) {
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
    /* PURPOSE: inits the model
        Sets "state" to WAITING
        Attempts to load high score and tutorials boolean
        Attempts to load game score and whether or not the user was saved
        Sets variables with all that info:
        - highScore
        - showedTutorials
        - gameScore
        - userWasSaved
     */
    // All saved state should be loaded at once; it makes no sense for some saved session data to be able to load when other saved data fails to load
    // High score and tutorials can be saved and loaded separately
    required init(numberOfRows: Int) {
        state = .gameStateWaiting
        
        // Try to load persistent data
        persistentData = dataManager.loadClassicPeristentData()
        if nil == persistentData {
            // Defaults to load highScore of 0
            persistentData = dataManager.createClassicPersistentData(highScore: highScore, showedTutorials: showedTutorials)
        }
        
        // Try to load game state
        gameState = dataManager.loadClassicGameState()
        if nil == gameState {
            // Defaults to loading gameScore of 0
            gameState = dataManager.createClassicGameState(gameScore: gameScore, userWasSaved: userWasSaved)
        }
        
        // If the load works correctly, these will be initialized to their saved values. Otherwise they'll be loaded to their default values of 0
        highScore = persistentData!.highScore
        showedTutorials = persistentData!.showedTutorials
        gameScore = gameState!.gameScore
        userWasSaved = gameState!.userWasSaved
        self.numberOfRows = numberOfRows
    }
    
    /* PURPOSE: Initializes the item generator with objects and positions; called in ContinuousGameScene
        Attempt to load the item generator's state
        Setup the ItemGenerator with loaded state if any (Optional)
        Modifies "state" variable; probably shouldn't do this
     */
    // This function should not modify game state, leave that responsibility to another function
    public func initItemGenerator(blockSize: CGSize, ballRadius: CGFloat) {
        // I don't think ItemGenerator should have a clue about the view or ceiling height or any of that
        let igState = dataManager.loadClassicItemGeneratorState()
        itemGenerator = ItemGenerator(blockSize: blockSize, ballRadius: ballRadius,
                                      numberOfRows: numberOfRows,
                                      numItems: numberOfItems,
                                      state: igState)
        if 0 == itemGenerator!.itemArray.count {
            state = .gameStateTurnOver
        }
    }
    
    // MARK: Public functions
    
    /* PURPOSE: called when the user wants to "undo"; returns state to what it was previously
        Returns "true" if it was able to load the previous state, "false" otherwise
        Asks itemGenerator to load the previous turn state? If that fails, we return "false"
        Undo high score and game score (by substracting one)
        Marks "prevTurnSaved" as false because we just undid a turn, and you can only undo one turn at a time
        Updates "state" to WAITING which is the state before the user makes a move
     */
    // There should be some game state struct from which the previous turn is loaded
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
            state = .gameStateWaiting
            
            return true
        }
        
        return false
    }
    
    // MARK: - Helper functions to prevent ContinuousGameScene from depending directly on the model's ItemGenerator instance
    
    // Helper functions for LevelsGameScene to prevent it from directly accessing the ItemGenerator
    public func getItemCount() -> Int {
        if let ig = itemGenerator {
            return ig.getItemCount()
        }
        
        return 0
    }
    
    public func getItem2DArray() -> [[Item]] {
        if let ig = itemGenerator {
            return ig.itemArray
        }
        
        return []
    }
    
    public func pruneFirstRowOfItems() {
        if let ig = itemGenerator {
            ig.pruneFirstRow()
        }
    }
    
    public func updateBallCount(count: Int) {
        if let ig = itemGenerator {
            ig.updateBallCount(count: count)
        }
    }

    
    /* PURPOSE: handle actions once the user starts their next turn
        Saves the item generator's turn state
        Sets "prevTurnSaved" to true
        Moves state to the next value (incrementState)
     */
    // The way incrementState is being used I think should be changed... or it will change how and where it should be called
    public func prepareTurn(point: CGPoint) {
        // Save the item generator's turn state as soon as the user starts the next turn
        itemGenerator!.saveTurnState()
        
        // Reset this to true since we saved state
        prevTurnSaved = true
        
        // Change our state from READY to MID_TURN
        incrementState()
    }

    /* PURPOSE: Called after the user watches an ad to save them (tells item generator to remove the bottom 3 rows if necessary)
        Updates "state" to READY
        Updates "userWasSaved" to true
        Tells ItemGenerator to save the user
     */
    public func saveUser() -> [Item] {
        state = .gameStateReady
        userWasSaved = true
        return itemGenerator!.saveUser()
    }

    /*
     Unclear on what this does exactly... removeItems removes items from the generator, but after the turn ends?
     */
    public func handleTurn() -> [(Item, Int, Int)] {
        // Check to see if the user collected any ball items so far
        let removedItems = itemGenerator!.removeItems()
        
        // XXX NEEDS WORK; need to figure out how to increment our state from MID_TURN to TURN_OVER
        // This happens in isMidTurn in main update loop for scene
        
        return removedItems
    }
    
    /* PURPOSE: Handle actions after a turn ends
     Increment game score
     Update high score if necessary
     Increment the game state to the next state
     Reset the "on fire bonus" in the ItemGenerator
     */
    // Maybe actions for each state should be encapsulated in a single function
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
    /* PURPOSE: Handles logic for when contact is made
     Figure out which item in the contact was not the game ball, and then tell the ItemGenerator that that object was hit
     */
    // This seems okay for now...
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
            // Look into why we don't need to do anything here
        }
    }
    
    /*
     Enables the "on fire bonus"
     */
    // Maybe the ItemGenerator can be made aware via another mechanism for when to enable this?
    public func addOnFireBonus() {
        itemGenerator!.setOnFireBonus(true)
    }
    
    /* PURPOSE: Generates a new row
     The ItemGenerator should handle the logic in this function; all it needs to know is WHEN to generate a new row
     */
    // The logic from this function show be moved into ItemGenerator class
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
    
    /*
     Calculates the loss risk; this function returns "true" if the user is close to losing, "false" otherwise
     */
    // Item array count and number of rows could be passed into here to make this more easily testable
    public func lossRisk() -> Bool {
        return (itemGenerator!.itemArray.count == numberOfRows - 2)
    }
    
    /*
     Determines if the game is over; returns "true" if it's over, "false" otherwise
     */
    // The floor of the game scene; if another row doesn't fit
    // Functions like this that are meant to check something shouldn't also update something like game state
    public func gameOver() -> Bool {
        if (itemGenerator!.itemArray.count == numberOfRows - 1) {
            state = .gameStateGameOver
            return true
        }
        return false
    }
    
    /*
     Increments the game state to the next state
     */
    // This needs to be improved
    public func incrementState() {
        if .gameStateWaiting == state {
            state = .gameStateReady
            // Don't need to save state after each turn
            return
        }
        else if .gameStateGameOver == state {
            // Don't change state after the game is over
            return
        }

        switch state {
        case .gameStateReady:
            state = .gameStateMidTurn
        case .gameStateMidTurn:
            state = .gameStateTurnOver
        case .gameStateTurnOver:
            state = .gameStateWaiting
        default:
            break
        }
    }
    
    // All functions below this comment can be removed and we can check another way
    public func isReady() -> Bool {
        // State when ball manager and item generator are ready
        return (.gameStateReady == state)
    }
    
    public func isMidTurn() -> Bool {
        // This state is when ball manager is in SHOOTING || WAITING state
        return (.gameStateMidTurn == state)
    }
    
    public func isTurnOver() -> Bool {
        return (.gameStateTurnOver == state)
    }
    
    public func isWaiting() -> Bool {
        return (.gameStateWaiting == state)
    }
    
    public func isGameOver() -> Bool {
        return (.gameStateGameOver == state)
    }
}
