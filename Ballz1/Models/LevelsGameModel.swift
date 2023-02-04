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
    public var highScore = Int(0)
    public var cumulativeScore = Int(0)
    public var levelCount = Int(1)
    
    public var numberOfBalls = Int(10)
    
    public var itemGenerator: ItemGenerator?
    
    public var showedTutorials = false
    
    public var savedUser = false
    
    // The number of rows we've generated so far
    public var rowNumber = Int(0)
    // The total number of rows to generate
    public var numRowsToGenerate = Int(0)
    
    // A boolean that is true after it detects that the last item has been broken
    public var lastItemBroken = false
    
    // MARK: Private properties
    private var persistentData: DataManager.LevelsPersistentData?
    
    private var numberOfItems = Int(8)
    private var numberOfRows = Int(0)
    
    private var scoreThisTurn = Int(0)
    private var blockBonus = Int(2)
    private var onFireBonus = Double(1.0)
    
    // TODO: Change this into an enum
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
    
    private static var MAX_NUM_ROWS_TO_GENERATE = Int(50)
    private static var MAX_NUM_BALLS = Int(50)
    
    // TODO: Fix this - this is bad, I could accidentally deploy the app with this set to false and then what?
    private var PRODUCTION = true
    
    var dataManager: DataManager = DataManager.shared
    
    static public var GAMEOVER_NONE = Int(0)
    static public var GAMEOVER_LOSS = Int(1)
    static public var GAMEOVER_WIN = Int(2)
    
    public func saveState() {
        // If we're in the middle of a turn, we don't want to save the state. Users could exploit this to cheat
        if isReady() || isGameOver() {
            // XXX REMOVE ME
            //savePersistentData()
            
            // Update the game score
            if gameScore > highScore {
                highScore = gameScore
            }
            
            cumulativeScore += gameScore
            
            dataManager.saveLevelsPersistentData(levelCount: levelCount, highScore: highScore, cumulativeScore: cumulativeScore, showedTutorials: showedTutorials)
        }
    }
    
    // MARK: - Helper functions to prevent LevelsGameScene from depending directly on the model's ItemGenerator instance
    
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
    
    // MARK: Initialization functions
    required init(blockSize: CGSize, ballRadius: CGFloat, numberOfRows: Int, production: Bool = true) {
        PRODUCTION = production
        
        state = WAITING
        
        // Try to load persistent data
        persistentData = dataManager.loadLevelsPersistentData()
        if nil == persistentData {
            persistentData = DataManager.LevelsPersistentData(levelCount: levelCount, highScore: gameScore, cumulativeScore: cumulativeScore, showedTutorials: showedTutorials)
        }
        
        /*
         For the game model, the only information we need to save is the level count.
         Start everything off at zero and display X number of rows of blocks for the level.
         Continue to add rows to the game until there are no more.
         Game ends whenever there are no items left in the item generator.
         */
        
        // If the load works correctly, these will be initialized to their saved values. Otherwise they'll be loaded to their default values of 0
        highScore = persistentData!.highScore
        levelCount = persistentData!.levelCount
        cumulativeScore = persistentData!.cumulativeScore
        showedTutorials = persistentData!.showedTutorials
        self.numberOfRows = numberOfRows
        
        /*
        // XXX REMOVE ME
        if 0 == cumulativeScore && levelCount > 1 {
            // If the user's cumulative score is 0 and they're beyond the 1st level, set it manually for them
            // XXX This may need to be removed later
            cumulativeScore = levelCount * 6000
            print("Manually set cumulative score to \(cumulativeScore)")
        }
        */
        
        if PRODUCTION {
            // Generate a dynamic number of rows based on the level count
            // Essentially, add 5 rows to the base for every 10 levels the user passes
            numRowsToGenerate = 10 + (4 * (levelCount / 10))
            if numRowsToGenerate > LevelsGameModel.MAX_NUM_ROWS_TO_GENERATE {
                // Cap it off to 50 rows max
                numRowsToGenerate = LevelsGameModel.MAX_NUM_ROWS_TO_GENERATE
            }
            
            numberOfBalls = 20 + (3 * (levelCount / 10))
            if numberOfBalls > LevelsGameModel.MAX_NUM_BALLS {
                // Cap it off to 50 balls max
                numberOfBalls = LevelsGameModel.MAX_NUM_BALLS
            }
            
            // I don't think ItemGenerator should have a clue about the view or ceiling height or any of that
            itemGenerator = ItemGenerator(blockSize: blockSize, ballRadius: ballRadius,
                                          numberOfRows: numberOfRows,
                                          numItems: numberOfItems,
                                          state: nil,
                                          useDrand: true,
                                          seed: levelCount)
            // XXX This isn't so clean.. find a better way to set the number of balls for the item generator
            itemGenerator!.numberOfBalls = numberOfBalls
        
            // We don't want to have ball items in levels
            itemGenerator!.removeBallTypeGeneration()
        
            // XXX This should be based on the level number (the higher the level, the more difficult it should be)
            // Addressed in issue #429
            itemGenerator!.easyPatternPercent = 40
            itemGenerator!.intermediatePatternPercent = 40
            itemGenerator!.hardPatternPercent = 20
        
            // XXX Force this to be in the TURN_OVER state; getting stuck in WAITING state
            // Addresses in issue #431
            /*
            if 0 == itemGenerator!.itemArray.count {
                state = TURN_OVER
            }
            */
        
            state = TURN_OVER
        }
        // TODO: This would be a good thing to do in some kind of UI test or using some other mechanism instead of a PRODUCTION boolean
        else {
            // NON-PRODUCTION: Create the desired row layouts here manually for testing
            numberOfBalls = 50
            let itemTypeDict: [Int : Int] = [:]
            let blockTypeArray: [Int] = [ItemGenerator.HIT_BLOCK, ItemGenerator.STONE_BLOCK, ItemGenerator.MYSTERY_BLOCK]
            let nonBlockTypeArray: [Int] = [ItemGenerator.SPACER, ItemGenerator.BOMB, ItemGenerator.BALL]
            
            let itemArrayStr: [[String]] = [
                ["H:44", "H:23", "S:0", "S:0", "S:0", "S:0", "?:50", "S:0"],
                ["S:0", "S:0", "H:20", "H:25", "H:35", "H:12", "S:0", "S:0"],
                ["?:26", "S:0", "S:0", "B:0", "H:44", "S:0", "T:31", "S:0"],
                ["S:0", "S:0", "S:0", "H:43", "S:0", "H:10", "S:0", "S:0"]
            ]
            
            var itemArray: [[Int]] = []
            var itemHitCountArray: [[Int]] = []
            for row in itemArrayStr {
                var itemRow: [Int] = []
                var hitCountRow: [Int] = []
                for item in row {
                    if item.starts(with: "H") {
                        itemRow.append(ItemGenerator.HIT_BLOCK)
                    }
                    else if item.starts(with: "T") {
                        itemRow.append(ItemGenerator.STONE_BLOCK)
                    }
                    else if item.starts(with: "?") {
                        itemRow.append(ItemGenerator.MYSTERY_BLOCK)
                    }
                    else if item.starts(with: "B") {
                        itemRow.append(ItemGenerator.BOMB)
                    }
                    else if item.starts(with: "S") {
                        itemRow.append(ItemGenerator.SPACER)
                    }
                    
                    // Get the hit count for this item
                    let hitCount = item.split(separator: ":")[1]
                    hitCountRow.append(Int(hitCount)!)
                }
                
                itemArray.append(itemRow)
                itemHitCountArray.append(hitCountRow)
            }
            
            numRowsToGenerate = itemArray.count
            
            let itemState = DataManager.ItemGeneratorState(numberOfBalls: numberOfBalls, itemTypeDict: itemTypeDict, itemArray: itemArray, itemHitCountArray: itemHitCountArray, blockTypeArray: blockTypeArray, nonBlockTypeArray: nonBlockTypeArray)
            itemGenerator = ItemGenerator(blockSize: blockSize, ballRadius: ballRadius,
                                          numberOfRows: 0,
                                          numItems: numberOfItems,
                                          state: itemState,
                                          useDrand: false,
                                          seed: 0)
            
            state = TURN_OVER
        }
    }
    
    // MARK: Public functions
    public func prepareTurn() {
        // Reset the score for this turn to 0
        scoreThisTurn = 0
        resetAdditives()
        
        // Save the item generator's turn state as soon as the user starts the next turn
        itemGenerator!.saveTurnState()
        
        // Change our state from READY to MID_TURN
        incrementState()
    }
    
    public func saveUser() -> [Item] {
        state = READY
        savedUser = true
        return itemGenerator!.saveUser()
    }
    
    public func handleTurn() -> [(Item, Int, Int)] {
        var addToScore = Int(0)
        
        let removedItems = itemGenerator!.removeItems()
        for item in removedItems {
            if item.0 is HitBlockItem {
                addToScore += Int(Double(blockBonus) * onFireBonus)
                blockBonus += Int(2 * onFireBonus)
            }
            else if item.0 is StoneHitBlockItem {
                addToScore += Int(Double(blockBonus) * onFireBonus)
                blockBonus += Int(4 * onFireBonus)
            }
            else if item.0 is BombItem {
                addToScore += Int(10 * onFireBonus)
            }
        }
        
        if 0 == itemGenerator!.getItemCount() && rowNumber >= numRowsToGenerate {
            // After detecting that the last item broke and we've generated all the rows, set this variable so the game scene can end the game
            lastItemBroken = true
        }
        
        // XXX We are now incrementing the model's state in the view when it detects all balls have landed
        
        gameScore += addToScore
        scoreThisTurn += addToScore
        
        return removedItems
    }
    
    public func addOnFireBonus() {
        onFireBonus = Double(1.5)
        let newScore = Int(Double(scoreThisTurn) * onFireBonus)
        let diff = newScore - scoreThisTurn
        gameScore += diff
        scoreThisTurn = newScore
        
        // Ball hits are now x2
        itemGenerator!.setOnFireBonus(true)
    }
    
    // Handles a turn ending; generate a new row, check for new balls, increment the score, etc
    public func handleTurnOver() {
        // XXX This might not be necessary in levels? This should only be checking for new balls that the user collected and you can't collect balls in levels.
        
        // Reset the flag in item generator for ball hits x2
        itemGenerator!.setOnFireBonus(false)
        
        // Submit this score to game center after finishing a level
        
        // Go from TURN_OVER state to WAITING state
        incrementState()
    }
    
    // MARK: Physics contact functions
    public func handleContact(nameA: String, nameB: String) {
        var additive = Int(1)
        if onFireBonus > 1.0 {
            additive = Int(2)
        }
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
            scoreThisTurn += additive
            gameScore += additive
        }
    }
    
    // Some hacky math to figure out how many rows of actual items we have left in the game
    // The reason we need to do this is because levels have a finite number of rows to play (numRowsToGenerate)
    // After we've generated all the rows for a level, we continue adding empty rows (rows with SpacerItems) so that we can properly detect lossRisk and gameOver scenarios
    public func getActualRowCount() -> Int {
        var actualRowCount = 0
        
        if rowNumber >= numRowsToGenerate {
            // We're not generating rows with items anymore so see by how many rows we've exceeded the number to generate
            // (If numRowsToGenerate is 10 and rowNumber is rowNumber 18, diff is 8)
            let diff = rowNumber - numRowsToGenerate
            // To see how many rows of actual itmes are left, take the difference between the number of rows on the screen and diff
            // We take numberOfRows - 2 because the top most row is empty, and the last row is unusable because if the blocks reach it then the user loses
            // (If we have 2 rows left on the screen, numberOfRows - 2 (10) - diff (8) is 2 so this will give the correct number of actual rows left)
            actualRowCount = (numberOfRows - 2) - diff
        }
        else {
            // If we haven't generated all the rows yet, then do this
            actualRowCount = numRowsToGenerate - rowNumber + (numberOfRows - 2)
        }
        
        return actualRowCount
    }
    
    // XXX This will need to be different for levels; need to generate all rows up front when we initialize the model
    // Addressed in issue #431
    public func generateRow() -> [Item] {
        rowNumber += 1

        if rowNumber > numRowsToGenerate {
            // XXX This is just a hack for now that needs to be fixed
            // Addressed in issue #431 (I think, the one to fix game states for levels gameplay)
            // At this point, if the user cleared all the items on the screen there will still technically be rows left in the item array
            // These rows will just contain SpacerItems. To then let the game scene know that the user cleared all the blocks,
            // we return an empty array. This is a bad solution because it's kind of a hack, but it works for now.
            if itemGenerator!.itemArray.count == 0 {
                return []
            }
            
            // Return an empty row of items (we're not generating anymore items)
            return itemGenerator!.generateRow(emptyRow: true)
        }
        
        if PRODUCTION {
            // Generate a normal row
            return itemGenerator!.generateRow()
        }
        else {
            // NON-PRODUCTION: Generate a test row if we're not in production mode
            return generateTestRow()
        }
    }
    
    public func lossRisk() -> Bool {
        return (itemGenerator!.itemArray.count == numberOfRows - 2)
    }
    
    // The floor of the game scene; if another row doesn't fit
    /*  XXX
     Rewrite this to maybe detect gameover without needing to call a function first; it should just end up in the GAME_OVER state
     and the view's update() loop should check for .isGameOver()
    */
    public func gameOver() -> Int {
        // XXX This needs to be updated to capture if the user lost
        // Also, the lossRisk function will need to be updated too
        if (itemGenerator!.itemArray.count == numberOfRows - 1) {
            state = GAME_OVER
            return LevelsGameModel.GAMEOVER_LOSS
        }
        else if itemGenerator!.itemArray.count == 0 {
            if PRODUCTION {
                // The user beat the level!
                levelCount += 1
            }
            else {
                // NON-PRODUCTION: Don't increment the level count if we're not in production
            }
            
            // Show an ad
            
            state = GAME_OVER
            return LevelsGameModel.GAMEOVER_WIN
        }
        
        return LevelsGameModel.GAMEOVER_NONE
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
    
    private func resetAdditives() {
        blockBonus = Int(2)
        onFireBonus = Double(1.0)
    }
    
    // NON-PRODUCTION function
    private func generateTestRow() -> [Item] {
        let items = itemGenerator!.itemArray[rowNumber - 1]
        return items
    }
}
