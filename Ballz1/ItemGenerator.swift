//
//  ItemGenerator.swift
//  Ballz1
//
//  Created by Gabriel Busto on 9/18/18.
//  Copyright © 2018 Self. All rights reserved.
//

import SpriteKit
import GameplayKit

/*
 This might be a good file to start with with regards to testing since it's core to both game types, and there are plenty of ways to fix up this code.
 
 Big improvements:
 - Create models for each item type that can handle initialization
 - Create an enum of possible item types
 - Functions should actually be somewhat testable, more easily than the Models at the moment
 - ItemGenerator should ONLY be concerned with logic to generate items. It shouldn't have any concept of CGSize for blocks
    + Should the ItemGenerator be concerned with how many balls are on the screen? The number of balls on the screen aren't technically generated items. Should the name of this class change? Or should the things this class does change?
 */

class ItemGenerator {
    
    // -------------------------------------------------------------
    // MARK: Public properties
    
    // Rows of items for which this generator is responsible
    public var itemArray: [[Item]] = []
    
    // Maximum hit count for a HitBlock
    // The default could possibly be set in the constructor
    public var numberOfBalls = Int(10)
    
    // These variables can be used to tweak the pattern distribution as needed
    // These are used by the model to tweak pattern difficulty distribution
    public var hardPatternPercent = 10
    public var intermediatePatternPercent = 25
    public var easyPatternPercent = 65
    
    // These should probably be some kind of enum
    // Used to mark item types to know what item types are allowed to be generated
    // TODO: Change these to an enum
    public static let SPACER = Int(0)
    public static let HIT_BLOCK = Int(1)
    public static let BALL = Int(2)
    public static let STONE_BLOCK = Int(3)
    public static let BOMB = Int(4)
    public static let MYSTERY_BLOCK = Int(5)
    
    // -------------------------------------------------------------
    // MARK: Private attributes
    // TODO: This is a good start for this, allows for dependency injection
    private var igState: DataManager.ItemGeneratorState?
    
    // Number of items to fit on each row
    public private(set) var numItemsPerRow = Int(0)
    
    public private(set) var numberOfRows = Int(0)
    
    // Number of items that this generator has generated
    private var numItemsGenerated = Int(0)
    
    // TODO: Why are these private? I could just make them read-only
    public private(set) var blockSize: CGSize?
    public private(set) var ballRadius: CGFloat?
    
    // Item types that this generator can generate; for example, after 100 turns, maybe you want to start adding special kinds of blocks
    // The format is [ITEM_TYPE: PERCENTAGE_TO_GENERATE]
    // XXX This may not be used anymore; if it isn't being used it should be removed
    private var itemTypeDict: [Int: Int] = [:]
    
    // There exist as many block types in this array as its percentage; for example, if hit blocks have a 65% chance of being selected, there will be 65 hit blocks in this array
    private var blockTypeArray: [Int] = []
    // This works the same as the above array, but this is only for non block item types (balls, spacer items, etc)
    private var nonBlockTypeArray: [Int] = []
    
    private var prevTurnState = ItemGeneratorPrevTurn(itemArray: [], itemHitCountArray: [], numberOfBalls: 0)
    
    // Boolean as to whether or not we should use drand to generate randomness
    private var USE_DRAND = false
    
    private var ballsOnFire = false
    
    private var dataManager: DataManager = DataManager.shared
    
    
    // The distribution for these patterns should be 65, 25, 10 (easy, intermediate, hard)
    private static let EASY_PATTERNS: [[Int]] = [
        [1, 0, 0, 0],
        [0, 1, 0, 0],
        [0, 0, 1, 0],
        [0, 0, 0, 1],
        [0, 0, 0, 1, 1],
        [1, 0, 0, 0, 0, 0, 0, 1],
        [1, 1, 0, 0 ,0 ,0 ,0 ,0],
        [0, 0, 0, 0, 0, 0, 1, 1],
    ]
    
    private static let INTERMEDIATE_PATTERNS: [[Int]] = [
        [1, 1, 0, 0],
        [0, 0, 1, 1],
        [1, 0, 0, 1],
        [1, 0, 1, 0],
        [1, 1, 0, 0, 0, 0, 1, 1],
        [0, 0, 1, 1, 1, 1, 0, 0],
    ]
    
    private static let HARD_PATTERNS: [[Int]] = [
        [1, 1, 1, 0],
        [0, 1, 1, 1],
        [1, 1, 0, 1, 1, 0],
        [1, 0, 1, 1, 0],
        [0, 0, 1, 1, 1, 1]
    ]
    
    
    // MARK: State handling functions
    
