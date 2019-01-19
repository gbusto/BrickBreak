//
//  ItemGenerator.swift
//  Ballz1
//
//  Created by Gabriel Busto on 9/18/18.
//  Copyright © 2018 Self. All rights reserved.
//

import SpriteKit
import GameplayKit

class ItemGenerator {
    
    // -------------------------------------------------------------
    // MARK: Public properties
    
    // Rows of items for which this generator is responsible
    public var itemArray: [[Item]] = []
    
    // Maximum hit count for a HitBlock
    public var numberOfBalls = Int(10)
    
    // These variables can be used to tweak the pattern distribution as needed
    // These are used by the model to tweak pattern difficulty distribution
    public var hardPatternPercent = 10
    public var intermediatePatternPercent = 25
    public var easyPatternPercent = 65
    
    // -------------------------------------------------------------
    // MARK: Private attributes
    private var igState: ItemGeneratorState?
    static let ItemGeneratorPath = "ItemGenerator"
    
    // Number of items to fit on each row
    private var numItemsPerRow = Int(0)
    
    private var numberOfRows = Int(0)
    
    // Number of items that this generator has generated
    private var numItemsGenerated = Int(0)
    
    private var blockSize: CGSize?
    private var ballRadius: CGFloat?
    
    // Item types that this generator can generate; for example, after 100 turns, maybe you want to start adding special kinds of blocks
    // The format is [ITEM_TYPE: PERCENTAGE_TO_GENERATE]
    private var itemTypeDict: [Int: Int] = [:]
    
    // There exist as many block types in this array as its percentage; for example, if hit blocks have a 65% chance of being selected, there will be 65 hit blocks in this array
    private var blockTypeArray: [Int] = []
    // This works the same as the above array, but this is only for non block item types (balls, spacer items, etc)
    private var nonBlockTypeArray: [Int] = []
    
    private var prevTurnState = ItemGeneratorPrevTurn(itemArray: [], itemHitCountArray: [], numberOfBalls: 0)
    
    // These should probably be some kind of enum
    // Used to mark item types to know what item types are allowed to be generated
    private static let SPACER = Int(0)
    private static let HIT_BLOCK = Int(1)
    private static let BALL = Int(2)
    private static let STONE_BLOCK = Int(3)
    private static let BOMB = Int(4)
    
    
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
    struct ItemGeneratorState: Codable {
        var numberOfBalls: Int
        var itemTypeDict: [Int: Int]
        // An array of tuples where index 0 is the item type (SPACER, HIT_BLOCK, BALL, etc) and index 1 is the hit block count (it's only really needed for hit block items)
        var itemArray: [[Int]]
        var itemHitCountArray: [[Int]]
        var blockTypeArray: [Int]
        var nonBlockTypeArray: [Int]
        
        enum CodingKeys: String, CodingKey {
            case numberOfBalls
            case itemTypeDict
            case itemArray
            case itemHitCountArray
            case blockTypeArray
            case nonBlockTypeArray
        }
    }
    
    // The struct for stuff needed to restore state from the previous turn
    struct ItemGeneratorPrevTurn {
        var itemArray: [[Int]]
        var itemHitCountArray: [[Int]]
        var numberOfBalls: Int
    }
    
    // Backs up the items (used for saving state and restoring user's previous turn)
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
    
    public func saveState(restorationURL: URL) {
        let url = restorationURL.appendingPathComponent(ItemGenerator.ItemGeneratorPath)
        do {
            igState!.numberOfBalls = numberOfBalls
            igState!.itemTypeDict = itemTypeDict
            
            // Backup the item array
            let backedUpItems = backupItems()
            
            igState!.itemArray = backedUpItems.itemArray
            igState!.itemHitCountArray = backedUpItems.itemHitCountArray
            igState!.blockTypeArray = blockTypeArray
            igState!.nonBlockTypeArray = nonBlockTypeArray
            
            let data = try PropertyListEncoder().encode(igState!)
            try data.write(to: url)
        }
        catch {
            print("Failed to save item generator state: \(error)")
        }
    }
    
    public func saveTurnState() {
        // Backup the items into this state struct
        prevTurnState = backupItems()
    }
    
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
    
    public func loadState(restorationURL: URL) -> Bool {
        do {
            let data = try Data(contentsOf: restorationURL)
            igState = try PropertyListDecoder().decode(ItemGeneratorState.self, from: data)
            return true
        }
        catch {
            print("Failed to load item generator state: \(error)")
            return false
        }
    }
    
