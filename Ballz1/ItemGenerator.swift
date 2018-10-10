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
    public var itemArray : [[Item]] = []
    
    // Maximum hit count for a HitBlock
    public var maxHitCount : Int?
    
    
    // -------------------------------------------------------------
    // MARK: Private functions
    
    // The number of active balls the user has; this will influence HitBlock counts
    private var numberOfBalls = Int(0)
    
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
    private var itemTypeDict : [Int: Int] = [:]
    // Total percentage that will grow as items are added to the itemTypeDict
    private var totalPercentage = Int(100)
    // Used to mark item types to know what item types are allowed to be generated
    private var EMPTY = Int(0)
    private var HIT_BLOCK = Int(1)
    private var BALL = Int(2)
    
    // An Int to let holder of this object know when the ItemGenerator is ready
    private var actionsStarted = Int(0)
    
    private var currentColor : Color?
    
    // MARK: Public functions
    public func initGenerator(blockSize: CGSize, ballRadius: CGFloat, numBalls: Int, numItems: Int) {
        
        self.blockSize = blockSize
        self.ballRadius = ballRadius
        numberOfBalls = numBalls
        maxHitCount = numBalls * 2
        numItemsPerRow = numItems
        currentColor = Color()
        
        // Initialize the allowed item types with only one type for now
        itemTypeDict[HIT_BLOCK] = 70
        itemTypeDict[BALL] = 30
    }
    
    public func addItemType(type: Int, percentage: Int) {
        itemTypeDict[type] = percentage
        totalPercentage += percentage
    }
    
    public func generateRow() -> [Item] {
        let color = currentColor!.changeColor()
        
        var newRow: [Item] = []

        for _ in 0...(numItemsPerRow - 1) {
            if Int.random(in: 1...100) < 60 {
                let type = pickItem()
    
                switch type {
                case EMPTY:
                    let spacer = SpacerItem()
                    newRow.append(spacer)
                    break
                case HIT_BLOCK:
                    let item = HitBlockItem()
                    item.initItem(generator: self, num: numItemsGenerated, size: blockSize!)
                    let block = item as HitBlockItem
                    block.setColor(color: color)
                    newRow.append(item)
                    break
                case BALL:
                    // Put the ball in the center of its row position
                    let size = CGSize(width: ballRadius!, height: ballRadius!)
                    let item = BallItem()
                    item.initItem(generator: self, num: numItemsGenerated, size: size)
                    print("Added ball with number \(numItemsGenerated)")
                    newRow.append(item)
                    break
                default:
                    // Shouldn't ever hit the default case; if we do just loop back around
                    print("Hit default case. Item type is \(type)")
                    continue
                }
                numItemsGenerated += 1
            }
                // If Int.random() didn't return a number < 60, add a spacer item anyways; each slot in a row needs to be occupied (i.e. each row must contain at least numItemsPerRow number of items)
            else {
                let spacer = SpacerItem()
                newRow.append(spacer)
            }
        }
        
        itemArray.append(newRow)
        
        return newRow
    }
    
    public func animateItems(_ action: SKAction) {
        actionsStarted = getItemCount()
        
        for row in itemArray {
            for item in row {
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
                        maxHitCount! += 2
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
            
            let newRow = row.filter {
                // Perform a remove action if needed
                if $0.removeItem() {
                    // Remove this item from the array if that evaluates to true (meaning it's time to remove the item)
                    removedItems.append($0)
                    return false
                }
                // Keep this item in the array
                return true
            }
            
            itemArray[i] = newRow
        }
        
        // After removing all necessary items, check to see if there any empty rows that can be removed
        removeEmptyRows()
        
        // Return all items that were removed
        return removedItems
    }
    
    // Iterate over all items to see if any are too close to the ground
    // "Too close" is defined as: if can't add another item before hitting the ground, we're too close
    public func canAddRow(_ floor: CGFloat, _ rowHeight: CGFloat) -> Bool {
        for row in itemArray {
            for item in row {
                // We don't care about spacer items
                if item is SpacerItem {
                    continue
                }
                
                if (item.getNode().position.y - rowHeight) < floor {
                    return false
                }
            }
        }
        
        return true
    }
    
    // MARK: Private functions
    private func pickItem() -> Int {
        for itemType in itemTypeDict.keys {
            if Int.random(in: 1...totalPercentage) < itemTypeDict[itemType]! {
                return itemType
            }
        }
        return 0
    }
    
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
    
    private func removeEmptyRows() {
        let newItemArray = itemArray.filter {
            for item in $0 {
                if item is SpacerItem {
                    continue
                }
                // If we encounter any items that aren't a SpacerItem, it should just be removed
                return true
            }
            
            // If we reached this point, there are only SpacerItem types so remove the row
            print("Removing an empty row")
            return false
        }
        
        itemArray = newItemArray
    }
}