    // The struct for stuff needed to restore state from the previous turn
    struct ItemGeneratorPrevTurn {
        var itemArray: [[Int]]
        var itemHitCountArray: [[Int]]
        var numberOfBalls: Int
    }
    
    // Backs up the items (used for saving state and restoring user's previous turn)
    /*
     Anything that has to do with the previous turn should be moved up a level in the layers of abstraction. This class should only be concerned with generating items.
     */
    private func backupItems() -> ItemGeneratorPrevTurn {
        var savedItemArray: [[Int]] = []
        var savedHitCountArray: [[Int]] = []
        for row in itemArray {
            var newItemRow: [Int] = []
            var itemHitCountRow: [Int] = []
            for item in row {
                if item is SpacerItem {
                    newItemRow.append(ItemGenerator.SPACER)
                    itemHitCountRow.append(0)
                }
                else if item is HitBlockItem {
                    let block = item as! HitBlockItem
                    newItemRow.append(ItemGenerator.HIT_BLOCK)
                    itemHitCountRow.append(block.hitCount!)
                }
                else if item is StoneHitBlockItem {
                    let block = item as! StoneHitBlockItem
                    newItemRow.append(ItemGenerator.STONE_BLOCK)
                    itemHitCountRow.append(block.hitCount!)
                }
                else if item is MysteryBlockItem {
                    let block = item as! MysteryBlockItem
                    newItemRow.append(ItemGenerator.MYSTERY_BLOCK)
                    itemHitCountRow.append(block.hitCount!)
                }
                else if item is BombItem {
                    newItemRow.append(ItemGenerator.BOMB)
                    itemHitCountRow.append(0)
                }
                else if item is BallItem {
                    newItemRow.append(ItemGenerator.BALL)
                    itemHitCountRow.append(0)
                }
            }
            savedItemArray.append(newItemRow)
            savedHitCountArray.append(itemHitCountRow)
        }
        
        let prevTurn = ItemGeneratorPrevTurn(itemArray: savedItemArray, itemHitCountArray: savedHitCountArray, numberOfBalls: numberOfBalls)
        return prevTurn
    }
    
    /* PURPOSE: Actually save turn state to disk
     Saves turn state to disk by backing up items in their current positions
     */
    public func saveState() {
        let backedUpItems = backupItems()
        
        dataManager.saveClassicItemGeneratorState(numberOfBalls: numberOfBalls, itemTypeDict: itemTypeDict, itemArray: backedUpItems.itemArray, itemHitCountArray: backedUpItems.itemHitCountArray, blockTypeArray: blockTypeArray, nonBlockTypeArray: nonBlockTypeArray)
    }
    
    /* PURPOSE: Backs up items and position to a variable, doesn't actually save to dis
     Should maybe be called something different to avoid confusing it with the variable above
     */
    public func saveTurnState() {
        // Backup the items into this state struct
        prevTurnState = backupItems()
    }

    /*
     Loads turn state from "prevTurnState" variable
     
     This function should be renamed; it sounds like it should take a parameter
     */
    public func loadTurnState() -> Bool {
        // Return false if the array for the previous turn is empty
        if prevTurnState.itemArray.isEmpty {
            return false
        }
        
        // Return true if we have items to reload
        itemArray = loadItems(items: prevTurnState.itemArray, itemHitCounts: prevTurnState.itemHitCountArray, numberOfBalls: prevTurnState.numberOfBalls)
        
        // Reset the previous turn state so we don't reload old data
        prevTurnState.itemArray = []
        prevTurnState.itemHitCountArray = []
        
        return true
    }
    
    // Gets the item count (doesn't include spacer items)
    /*
     Gets the current count of items; could be simplified using map, filter, and count?
     */
    public func getItemCount() -> Int {
        var count = Int(0)
        for row in itemArray {
            for item in row {
                if item is SpacerItem {
                    continue
                }
                
                count += 1
            }
        }
        
        return count
    }
    
