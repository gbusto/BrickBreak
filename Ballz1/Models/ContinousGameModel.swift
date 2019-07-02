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
    
    public var userWasSaved = false
    
    // False when there is no previous turn data saved; true otherwise
    public var prevTurnSaved = false
    
    public var showedTutorials = false
    
    // MARK: Private properties
    private var persistentData: PersistentData?
    private var gameState: GameState?
    
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
    
    // For storing data
    static let AppDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    // This is the main app directory
    static let AppDirURL = AppDirectory.appendingPathComponent("BB")
    // This is persistent data that will contain the high score
    static let PersistentDataURL = AppDirURL.appendingPathComponent("PersistentData")
    // The directory to store game state for this game type
    static let ContinuousDirURL = AppDirURL.appendingPathComponent("ContinuousDir")
    // The path where game state is stored for this game mode
    static let GameStateURL = ContinuousDirURL.appendingPathComponent("GameState")
    
    
    // MARK: State handling code
    // This struct is used for managing persistent data (such as your overall high score, what level you're on, etc)
    struct PersistentData: Codable {
        var highScore: Int
        var showedTutorials: Bool
        
        // This serves as the authoritative list of properties that must be included when instances of a codable type are encoded or decoded
        // Read Apple's documentation on CodingKey protocol and Codable
        enum CodingKeys: String, CodingKey {
            case highScore
            case showedTutorials
        }
    }
    
    // This struct is used for managing any state from this class that is required to save the user's place
    struct GameState: Codable {
        var gameScore: Int
        var userWasSaved: Bool
        
        enum CodingKeys: String, CodingKey {
            case gameScore
            case userWasSaved
        }
    }
    
    public func saveState() {
        // If we're in the middle of a turn, we don't want to save the state. Users could exploit this to cheat
        if isReady() || isGameOver() {
            savePersistentState()
            saveGameState()
        }
    }
    
    public func savePersistentState() {
        do {
            // Create the App directory Documents/BB
            if false == FileManager.default.fileExists(atPath: ContinuousGameModel.AppDirURL.path) {
                try FileManager.default.createDirectory(at: ContinuousGameModel.AppDirURL, withIntermediateDirectories: true, attributes: nil)
            }
            
            // Check if the user beat their high score; if they did then save it
            if persistentData!.highScore != highScore {
                persistentData!.highScore = highScore
            }
            
            // Save state to know if user was shown tutorial
            persistentData!.showedTutorials = showedTutorials
            
            // Save the persistent data
            let pData = try PropertyListEncoder().encode(self.persistentData!)
            try pData.write(to: ContinuousGameModel.PersistentDataURL, options: .completeFileProtectionUnlessOpen)
        }
        catch {
            print("Error saving persistent state: \(error)")
        }
    }
    
    public func saveGameState() {
        do {
            // If it's a game over, clear the game state so we start fresh next time
            if GAME_OVER == state {
                clearGameState()
                return
            }
            
            // Don't save any of this stuff after a game over

            // Create the directory for this game mode (Documents/BB/ContinuousDir)
            if false == FileManager.default.fileExists(atPath: ContinuousGameModel.ContinuousDirURL.path) {
                try FileManager.default.createDirectory(at: ContinuousGameModel.ContinuousDirURL, withIntermediateDirectories: true, attributes: nil)
            }
            
            // Save game state stuff (right now it's just the current game score)
            gameState!.gameScore = gameScore
            gameState!.userWasSaved = userWasSaved
            
            // Save the game state
            let gameData = try PropertyListEncoder().encode(self.gameState!)
            try gameData.write(to: ContinuousGameModel.GameStateURL, options: .completeFileProtectionUnlessOpen)
            
            // Save the ball manager's state
            // XXX REMOVE ME
            //ballManager!.saveState(restorationURL: ContinuousGameModel.ContinuousDirURL)
            if false == DataManager.shared.saveClassicBallState(numberOfBalls: ballManager!.numberOfBalls, originPoint: ballManager!.getOriginPoint()) {
                print("Failed to save ball manager state for classic mode!")
            }
            else {
                print("Successfully saved ball manager state for classic mode!")
            }
            
            // Save the item generator's state
            itemGenerator!.saveState(restorationURL: ContinuousGameModel.ContinuousDirURL)
        }
        catch {
            print("Error encoding game state: \(error)")
        }
    }
    
    public func loadPersistentState() -> Bool {
        do {
            // Load the persistent data
            let pData = try Data(contentsOf: ContinuousGameModel.PersistentDataURL)
            persistentData = try PropertyListDecoder().decode(PersistentData.self, from: pData)
            
            return true
        }
        catch {
            print("Error decoding persistent game state: \(error)")
            return false
        }
    }
    
    public func loadGameState() -> Bool {
        do {
            // Load game state for this game mode
            let gameData = try Data(contentsOf: ContinuousGameModel.GameStateURL)
            gameState = try PropertyListDecoder().decode(GameState.self, from: gameData)
            
            return true
        }
        catch {
            print("Error decoding game state: \(error)")
            return false
        }
    }
    
    public func clearGameState() {
        do {
             try FileManager.default.removeItem(atPath: ContinuousGameModel.GameStateURL.path)
             try FileManager.default.removeItem(atPath: ContinuousGameModel.ContinuousDirURL.path)
        }
        catch {
            print("Error clearing state: \(error)")
        }
    }
    
    // MARK: Initialization functions
    required init(numberOfRows: Int) {
        state = WAITING
        
        // Try to load persistent data
        if false == loadPersistentState() {
            // Defaults to load highScore of 0
            persistentData = PersistentData(highScore: highScore, showedTutorials: showedTutorials)
        }
        
        // Try to load game state
        if false == loadGameState() {
            // Defaults to loading gameScore of 0
            gameState = GameState(gameScore: gameScore, userWasSaved: userWasSaved)
        }
        
        // If the load works correctly, these will be initialized to their saved values. Otherwise they'll be loaded to their default values of 0
        highScore = persistentData!.highScore
        showedTutorials = persistentData!.showedTutorials
        gameScore = gameState!.gameScore
        userWasSaved = gameState!.userWasSaved
        self.numberOfRows = numberOfRows
    }
    
    public func initBallManager(ballRadius: CGFloat) {
        // This function will either load ball manager with a saved state or the default ball manager state
        let bmState = DataManager.shared.loadClassicBallState()
        ballManager = BallManager(numBalls: bmState!.numberOfBalls, radius: ballRadius, restorationURL: ContinuousGameModel.ContinuousDirURL)
        ballManager!.setOriginPoint(point: bmState!.originPoint!)
    }
    
    public func initItemGenerator(blockSize: CGSize, ballRadius: CGFloat) {
        // I don't think ItemGenerator should have a clue about the view or ceiling height or any of that
        itemGenerator = ItemGenerator(blockSize: blockSize, ballRadius: ballRadius,
                                      numberOfBalls: ballManager!.numberOfBalls,
                                      numberOfRows: numberOfRows,
                                      numItems: numberOfItems,
                                      restorationURL: ContinuousGameModel.ContinuousDirURL)
        if 0 == itemGenerator!.itemArray.count {
            state = TURN_OVER
        }
    }
    
    // MARK: Public functions
    public func getBalls() -> [BallItem] {
        return ballManager!.ballArray
    }
    
    // Load the previous turn state
    public func loadPreviousTurnState() -> Bool {
        if prevTurnSaved {
            if false == itemGenerator!.loadTurnState() {
                return false
            }
            if false == ballManager!.loadTurnState() {
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
        
        // Also save the ball manager's state
        ballManager!.saveTurnState()
        
        // Reset this to true since we saved state
        prevTurnSaved = true
        
        ballManager!.setDirection(point: point)
        // Change the ball manager's state from READY to SHOOTING
        ballManager!.incrementState()
        // Change our state from READY to MID_TURN
        incrementState()
    }
    
    public func endTurn() {
        ballManager!.returnAllBalls()
    }
    
    public func saveUser() -> [Item] {
        state = READY
        userWasSaved = true
        return itemGenerator!.saveUser()
    }

    public func handleTurn() -> [Item] {
        // Check to see if the user collected any ball items so far
        let removedItems = itemGenerator!.removeItems()
        for item in removedItems {
            if item is BallItem {
                // Transfer ownership of the from the item generator to the ball manager
                let ball = item as! BallItem
                ballManager!.addBall(ball: ball)
            }
        }
        
        // Iterate over all the balls in the array of stopped balls, stop them, and move them to their new origin point
        ballManager!.handleStoppedBalls()
        
        // Check to see if the ball manager is still waiting for balls to return
        if ballManager!.isWaiting() {
            ballManager!.waitForBalls()
        }
        
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
        
        // Go from TURN_OVER state to WAITING state
        incrementState()
        
        // Reset the x2 ball hit flag
        itemGenerator!.setOnFireBonus(false)
    }
    
    // MARK: Physics contact functions
    public func handleContact(nameA: String, nameB: String) {
        // Items that start with the name bm are ball manager balls. They are named differently from the other items so we can quickly check if a ball manager ball is interacting with an item from the item generator
        // Add any extra cases in here if they need special attention
        if nameA.starts(with: "bm") {
            if "ground" == nameB {
                ballManager!.markBallInactive(name: nameA)
            }
            else {
                let _ = itemGenerator!.hit(name: nameB)
            }
        }
        
        if nameB.starts(with: "bm") {
            if "ground" == nameA {
                ballManager!.markBallInactive(name: nameB)
            }
            else {
                let _ = itemGenerator!.hit(name: nameA)
            }
        }
    }
    
    public func setBallsOnFire() {
        ballManager!.setBallsOnFire()
        
        // Set the ball hit x2 flag
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
