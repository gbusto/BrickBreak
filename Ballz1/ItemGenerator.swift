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
    
    // -------------------------------------------------------------
    // MARK: Private attributes
    private var igState: ItemGeneratorState?
    static let ItemGeneratorPath = "ItemGenerator"
    
    // Number of items to fit on each row
    private var numItemsPerRow = Int(0)
    // The minimum number of items per row
    private var minItemsPerRow = Int(2)
    
    // Number of items that this generator has generated
    private var numItemsGenerated = Int(0)
    
    private var blockSize: CGSize?
    private var ballRadius: CGFloat?
    
    // Item types that this generator can generate; for example, after 100 turns, maybe you want to start adding special kinds of blocks
    // The format is [ITEM_TYPE: PERCENTAGE_TO_GENERATE]
    private var itemTypeDict: [Int: Int] = [:]
    
    // There exist as many block types in this array as its percentage; for example, if hit blocks have a 65% chance of being selected, there will be 65 hit blocks in this array
    private var blockTypeArray: [Int] = []
    // This works the same as the above array, but this is only for non block item types (currency, balls, spacer items, etc)
    private var nonBlockTypeArray: [Int] = []
    
    // Used to mark item types to know what item types are allowed to be generated
    private static let SPACER = Int(0)
    private static let HIT_BLOCK = Int(1)
    private static let BALL = Int(2)
    private static let CURRENCY = Int(3)
    
    // An Int to let holder of this object know when the ItemGenerator is ready
    private var actionsStarted = Int(0)
    
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
    
    public func saveState(restorationURL: URL) {
        let url = restorationURL.appendingPathComponent(ItemGenerator.ItemGeneratorPath)
        do {
            igState!.numberOfBalls = numberOfBalls
            igState!.itemTypeDict = itemTypeDict
            
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
                    else if item is BallItem {
                        newItemRow.append(ItemGenerator.BALL)
                        itemHitCountRow.append(0)
                    }
                    else if item is CurrencyItem {
                        newItemRow.append(ItemGenerator.CURRENCY)
                        itemHitCountRow.append(0)
                    }
                }
                savedItemArray.append(newItemRow)
                savedHitCountArray.append(itemHitCountRow)
            }
            
            igState!.itemArray = savedItemArray
            igState!.itemHitCountArray = savedHitCountArray
            igState!.blockTypeArray = blockTypeArray
            igState!.nonBlockTypeArray = nonBlockTypeArray
            
            let data = try PropertyListEncoder().encode(igState!)
            try data.write(to: url)
            print("Saved item generator state")
        }
        catch {
            print("Failed to save item generator state: \(error)")
        }
    }
    
    public func loadState(restorationURL: URL) -> Bool {
        do {
            let data = try Data(contentsOf: restorationURL)
            igState = try PropertyListDecoder().decode(ItemGeneratorState.self, from: data)
            print("Loaded item generator state")
            return true
        }
        catch {
            print("Failed to load item generator state: \(error)")
            return false
        }
    }
    
    // MARK: Public functions
    required init(blockSize: CGSize, ballRadius: CGFloat, numberOfBalls: Int, numItems: Int, restorationURL: URL) {
        self.blockSize = blockSize
        self.ballRadius = ballRadius
        numItemsPerRow = numItems
        
        let url = restorationURL.appendingPathComponent(ItemGenerator.ItemGeneratorPath)
        // Try to load state and if not initialize things to their default values
        if false == loadState(restorationURL: url) {
            // Initialize the allowed item types with only one type for now
            addBlockItemType(type: ItemGenerator.HIT_BLOCK, percentage: 100)
            addNonBlockItemType(type: ItemGenerator.SPACER, percentage: 80)
            addNonBlockItemType(type: ItemGenerator.CURRENCY, percentage: 10)
            addNonBlockItemType(type: ItemGenerator.BALL, percentage: 10)
            
            igState = ItemGeneratorState(numberOfBalls: numberOfBalls, itemTypeDict: itemTypeDict, itemArray: [], itemHitCountArray: [], blockTypeArray: blockTypeArray, nonBlockTypeArray: nonBlockTypeArray)
        }
        
        // Set these global variables based on the item generator state
        self.numberOfBalls = igState!.numberOfBalls
        self.itemTypeDict = igState!.itemTypeDict
        self.blockTypeArray = igState!.blockTypeArray
        self.nonBlockTypeArray = igState!.nonBlockTypeArray
        
        // Load items into the item array based on our saved item array and item hit count array
        if igState!.itemArray.count > 0 {
            for i in 0...(igState!.itemArray.count - 1) {
                var newRow: [Item] = []
                let row = igState!.itemArray[i]
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
                        block.updateHitCount(count: igState!.itemHitCountArray[i][j])
                    }
                    else if item! is BallItem {
                        // Don't need to do anything
                    }
                    else if item! is CurrencyItem {
                        // Don't need to do anything
                    }
                    numItemsGenerated += 1
                }
                print("Added new row to the item array")
                itemArray.append(newRow)
            }
        }
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
    
    public func generateRow() -> [Item] {
        var newRow: [Item] = []
        
        // Pick from one of the pattern difficulties
        var pattern: [Int] = []
        let num = Int.random(in: 1...100)
        if num < 65 {
            // Easy pattern
            pattern = ItemGenerator.EASY_PATTERNS.randomElement()!
        }
        else if (num >= 65) && (num < 90) {
            // Medium pattern
            pattern = ItemGenerator.INTERMEDIATE_PATTERNS.randomElement()!
        }
        else if (num >= 90) {
            // Hard pattern
            pattern = ItemGenerator.HARD_PATTERNS.randomElement()!
        }
                
        var i = 0
        var str = ""
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
                
                // DEBUG
                if item is SpacerItem {
                    str += "[S]"
                }
                // DEBUG
                else if item is CurrencyItem {
                    str += "[C]"
                }
                // DEBUG
                else if item is BallItem {
                    str += "[B]"
                }
                // DEBUG
                else if item is HitBlockItem {
                    str += "[H]"
                }
                else {
                    str += "[?]"
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
        
        // DEBUG
        print(str)
        
        // Return the newly generated row
        return newRow
    }
    
    public func animateItems(_ action: SKAction) {
        // This count will not include spacer items, so they should be skipped in the animation loop below
        actionsStarted = getItemCount()
        
        for row in itemArray {
            for item in row {
                if item is SpacerItem {
                    // SpacerItems aren't included in the actionsStarted count so skip their animation here
                    continue
                }
                
                // If the item is invisible, have it fade in
                if 0 == item.getNode().alpha {
                    // If this is the newest row
                    let fadeIn = SKAction.fadeIn(withDuration: 1)
                    item.getNode().run(SKAction.group([fadeIn, action])) {
                        self.actionsStarted -= 1
                    }
                }
                else {
                    item.getNode().run(action) {
                        self.actionsStarted -= 1
                    }
                }
            }
        }
    }
    
    public func isReady() -> Bool {
        // This is used to prevent the user from shooting while the block manager isn't ready yet
        return (0 == actionsStarted)
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
                }
            }
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
        //removeEmptyRows()
        removeEmptyRows()
        
        // Return all items that were removed
        return removedItems
    }
    
    // Iterate over all items to see if any are within (rowHeight * numRows) of the floor
    // Returns true if it can items, false otherwise
    public func canAddItems(_ floor: CGFloat, _ rowHeight: CGFloat, _ numRows: Int) -> Bool {
        for row in itemArray {
            for item in row {
                // We don't care about spacer items
                if item is SpacerItem {
                    continue
                }
                
                if (item.getNode().position.y - (rowHeight * CGFloat(numRows))) < floor {
                    return false
                }
            }
        }
        print("New number of rows \(itemArray.count)")
        
        return true
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
            let choices = [numberOfBalls, numberOfBalls * 2, numberOfBalls, numberOfBalls * 2]
            block.setHitCount(count: choices.randomElement()!)
            return item
        case ItemGenerator.BALL:
            let size = CGSize(width: ballRadius!, height: ballRadius!)
            let item = BallItem()
            item.initItem(num: numItemsGenerated, size: size)
            return item
        case ItemGenerator.CURRENCY:
            let item = CurrencyItem()
            item.initItem(num: numItemsGenerated, size: blockSize!)
            return item
        default:
            return nil
        }
    }
    
    // Gets the item count (doesn't include spacer items)
    private func getItemCount() -> Int {
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