    // Load items into an array and return that array
    /*
     Sets up items in the item generator based on variables passed in; good for testing.
     Code looks complicated, could probably be simplified.
     */
    func loadItems(items: [[Int]], itemHitCounts: [[Int]], numberOfBalls: Int) -> [[Item]] {
        // The final array we'll return
        var array: [[Item]] = []
        
        self.numberOfBalls = numberOfBalls
        
        // A boolean flag that says if we have an odd number of rows; used for loading stone blocks in the correct state
        let oddNumRows = (items.count % 2 == 1)
        
        if items.count > 0 {
            for i in 0...(items.count - 1) {
                var newRow: [Item] = []
                
                // This is for ensuring stone blocks load in the correct state
                let isOddRow = (i % 2 == 1)
                
                let row = items[i]
                for j in 0...(row.count - 1) {
                    let itemType = row[j]
                    let item = generateItem(itemType: itemType)
                    newRow.append(item!)
                    if item! is SpacerItem {
                        continue
                    }
                    else if item! is HitBlockItem {
                        let block = item! as! HitBlockItem
                        // Load the block's hit count
                        block.updateHitCount(count: itemHitCounts[i][j])
                    }
                    else if item! is StoneHitBlockItem {
                        let block = item! as! StoneHitBlockItem
                        // Load the block's hit count
                        block.updateHitCount(count: itemHitCounts[i][j])
                        if oddNumRows && isOddRow {
                            // If there are an odd number of rows in the item array, the stone blocks in the odd rows should be stone; this ensures that the state is correct for when the view calls animateItems() which will trigger the stone block to change state
                            block.changeState(duration: 0)
                        }
                        else if (false == oddNumRows) && (false == isOddRow) {
                            // If there are an even number of rows in the item array, the stone blocks in the even rows should be stone
                            block.changeState(duration: 0)
                        }
                    }
                    else if item! is MysteryBlockItem {
                        let block = item! as! MysteryBlockItem
                        // Load the block's hit count
                        block.updateHitCount(count: itemHitCounts[i][j])
                    }
                    else if item! is BombItem {
                        // Don't need to do anything
                    }
                    else if item! is BallItem {
                        // Don't need to do anything
                    }
                    numItemsGenerated += 1
                }
                array.append(newRow)
            }
        }
        
        return array
    }
    
    /*
     I think this generates a number for blocks that ends up being the block's required hits before it breaks
     */
    private func randomNumber(upper: Int, lower: Int) -> Int {
        return Int(drand48() * 100) % (upper - lower + 1) + lower
    }
    
    // MARK: Public functions
    /*
     Big initializer; need to find a good way to test this stuff out since it's generating things based on a percentage.
     */
    required init(blockSize: CGSize, ballRadius: CGFloat, numberOfRows: Int, numItems: Int, state: DataManager.ItemGeneratorState?, useDrand: Bool = false, seed: Int = 0) {
        // XXX Change restoration URL to be optional; if it's nil, don't try to load any data
        // XXX Maybe this should only be something that the view is aware of
        self.blockSize = blockSize
        // XXX Same with this... something that only the view is aware of
        self.ballRadius = ballRadius
        self.numberOfRows = numberOfRows
        numItemsPerRow = numItems
        
        USE_DRAND = useDrand
        if USE_DRAND {
            srand48(seed)
        }
        
        if nil == state {
            // Try to load state and if not initialize things to their default values
            // Initialize the allowed item types with only one type for now
            addBlockItemType(type: ItemGenerator.HIT_BLOCK, percentage: 93)
            addBlockItemType(type: ItemGenerator.STONE_BLOCK, percentage: 5)
            // XXX Update this in the future; basically we only want this block introduced every 50 turns
            addBlockItemType(type: ItemGenerator.MYSTERY_BLOCK, percentage: 2)
            addNonBlockItemType(type: ItemGenerator.SPACER, percentage: 90)
            addNonBlockItemType(type: ItemGenerator.BALL, percentage: 8)
            addNonBlockItemType(type: ItemGenerator.BOMB, percentage: 2)

            igState = DataManager.ItemGeneratorState(numberOfBalls: numberOfBalls, itemTypeDict: itemTypeDict, itemArray: [], itemHitCountArray: [], blockTypeArray: blockTypeArray, nonBlockTypeArray: nonBlockTypeArray)
        }
        else {
            igState = state
        }
        
        // Set these global variables based on the item generator state
        self.numberOfBalls = igState!.numberOfBalls
        self.itemTypeDict = igState!.itemTypeDict
        self.blockTypeArray = igState!.blockTypeArray
        self.nonBlockTypeArray = igState!.nonBlockTypeArray
        
        // Load items into the item array based on our saved item array and item hit count array
        itemArray = loadItems(items: igState!.itemArray, itemHitCounts: igState!.itemHitCountArray, numberOfBalls: self.numberOfBalls)
    }
    