    // Gets the item count (doesn't include spacer items)
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
    private func loadItems(items: [[Int]], itemHitCounts: [[Int]], numberOfBalls: Int) -> [[Item]] {
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
    
    // MARK: Public functions
    required init(blockSize: CGSize, ballRadius: CGFloat, numberOfBalls: Int, numberOfRows: Int, numItems: Int, restorationURL: URL) {
        // XXX Change restoration URL to be optional; if it's nil, don't try to load any data
        self.blockSize = blockSize
        self.ballRadius = ballRadius
        self.numberOfRows = numberOfRows
        numItemsPerRow = numItems
        
        let url = restorationURL.appendingPathComponent(ItemGenerator.ItemGeneratorPath)
        // Try to load state and if not initialize things to their default values
        if false == loadState(restorationURL: url) {
            // Initialize the allowed item types with only one type for now
            addBlockItemType(type: ItemGenerator.HIT_BLOCK, percentage: 95)
            addBlockItemType(type: ItemGenerator.STONE_BLOCK, percentage: 5)
            addNonBlockItemType(type: ItemGenerator.SPACER, percentage: 90)
            addNonBlockItemType(type: ItemGenerator.BALL, percentage: 8)
            addNonBlockItemType(type: ItemGenerator.BOMB, percentage: 2)
            
            igState = ItemGeneratorState(numberOfBalls: numberOfBalls, itemTypeDict: itemTypeDict, itemArray: [], itemHitCountArray: [], blockTypeArray: blockTypeArray, nonBlockTypeArray: nonBlockTypeArray)
        }
        
        // Set these global variables based on the item generator state
        self.numberOfBalls = igState!.numberOfBalls
        self.itemTypeDict = igState!.itemTypeDict
        self.blockTypeArray = igState!.blockTypeArray
        self.nonBlockTypeArray = igState!.nonBlockTypeArray
        
        // Load items into the item array based on our saved item array and item hit count array
        itemArray = loadItems(items: igState!.itemArray, itemHitCounts: igState!.itemHitCountArray, numberOfBalls: numberOfBalls)
    }
    
    public func addBlockItemType(type: Int, percentage: Int) {
        for _ in 1...percentage {
            blockTypeArray.append(type)
        }
    }
    
    public func addNonBlockItemType(type: Int, percentage: Int) {
        for _ in 1...percentage {
            nonBlockTypeArray.append(type)
        }
    }
    
    public func getBlockCount() -> Int {
        var count = 0
        for row in itemArray {
            for item in row {
                if item is HitBlockItem {
                    count += 1
                }
            }
        }
        
        return count
    }
    
    // Used by the model to reset the pattern difficulty distribution
    public func resetDifficulty() {
        easyPatternPercent = 65
        intermediatePatternPercent = 25
        hardPatternPercent = 10
    }
    
    public func generateRow() -> [Item] {
        var newRow: [Item] = []
        
        // Pick from one of the pattern difficulties
        var pattern: [Int] = []
        let num = Int.random(in: 1...100)
        if num < getEasyPatternPercent() {
            // Easy pattern
            pattern = ItemGenerator.EASY_PATTERNS.randomElement()!
        }
        else if (num >= getEasyPatternPercent()) && (num < getIntermediatePatternPercent()) {
            // Medium pattern
            pattern = ItemGenerator.INTERMEDIATE_PATTERNS.randomElement()!
        }
        else { // num is >= intermediatePatternPercent so pick a hard pattern
            // Hard pattern
            pattern = ItemGenerator.HARD_PATTERNS.randomElement()!
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
                    let itemType = blockTypeArray.randomElement()!
                    item = generateItem(itemType: itemType)!
                }
                else {
                    // Generate a non-block type
                    let itemType = nonBlockTypeArray.randomElement()!
                    item = generateItem(itemType: itemType)!
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
    
    public func hit(name: String) {
        for row in itemArray {
            for item in row {
                if item.getNode().name == name {
                    item.hitItem()
                    if item.getNode().name!.starts(with: "ball") {
                        // If this item was a ball, increase the max hit count by 2 because it will be transferred over to the ball manager
                        numberOfBalls += 1
                    }
                    else if item.getNode().name!.starts(with: "bomb") {
                        // If a bomb item was hit, get all adjacent items
                        let items = getAdjacentItems(to: item)
                        // Iterate over each item
                        for item in items {
                            // Set hit block item count to 0
                            if item is HitBlockItem {
                                let hitBlock = item as! HitBlockItem
                                hitBlock.hitCount! = 0
                            }
                            // Set stone block item count to 0
                            else if item is StoneHitBlockItem {
                                let stoneBlock = item as! StoneHitBlockItem
                                stoneBlock.hitCount! = 0
                            }
                        }
                    }
                }
            }
        }
    }
    
    // This function is responsible for pruning any items in the first row; once the item generator has numberOfRows - 1 rows in its array, any non-block items are removed from the game scene and will need to be removed from here as well
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
    public func removeItems() -> [Item] {
        var removedItems : [Item] = []
        
        // Return out so we don't cause an error with the loop logic below
        if itemArray.isEmpty {
            return removedItems
        }
        
        for i in 0...(itemArray.count - 1) {
            let row = itemArray[i]
            var newRow: [Item] = []
            
            // Remove items that should be removed and add them to an array that we will return
            // If an item is removed, replace it with a spacer item
            let _ = row.filter {
                // Perform a remove action if needed
                if $0.removeItem() {
                    // Remove this item from the array if that evaluates to true (meaning it's time to remove the item)
                    removedItems.append($0)
                    // Replace it with a spacer item
                    let item = SpacerItem()
                    newRow.append(item)
                    return false
                }
                // Keep this item in the array
                newRow.append($0)
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
    
    public func saveUser() -> [Item] {
        let removedItems = itemArray.remove(at: 0)
        removeEmptyRows()
        
        return removedItems
    }
    
    // MARK: Private functions
    // Actually generate the item to be placed in the array
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
            block.setHitCount(count: choices.randomElement()!)
            return item
        case ItemGenerator.STONE_BLOCK:
            let item = StoneHitBlockItem()
            item.initItem(num: numItemsGenerated, size: blockSize!)
            let block = item as StoneHitBlockItem
            let choices = [numberOfBalls, numberOfBalls * 2, numberOfBalls, numberOfBalls * 2, numberOfBalls * 2]
            block.setHitCount(count: choices.randomElement()!)
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
    
    // This could be improved and refactored
    private func getAdjacentItems(to: Item) -> [Item] {
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
        
        return adjacentItems
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
}
