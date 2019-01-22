//
//  LevelsGameModel.swift
//  Ballz1
//
//  Created by hemingway on 1/13/19.
//  Copyright © 2019 Self. All rights reserved.
//

import SpriteKit

class LevelsGameModel {
    
    // MARK: Public properties
    public var gameScore = Int(0)
    public var levelCount = Int(0)
    
    public var ballManager: BallManager?
    public var itemGenerator: ItemGenerator?
    
    public var showedTutorials = false
    
    // MARK: Private properties
    private var persistentData: PersistentData?
    
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
    // The directory to store game state for this game type
    static let LevelsDirURL = AppDirURL.appendingPathComponent("LevelsDir")
    // The path where game state is stored for this game mode
    static let PersistentDataURL = LevelsDirURL.appendingPathComponent("PersistentData")
    
    
    // MARK: State handling code
    // This struct is used for managing persistent data (such as your overall high score, what level you're on, etc)
    struct PersistentData: Codable {
        var levelCount: Int
        var showedTutorials: Bool
        
        // This serves as the authoritative list of properties that must be included when instances of a codable type are encoded or decoded
        // Read Apple's documentation on CodingKey protocol and Codable
        enum CodingKeys: String, CodingKey {
            case levelCount
            case showedTutorials
        }
    }
    
    public func saveState() {
        // If we're in the middle of a turn, we don't want to save the state. Users could exploit this to cheat
        if isReady() || isGameOver() {
            savePersistentState()
        }
    }
    
    public func savePersistentState() {
        do {
            // Create the App directory Documents/BB
            if false == FileManager.default.fileExists(atPath: LevelsGameModel.AppDirURL.path) {
                try FileManager.default.createDirectory(at: LevelsGameModel.AppDirURL, withIntermediateDirectories: true, attributes: nil)
            }
            
            // Set persistent data variables in struct here
            
            // Save the persistent data
            let pData = try PropertyListEncoder().encode(self.persistentData!)
            try pData.write(to: LevelsGameModel.PersistentDataURL, options: .completeFileProtectionUnlessOpen)
        }
        catch {
            print("Error saving persistent state: \(error)")
        }
    }
    
    public func loadPersistentState() -> Bool {
        do {
            // Load the persistent data
            let pData = try Data(contentsOf: LevelsGameModel.PersistentDataURL)
            persistentData = try PropertyListDecoder().decode(PersistentData.self, from: pData)
            
            return true
        }
        catch {
            print("Error decoding persistent game state: \(error)")
            return false
        }
    }
    
    public func clearGameState() {
        do {
            try FileManager.default.removeItem(atPath: LevelsGameModel.LevelsDirURL.path)
        }
        catch {
            print("Error clearing state: \(error)")
        }
    }
    
    // MARK: Initialization functions
    required init(view: SKView, blockSize: CGSize, ballRadius: CGFloat, numberOfRows: Int) {
        state = WAITING
        
        // Try to load persistent data
        if false == loadPersistentState() {
            persistentData = PersistentData(levelCount: levelCount, showedTutorials: showedTutorials)
        }
        
        /*
         For the game model, the only information we need to save is the level count.
         Start everything off at zero and display X number of rows of blocks for the level.
         Continue to add rows to the game until there are no more.
         Game ends whenever there are no items left in the item generator.
         */
        
        // If the load works correctly, these will be initialized to their saved values. Otherwise they'll be loaded to their default values of 0
        levelCount = persistentData!.levelCount
        showedTutorials = persistentData!.showedTutorials
        self.numberOfRows = numberOfRows
        
        // This function will either load ball manager with a saved state or the default ball manager state
        ballManager = BallManager(numBalls: numberOfBalls, radius: ballRadius, restorationURL: LevelsGameModel.LevelsDirURL)
        
        // I don't think ItemGenerator should have a clue about the view or ceiling height or any of that
        itemGenerator = ItemGenerator(blockSize: blockSize, ballRadius: ballRadius,
                                      numberOfBalls: ballManager!.numberOfBalls,
                                      numberOfRows: numberOfRows,
                                      numItems: numberOfItems,
                                      restorationURL: LevelsGameModel.LevelsDirURL,
                                      useDrand: true,
                                      // XXX This value should be based on the level number
                                      seed: 0)
        if 0 == itemGenerator!.itemArray.count {
            state = TURN_OVER
        }
    }
    
    // MARK: Public functions
    public func getBalls() -> [BallItem] {
        return ballManager!.ballArray
    }
    
    public func prepareTurn(point: CGPoint) {
        // Save the item generator's turn state as soon as the user starts the next turn
        itemGenerator!.saveTurnState()
        
        // Also save the ball manager's state
        ballManager!.saveTurnState()
        
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
        var addToScore = Int(0)
        
        // Check to see if the user collected any ball items so far
        let removedItems = itemGenerator!.removeItems()
        for item in removedItems {
            if item is BallItem {
                print("Removed item is ball")
                addToScore += 2
                // Transfer ownership of the from the item generator to the ball manager
                let ball = item as! BallItem
                ballManager!.addBall(ball: ball)
            }
            else if item is HitBlockItem {
                print("Removed item is hit block")
                addToScore += 10
            }
            else if item is StoneHitBlockItem {
                print("Removed item is stone block")
                addToScore += 20
            }
            else if item is BombItem {
                print("Removed item is bomb")
                addToScore += 10
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
        
        gameScore += addToScore
        
        return removedItems
    }
    
    // Handles a turn ending; generate a new row, check for new balls, increment the score, etc
    public func handleTurnOver() {
        ballManager!.checkNewArray()
        
        // XXX This needs to be different here; update the user's score by more than just one.
        // Need a formula for this like 1 point per hit, 5 per block break, and double the final score if they hit "on fire" (maybe?)
        //gameScore += 1
        
        // Submit this score to game center after finishing a level
        
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
                if "wall" != nameB && "ceiling" != nameB {
                    gameScore += 1
                }
                itemGenerator!.hit(name: nameB)
            }
        }
        
        if nameB.starts(with: "bm") {
            if "ground" == nameA {
                ballManager!.markBallInactive(name: nameB)
            }
            else {
                if "wall" != nameA && "ceiling" != nameA {
                    gameScore += 1
                }
                itemGenerator!.hit(name: nameA)
            }
        }
    }
    
    // XXX This will need to be different for levels; need to generate all rows up front when we initialize the model
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