    /*
     Not sure if this is totally necessary anymore.. but it may be useful.
     Should use a switch statement instead these if/else ones though.
     */
    public func debugPrint() {
        var output = ""
        for row in itemArray {
            for item in row {
                if item is BallItem {
                    output += "[B]"
                }
                else if item is HitBlockItem {
                    output += "[H]"
                }
                else if item is StoneHitBlockItem {
                    output += "[T]"
                }
                else if item is MysteryBlockItem {
                    output += "[?]"
                }
                else if item is BombItem {
                    output += "[B]"
                }
                else if item is SpacerItem {
                    output += "[ ]"
                }
                else {
                    output += "[#]"
                }
            }
            output += "\n"
        }
        print(output)
    }
    
    /*
     This is sort of a helper function to make it easier to pick a random block type later on.
     The way it works at a high level is this:
     Create an array (with a total length of 100) of X block type, Y block type, and Z block type.
     Then we will randomly choose one element out of that array.
     There is likely a much better way to handle this.
     */
    public func addBlockItemType(type: Int, percentage: Int) {
        for _ in 1...percentage {
            blockTypeArray.append(type)
        }
    }
    
    /*
     Same as the function above, except this is done with non block item types.
     */
    public func addNonBlockItemType(type: Int, percentage: Int) {
        for _ in 1...percentage {
            nonBlockTypeArray.append(type)
        }
    }
    
    // Removes balls from the item generator's generation list
    /*
     Seems to reset the non block item array and then repopulate it with spacers and bombs.
     Again, if I could fix the way the code is randomly picking a type, then all we'd need to do here is just remove the
        ball type from the list of possibilities of non block type items.
     */
    public func removeBallTypeGeneration() {
        nonBlockTypeArray = []
        addNonBlockItemType(type: ItemGenerator.SPACER, percentage: 98)
        addNonBlockItemType(type: ItemGenerator.BOMB, percentage: 2)
    }
    
    /*
     Could probably be made simpler and have a variable keeping track of this.
     Could also maybe use filter, map, and count to accomplish this
     */
    public func getBlockCount() -> Int {
        var count = 0
        for row in itemArray {
            for item in row {
                if item is HitBlockItem || item is StoneHitBlockItem || item is MysteryBlockItem {
                    count += 1
                }
            }
        }
        
        return count
    }
    
    // Used by the model to reset the pattern difficulty distribution
    /*
     Resets the difficulty of items being generated. Basically makes the game a bit easier after making it more difficult
     */
    public func resetDifficulty() {
        easyPatternPercent = 65
        intermediatePatternPercent = 25
        hardPatternPercent = 10
    }
    
    /*
     Generates a new row of items.
     Massive function that could probably be simplified; it's very difficult to test.
     */
    public func generateRow(emptyRow: Bool = false) -> [Item] {
        var newRow: [Item] = []
        
        if emptyRow {
            for _ in 1...numItemsPerRow {
                newRow.append(SpacerItem())
            }
            itemArray.append(newRow)
            return newRow
        }
        
        // Pick from one of the pattern difficulties
        var pattern: [Int] = []
        var num = 0
        if USE_DRAND {
            num = randomNumber(upper: 100, lower: 1)
        }
        else {
            num = Int.random(in: 1...100)
        }
        
        if num < getEasyPatternPercent() {
            // Easy pattern
            if USE_DRAND {
                let choice = randomNumber(upper: ItemGenerator.EASY_PATTERNS.count - 1, lower: 0)
                pattern = ItemGenerator.EASY_PATTERNS[choice]
            }
            else {
                pattern = ItemGenerator.EASY_PATTERNS.randomElement()!

            }
        }
        else if (num >= getEasyPatternPercent()) && (num < getIntermediatePatternPercent()) {
            // Medium pattern
            if USE_DRAND {
                let choice = randomNumber(upper: ItemGenerator.INTERMEDIATE_PATTERNS.count - 1, lower: 0)
                pattern = ItemGenerator.INTERMEDIATE_PATTERNS[choice]
            }
            else {
                pattern = ItemGenerator.INTERMEDIATE_PATTERNS.randomElement()!
            }
        }
        else { // num is >= intermediatePatternPercent so pick a hard pattern
            // Hard pattern
            if USE_DRAND {
                let choice = randomNumber(upper: ItemGenerator.HARD_PATTERNS.count - 1, lower: 0)
                pattern = ItemGenerator.HARD_PATTERNS[choice]
            }
            else {
                pattern = ItemGenerator.HARD_PATTERNS.randomElement()!
            }
        }
        
        // Slot counter
        var i = 0
        while i < numItemsPerRow {
            // Loop over the pattern (it could <= numItemsPerRow so we don't want to make assumptions about size)
            for j in 0...(pattern.count - 1) {
                var item: Item
                // Generate the item
                if 1 == pattern[j] {
                    // If it's a 1, generate a block type
                    if USE_DRAND {
                        let choice = randomNumber(upper: blockTypeArray.count - 1, lower: 0)
                        let itemType = blockTypeArray[choice]
                        item = generateItem(itemType: itemType)!
                    }
                    else {
                        let itemType = blockTypeArray.randomElement()!
                        item = generateItem(itemType: itemType)!
                    }
                }
                else {
                    // Generate a non-block type
                    if USE_DRAND {
                        let choice = randomNumber(upper: nonBlockTypeArray.count - 1, lower: 0)
                        let itemType = nonBlockTypeArray[choice]
                        item = generateItem(itemType: itemType)!
                    }
                    else {
                        let itemType = nonBlockTypeArray.randomElement()!
                        item = generateItem(itemType: itemType)!
                    }
                }
                
                // Add the item to the row
                newRow.append(item)
                if false == (item is SpacerItem) {
                    // If it's anything but a spacer item, increase the number of items generated
                    numItemsGenerated += 1
                }
                
                // Increment our row slot counter (we want to stop at numItemsPerRow)
                i += 1
                if i == numItemsPerRow {
                    break
                }
            }
        }
        
        // Append the new row to the generator's item array
        itemArray.append(newRow)
        
        // Return the newly generated row
        return newRow
    }
    
