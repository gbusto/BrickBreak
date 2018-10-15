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
    
    public var currencyAmount = Int(0)
    
    public var ballManager: BallManager?
    public var itemGenerator: ItemGenerator?
    
    // MARK: Private properties
    private var persistentData: PersistentData?
    private var gameState: GameState?
    
    private var numberOfItems = Int(8)
    private var numberOfBalls = Int(10)
    
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
    // This is persistent data that will contain the high score and currency
    static let PersistentDataURL = AppDirURL.appendingPathComponent("PersistentData")
    // The directory to store game state for this game type
    static let ContinuousDirURL = AppDirURL.appendingPathComponent("ContinuousDir")
    // The path where game state is stored for this game mode
    static let GameStateURL = ContinuousDirURL.appendingPathComponent("GameState")
    
    
    // MARK: State handling code
    // This struct is used for managing persistent data (such as your overall high score, currency amount, what level you're on, etc)
    struct PersistentData: Codable {
        var highScore: Int
        var currencyAmount: Int
        
        // This serves as the authoritative list of properties that must be included when instances of a codable type are encoded or decoded
        // Read Apple's documentation on CodingKey protocol and Codable
        enum CodingKeys: String, CodingKey {
            case highScore
            case currencyAmount
        }
    }
    
    // This struct is used for managing any state from this class that is required to save the user's place
    struct GameState: Codable {
        var gameScore: Int
        
        enum CodingKeys: String, CodingKey {
            case gameScore
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
                print("Created app directory in Documents")
            }
            
            // Check if the user beat their high score; if they did then save it
            if persistentData!.highScore != highScore {
                persistentData!.highScore = highScore
            }
            // Save the user's current currency amount
            persistentData!.currencyAmount = currencyAmount
            
            // Save the persistent data
            let pData = try PropertyListEncoder().encode(self.persistentData!)
            try pData.write(to: ContinuousGameModel.PersistentDataURL, options: .completeFileProtectionUnlessOpen)
            print("Wrote persistent data to file")
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
                print("Created directory for continuous game state")
            }
            
            // Save game state stuff (right now it's just the current game score)
            gameState!.gameScore = gameScore
            
            // Save the game state
            let gameData = try PropertyListEncoder().encode(self.gameState!)
            try gameData.write(to: ContinuousGameModel.GameStateURL, options: .completeFileProtectionUnlessOpen)
            print("Wrote game state data to file")
            
            // Save the ball manager's state
            ballManager!.saveState(restorationURL: ContinuousGameModel.ContinuousDirURL)
            
            // Save the item generator's state
            itemGenerator!.saveState(restorationURL: ContinuousGameModel.ContinuousDirURL)
        }
        catch {
            print("Error encoding game state: \(error)")
        }
    }
    
    public func loadPersistentState() -> Bool {
        do {
            // COMMENT ME OUT
            //try FileManager.default.removeItem(atPath: ContinuousGameModel.PersistentDataURL.path)
            //return false
            
            // Load the persistent data
            let pData = try Data(contentsOf: ContinuousGameModel.PersistentDataURL)
            persistentData = try PropertyListDecoder().decode(PersistentData.self, from: pData)
            print("Loaded persistent data")
            
            return true
        }
        catch {
            print("Error decoding persistent game state: \(error)")
            return false
        }
    }
    
    public func loadGameState() -> Bool {
        do {
            // COMMENT ME OUT
            //try FileManager.default.removeItem(atPath: ContinuousGameModel.GameStateURL.path)
            //try FileManager.default.removeItem(atPath: ContinuousGameModel.ContinuousDirURL.path)
            //return false
            
            // Load game state for this game mode
            let gameData = try Data(contentsOf: ContinuousGameModel.GameStateURL)
            gameState = try PropertyListDecoder().decode(GameState.self, from: gameData)
            print("Loaded game state")
            
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
    required init(view: SKView, blockSize: CGSize, ballRadius: CGFloat) {
        // State should always be initialized to READY
        if false == loadPersistentState() {
            // Defaults to load highScore of 0 and currencyAmount of 0
            persistentData = PersistentData(highScore: highScore, currencyAmount: currencyAmount)
        }
        
        if false == loadGameState() {
            // Defaults to loading gameScore of 0
            gameState = GameState(gameScore: gameScore)
        }
        
        // If the load works correctly, these will be initialized to their saved values. Otherwise they'll be loaded to their default values of 0
        highScore = persistentData!.highScore
        currencyAmount = persistentData!.currencyAmount
        gameScore = gameState!.gameScore
        
        // This function will either load ball manager with a saved state or the default ball manager state
        ballManager = BallManager(numBalls: numberOfBalls, radius: ballRadius, restorationURL: ContinuousGameModel.ContinuousDirURL)
        
        // I don't think ItemGenerator should have a clue about the view or ceiling height or any of that
        itemGenerator = ItemGenerator(blockSize: blockSize, ballRadius: ballRadius, numberOfBalls: ballManager!.numberOfBalls, numItems: numberOfItems, restorationURL: ContinuousGameModel.ContinuousDirURL)
        if 0 == itemGenerator!.itemArray.count {
            state = TURN_OVER
        }
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
    
    public func endTurn() {
        ballManager!.returnAllBalls()
    }

    public func handleTurn() -> [Item] {
        // Check to see if the user collected any balls or currency items so far
        let removedItems = itemGenerator!.removeItems()
        for item in removedItems {
            if item is BallItem {
                // Transfer ownership of the from the item generator to the ball manager
                let ball = item as! BallItem
                ballManager!.addBall(ball: ball)
            }
            else if item is CurrencyItem {
                // Increment the current amount
                currencyAmount += 1
            }
        }
        
        // Check for inactive balls and stop them
        ballManager!.stopInactiveBalls()
        
        // Wait for the ball manager to finish
        if ballManager!.isDone() {
            print("BALL MANAGER IS DONE")
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
                itemGenerator!.hit(name: nameB)
            }
        }
        
        if nameB.starts(with: "bm") {
            if "ground" == nameA {
                ballManager!.markBallInactive(name: nameB)
            }
            else {
                itemGenerator!.hit(name: nameA)
            }
        }
    }
    
    public func generateRow() -> [Item] {
        let count = itemGenerator!.getBlockCount()
        // If the user is doing well and there are no items on the screen, generate a harder pattern
        if count <= 4 {
            itemGenerator!.easyPatternPercent = 10
            itemGenerator!.intermediatePatternPercent = 30
            itemGenerator!.hardPatternPercent = 60
        }
        // If they have <= 6 items on the screen, increase the difficult of getting a harder pattern
        else if (count > 4) && (count <= 8) {
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
    
    public func animateItems(action: SKAction) {
        itemGenerator!.animateItems(action)
    }
    
    public func animationsDone() -> Bool {
        if itemGenerator!.isReady() {
            // Change state from WAITING to READY
            print("MODEL IS READY")
            incrementState()
            return true
        }
        return false
    }
    
    public func lossRisk(floor: CGFloat, rowHeight: CGFloat) -> Bool {
        return !itemGenerator!.canAddItems(floor, rowHeight, 2)
    }
    
    // The floor of the game scene; if another row doesn't fit
    public func gameOver(floor: CGFloat, rowHeight: CGFloat) -> Bool {
        if false == itemGenerator!.canAddItems(floor, rowHeight, 1) {
            state = GAME_OVER
            return true
        }
        return false
    }
    
    public func incrementState() {
        if WAITING == state {
            state = READY
            // Save state after each turn
            saveState()
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