    /*
     Super simple; not sure if it needs its own function.
     */
    public func setOnFireBonus(_ flag: Bool) {
        ballsOnFire = flag
    }
    
    /*
     Handle two items colliding.
     Could probably move each hit action into a separate function tied to the specific item type.
     */
    public func hit(name: String) -> Bool {
        var successfulHit = true
        
        for row in itemArray {
            for item in row {
                if item.getNode().name == name {
                    item.hitItem()
                    if item.getNode().name!.starts(with: "block") {
                        if ballsOnFire {
                            // If balls are on fire, process a second hit against the blocks (ball hits are x2 when they're on fire)
                            item.hitItem()
                        }
                    }
                    else if item.getNode().name!.starts(with: "sblock") {
                        // This is a stone hit block item
                        let shb = item as! StoneHitBlockItem
                        if shb.isStone {
                            successfulHit = false
                        }
                        if ballsOnFire {
                            // If balls are on fire, process a second hit against the blocks (ball hits are x2 when they're on fire)
                            item.hitItem()
                        }
                    }
                    else if item.getNode().name!.starts(with: "bomb") {
                        // If a bomb item was hit, clear all adjacent items
                        let bomb = item as! BombItem
                        if false == bomb.hitWasProcessed {
                            // hitWasProcessed is a boolean so we don't run in an infinite loop/recursion where we keep calling the hit function for the same item
                            bomb.hitWasProcessed = true
                            clearAdjacentItems(to: item)
                        }
                    }
                    else if item.getNode().name!.starts(with: "mblock") {
                        if ballsOnFire {
                            // If balls are on fire, process a second hit against the blocks (ball hits are x2 when they're on fire)
                            item.hitItem()
                        }
                        
                        // Check if the block's hitCount is 0 and we should remove all items in its row
                        let block = item as! MysteryBlockItem
                        if (block.hitCount! <= 0) && (false == block.hitWasProcessed) {
                            // hitWasProcessed is a boolean so we don't run in an infinite loop/recursion where we keep calling the hit function for the same item
                            block.hitWasProcessed = true
                            let rewardType = block.getReward()
                            // Based on the reward type, we need to take different actions
                            if MysteryBlockItem.CLEAR_ROW_REWARD == rewardType {
                                clearRowItems(item: item)
                            }
                            else if MysteryBlockItem.CLEAR_COLUMN_REWARD == rewardType {
                                clearColumnItems(item: item)
                            }
                        }
                    }
                    
                    // Break out only if we found the item
                    return successfulHit
                }
            }
        }
        
        // If we fall through to here, we didn't find the item so don't count it as a hit
        return false
    }
    
    /*
     Very simple; probably doesn't need its own function
     */
    public func updateBallCount(count: Int) {
        // This is used to address a bug in which the number of balls and the hit count diverge
        numberOfBalls = count
    }
    
    // This function is responsible for pruning any items in the first row; once the item generator has numberOfRows - 1 rows in its array, any non-block items are removed from the game scene and will need to be removed from here as well
    /*
     Prunes the bottom-most row of blocks, but not balls or bombs (I think); unclear on the context and why it's called.
     It's always called after animateItems() function
     */
    public func pruneFirstRow() {
        if itemArray.count == (numberOfRows - 1) {
            let row = itemArray[0]
            let newRow = row.filter {
                if ($0 is BallItem) || ($0 is BombItem) {
                    return false
                }
                return true
            }
            itemArray[0] = newRow
        }
    }
    
    // Looks for items that should be removed; each Item keeps track of its state and whether or not it's time for it to be removed.
    // If item.removeItem() returns true, it's time to remove the item; it will be added to an array of items that have been removed and returned to the model
    // XXX In the future, change the return type to be either [(Item, CGPoint)], or a Dictionary<Item, CGPoint>
    /*
     Looks for items that should be removed, as stated by comment above, and returns all items that were removed.
     The function name could be changed so it's a little more clear about what it does.
     It sounds like it should remove a specified list of items.
     Probably difficult to test, should be improved.
     */
    public func removeItems() -> [(Item, Int, Int)] {
        var removedItems: [(Item, Int, Int)] = []
        
        // Return out so we don't cause an error with the loop logic below
        if itemArray.isEmpty {
            return removedItems
        }
        
        for i in 0...(itemArray.count - 1) {
            let row = itemArray[i]
            var newRow: [Item] = []
            
            // Remove items that should be removed and add them to an array that we will return
            // If an item is removed, replace it with a spacer item
            var j = 0
            let _ = row.filter {
                // Perform a remove action if needed
                if $0.removeItem() {
                    // Remove this item from the array if that evaluates to true (meaning it's time to remove the item)
                    let group = ($0, i, j)
                    j += 1
                    removedItems.append(group)
                    // Replace it with a spacer item
                    let item = SpacerItem()
                    newRow.append(item)
                    return false
                }
                // Keep this item in the array
                newRow.append($0)
                j += 1
                return true
            }
            
            // Assign the newly created row to this index
            itemArray[i] = newRow
        }
        
        // After removing all necessary items, check to see if there any empty rows that can be removed
        removeEmptyRows()
        
        // Return all items that were removed
        return removedItems
    }
    
    /*
     Function could probably be renamed, but I think this removes the bottom 3 rows to save a user before they lose.
     */
    public func saveUser() -> [Item] {
        var removedItems: [Item] = []
        for _ in 1...4 {
            let items = itemArray.remove(at: 0)
            for item in items {
                removedItems.append(item)
            }
        }
        
        removeEmptyRows()
        
        return removedItems
    }
    
    // MARK: Private functions
    // Actually generate the item to be placed in the array
    /*
     Generates an item; I don't think this should return an optional. The default case could maybe be the SpacerItem.
     Should be relatively easy to test.
     Could have separate models for each item type that is responsible for initializing itself.
     */
    private func generateItem(itemType: Int) -> Item? {
        switch itemType {
        case ItemGenerator.SPACER:
            let item = SpacerItem()
            return item
        case ItemGenerator.HIT_BLOCK:
            let item = HitBlockItem()
            item.initItem(num: numItemsGenerated, size: blockSize!)
            let block = item as HitBlockItem
            let choices = [numberOfBalls, numberOfBalls * 2, numberOfBalls, numberOfBalls * 2, numberOfBalls * 2]
            if USE_DRAND {
                let choice = randomNumber(upper: choices.count - 1, lower: 0)
                block.setHitCount(count: choices[choice])
            }
            else {
                block.setHitCount(count: choices.randomElement()!)
            }
            return item
        case ItemGenerator.STONE_BLOCK:
            let item = StoneHitBlockItem()
            item.initItem(num: numItemsGenerated, size: blockSize!)
            let block = item as StoneHitBlockItem
            let choices = [numberOfBalls, numberOfBalls * 2, numberOfBalls, numberOfBalls * 2, numberOfBalls * 2]
            if USE_DRAND {
                let choice = randomNumber(upper: choices.count - 1, lower: 0)
                block.setHitCount(count: choices[choice])
            }
            else {
                block.setHitCount(count: choices.randomElement()!)
            }
            return item
        case ItemGenerator.MYSTERY_BLOCK:
            let item = MysteryBlockItem()
            item.initItem(num: numItemsGenerated, size: blockSize!)
            let block = item as MysteryBlockItem
            let choices = [numberOfBalls, numberOfBalls * 2, numberOfBalls, numberOfBalls * 2, numberOfBalls * 2]
            if USE_DRAND {
                let choice = randomNumber(upper: choices.count - 1, lower: 0)
                block.setHitCount(count: choices[choice])
            }
            else {
                block.setHitCount(count: choices.randomElement()!)
            }
            return item
        case ItemGenerator.BOMB:
            let item = BombItem()
            item.initItem(num: numItemsGenerated, size: blockSize!)
            return item
        case ItemGenerator.BALL:
            let size = CGSize(width: ballRadius!, height: ballRadius!)
            let item = BallItem()
            item.initItem(num: numItemsGenerated, size: size)
            return item
        default:
            return nil
        }
    }
    
    /*
     These next 3 functions seem okay for now.
     */
    private func getEasyPatternPercent() -> Int {
        return easyPatternPercent
    }
    
    private func getIntermediatePatternPercent() -> Int {
        return (easyPatternPercent + intermediatePatternPercent)
    }
    
    private func getHardPatternPercent() -> Int {
        return (easyPatternPercent + intermediatePatternPercent + hardPatternPercent)
    }
    
    // Finds the row index of a given item or nil if it wasn't found (it shouldn't ever return nil, but just in case)
    /*
     I guess it's okay that this can return nil. But we should be confident enough in the code to know for sure whether or not the item still exists.
     If there's no chance it could accidentally be removed, then we can return an Int that isn't an optional.
     */
    private func findItemRowIndex(_ item: Item) -> Int? {
        if 0 == itemArray.count {
            return nil
        }
        
        let itemName = item.getNode().name!
        
        for i in 0...(itemArray.count - 1) {
            let row = itemArray[i]
            let foundItem = row.contains { $0.getNode().name! == itemName }
            if foundItem {
                return i
            }
        }
        
        return nil
    }
    
    // Find the item's index within its row (shouldn't ever return nil, but it should be checked anyways)
    /*
     Same as function from above; we should know for sure whether or not the item can still be in the item array.
     */
    private func itemIndexInRow(lookFor: Item, rowIndex: Int) -> Int? {
        let name = lookFor.getNode().name!
        let row = itemArray[rowIndex]
        for i in 0...(row.count - 1) {
            let item = row[i]
            if name == item.getNode().name! {
                return i
            }
        }
        
        return nil
    }
    
    /*
     This is how we need to remove empty rows. If we have rows of items like these:
     [H] [S] [S] [B]
     [S] [S] [H] [S]
     [H] [S] [S] [H]
     (where H == hit block, B == ball, and S == spacer item)
     
     And we break the hit block in the 2nd row, we want that row to remain all spacer items in
     the event that we quit the game and come back. If we just remove that row as soon as it's
     empty and quit the game and have the item generator reload, the rows will look like this:
     [H] [S] [S] [B]
     [H] [S] [S] [H]
     
     which is incorrect. The layout of the items should be exactly the same.
     */
    /*
     Self explanatory; should be testable. We shouldn't use a "while true" loop though.
     */
    private func removeEmptyRows() {
        while true {
            // If there are no rows left, return out
            if 0 == itemArray.count {
                return
            }
            
            let row = itemArray[0]
            for item in row {
                if item is SpacerItem {
                    continue
                }
                // As soon as we get to a row that doesn't just contain spacer items, return
                return
            }
            // If it is empty, remove it from the array and loop around to check the row before that
            let _ = itemArray.remove(at: 0)
        }
    }
    
    // This could be improved and refactored
    /*
     I think this is used for Bombs when they explode. It needs to destroy adjacent items.
     Guarantee that this function is horribly inefficient and can be improved.
     It should be testable though; maybe it should return the adjacent items and another function should remove them.
     */
    private func clearAdjacentItems(to: Item) {
        var adjacentItems: [Item] = []
        
        // 1. Find the row that the item is in
        // 2. Find the index of the item in that row
        // 3. Find (rowIndex - 1) and get the items at (itemIndex - 1, itemIndex, and itemIndex + 1)
        // 4. Find rowIndex and get the items at (itemIndex - 1 and itemIndex + 1)
        // 5. Find (rowIndex + 1) and get the items at (itemIndex - 1, itemIndex, and itemIndex + 1)
        // 6. Return that list
        
        // Find the row index of the item if it exists
        if let rowIndex = findItemRowIndex(to) {
            // Find the item's index in that row
            if let itemIndex = itemIndexInRow(lookFor: to, rowIndex: rowIndex) {
                // Iterate over all the rows in the item array
                for i in 0...(itemArray.count - 1) {
                    // If the row is before or after the item's row, add items at (itemIndex - 1, itemIndex, and itemIndex + 1)
                    if (i == (rowIndex - 1)) || (i == (rowIndex + 1)) {
                        // Iterate over the row to find adjacent items
                        let row = itemArray[i]
                        for j in 0...(row.count - 1) {
                            if (j == (itemIndex - 1)) || (j == (itemIndex)) || (j == (itemIndex + 1)) {
                                adjacentItems.append(row[j])
                            }
                        }
                    }
                        // If this is the row the item is in, we just need to find the item before it and after it
                    else if (i == rowIndex) {
                        let row = itemArray[i]
                        for j in 0...(row.count - 1) {
                            if (j == (itemIndex - 1)) || (j == (itemIndex + 1)) {
                                adjacentItems.append(row[j])
                            }
                        }
                    }
                }
            }
        }
        
        for item in adjacentItems {
            if item is HitBlockItem {
                let hitBlock = item as! HitBlockItem
                hitBlock.hitCount! = 0
            }
            // Set stone block item count to 0
            else if item is StoneHitBlockItem {
                let stoneBlock = item as! StoneHitBlockItem
                stoneBlock.hitCount! = 0
            }
            else if item is MysteryBlockItem {
                let mysteryBlock = item as! MysteryBlockItem
                // Reduce the item count down to 0
                mysteryBlock.hitCount! = 0
                if false == mysteryBlock.hitWasProcessed {
                    mysteryBlock.hitWasProcessed = true
                    let rewardType = mysteryBlock.getReward()
                    if MysteryBlockItem.CLEAR_ROW_REWARD == rewardType {
                        clearRowItems(item: mysteryBlock)
                    }
                    else if MysteryBlockItem.CLEAR_COLUMN_REWARD == rewardType {
                        clearColumnItems(item: mysteryBlock)
                    }
                }
            }
            else if item is BombItem {
                let bomb = item as! BombItem
                if false == bomb.hitWasProcessed {
                    // Process the bomb hit
                    clearAdjacentItems(to: item)
                    bomb.hitWasProcessed = true
                }
            }
        }
    }
    
    /*
     I think this function was introduced to handle when a mystery block breaks.
     One type of mystery block clears out an entire row, and this handles removing items in the same row as that mystery block.
     Should be more easily testable; should return items to be removed, and then have another function actually remove those items.
     */
    private func clearRowItems(item: Item) {
        // Remove all items in the row
        var items: [Item] = []
        for row in itemArray {
            for i in row {
                if i.getNode().name! == item.getNode().name! {
                    items = row
                    break
                }
            }
        }
        
        // Now that we have the items, mark the items in the row as being hit
        for i in items {
            if i is HitBlockItem {
                let hitBlock = i as! HitBlockItem
                hitBlock.hitCount! = 0
            }
                // Set stone block item count to 0
            else if i is StoneHitBlockItem {
                let stoneBlock = i as! StoneHitBlockItem
                stoneBlock.hitCount! = 0
            }
            else if i is MysteryBlockItem {
                // This item is in the same row so we don't need to do any special processing here
                let mysteryBlock = i as! MysteryBlockItem
                mysteryBlock.hitCount! = 0
            }
            else if i is BombItem {
                let bomb = i as! BombItem
                if false == bomb.hitWasProcessed {
                    // Hit the item first
                    bomb.hitItem()
                    
                    // Then process the bomb hit
                    clearAdjacentItems(to: i)
                    bomb.hitWasProcessed = true
                }
            }
        }
    }
    
    /*
     Same as above, but clears out a column of items instead of a row.
     */
    private func clearColumnItems(item: Item) {
        // Remove all items in the row
        var items: [Item] = []
        var columnIndex = Int(0)
        
        // First find the exact column index
        for row in itemArray {
            for i in 0...(row.count - 1) {
                let rowItem = row[i]
                if rowItem.getNode().name! == item.getNode().name! {
                    columnIndex = i
                    break
                }
            }
        }
        
        // Second, get all items in that column
        for row in itemArray {
            items.append(row[columnIndex])
        }
        
        // Now that we have the items, mark the items in the row as being hit
        for i in items {
            if i is HitBlockItem {
                let hitBlock = i as! HitBlockItem
                hitBlock.hitCount! = 0
            }
                // Set stone block item count to 0
            else if i is StoneHitBlockItem {
                let stoneBlock = i as! StoneHitBlockItem
                stoneBlock.hitCount! = 0
            }
            else if i is MysteryBlockItem {
                // This item is in the same row so we don't need to do any special processing here
                let mysteryBlock = i as! MysteryBlockItem
                mysteryBlock.hitCount! = 0
            }
            else if i is BombItem {
                let bomb = i as! BombItem
                if false == bomb.hitWasProcessed {
                    // Hit the item first
                    bomb.hitItem()
                    
                    // Then process the bomb hit
                    clearAdjacentItems(to: i)
                    bomb.hitWasProcessed = true
                }
            }
        }
    }
}
