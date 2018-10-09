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
    
    // Items for which this generator is responsible
    public var itemArray : [Item] = []
    
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
    
    // Width for each item (mostly used for blocks)
    private var itemWidth : CGFloat?
    
    // ceilingHeight is used to know where items should be generated
    private var ceilingHeight : CGFloat?
    // groundHeight is used to know if another row can be generated; if not, it means the game is over
    private var groundHeight : CGFloat?
    
    private var scene: SKScene?
    
    // The SKView
    private var view : SKView?
    
    // Item types that this generator can generate; for example, after 100 turns, maybe you want to start adding special kinds of blocks
    // The format is [ITEM_TYPE: PERCENTAGE_TO_GENERATE]
    private var itemTypeDict : [Int: Int] = [:]
    // Total percentage that will grow as items are added to the itemTypeDict
    private var totalPercentage = Int(100)
    // Used to mark item types to know what item types are allowed to be generated
    private var HIT_BLOCK = Int(1)
    private var BALL = Int(2)
    
    // An Int to let the GameScene know when the ItemGenerator is ready
    private var actionsStarted = Int(0)
    
    private var currentColor : Color?
    
    // MARK: Public functions
    public func initGenerator(scene: SKScene, view: SKView, numBalls: Int, numItems: Int,
                              ceiling: CGFloat, ground: CGFloat) {
        
        self.scene = scene
        self.view = view
        numberOfBalls = numBalls
        maxHitCount = numBalls * 2
        numItemsPerRow = numItems
        itemWidth = view.frame.width / CGFloat(numItems)
        ceilingHeight = ceiling
        groundHeight = ground
        currentColor = Color()
        
        // Initialize the allowed item types with only one type for now
        itemTypeDict[HIT_BLOCK] = 70
        itemTypeDict[BALL] = 30
    }
    
    public func addItemType(type: Int, percentage: Int) {
        itemTypeDict[type] = percentage
        totalPercentage += percentage
    }
    
    public func generateRow() {
        let color = currentColor!.changeColor()
        print("Color is \(color)")
        
        for i in 0...(numItemsPerRow - 1) {
            if Int.random(in: 1...100) < 60 {
                let type = pickItem()
                if 0 == type {
                    // If no item was picked, loop back around
                    continue
                }
    
                switch type {
                case HIT_BLOCK:
                    let posX = CGFloat(i) * itemWidth!
                    let posY = CGFloat(ceilingHeight! - (itemWidth! * 1))
                    let pos = CGPoint(x: posX, y: posY)
                    
                    let size = CGSize(width: itemWidth! * 0.95, height: itemWidth! * 0.95)
                    let item = HitBlockItem()
                    item.initItem(generator: self, num: numItemsGenerated, size: size, position: pos)
                    let block = item as HitBlockItem
                    block.setColor(color: color)
                    // XXX Might remove this, not sure if we'll ever need to use loadItem()
                    let ret = item.loadItem()
                    if false == ret {
                        print("Failed to load hit block item")
                    }
                    item.getNode().alpha = 0
                    scene!.addChild(item.getNode())
                    print("Adding block at row position \(i)")
                    itemArray.append(item)
                    break
                case BALL:
                    // Put the ball in the center of its row position
                    let posX = (CGFloat(i) * itemWidth!) + (itemWidth! / 2)
                    let posY = CGFloat(ceilingHeight! - (itemWidth! * 1)) + (itemWidth! / 2)
                    let pos = CGPoint(x: posX, y: posY)
                    
                    let radius = view!.frame.width * 0.018
                    let size = CGSize(width: radius, height: radius)
                    let item = BallItem()
                    item.initItem(generator: self, num: numItemsGenerated, size: size, position: pos)
                    print("Added ball with number \(numItemsGenerated)")
                    // XXX Might remove this, not sure if we'll ever need to use loadItem()
                    let ret = item.loadItem()
                    if false == ret {
                        print("Failed to load ball item")
                    }
                    item.getNode().alpha = 0
                    scene!.addChild(item.getNode())
                    itemArray.append(item)
                    break
                default:
                    // Shouldn't ever hit the default case; if we do just loop back around
                    print("Hit default case. Item type is \(type)")
                    continue
                }
                numItemsGenerated += 1
            }
        }
        
        actionsStarted = itemArray.count
        
        for item in itemArray {
            let action1 = SKAction.fadeIn(withDuration: 1)
            let action2 = SKAction.moveBy(x: 0, y: -itemWidth!, duration: 1)
            item.getNode().run(SKAction.group([action1, action2])) {
                // Remove one from the count each time an action completes
                self.actionsStarted -= 1
            }
        }
    }
    
    public func isReady() -> Bool {
        // This is used to prevent the user from shooting while the block manager isn't ready yet
        return (0 == actionsStarted)
    }
    
    public func hit(name: String) {
        for item in itemArray {
            if item.getNode().name == name {
                item.hitItem()
                if item.getNode().name!.starts(with: "ball") {
                    // If this item was a ball, increase the max hit count by 2 because it will be transferred over to the ball manager
                    maxHitCount! += 2
                }
            }
        }
    }
    
    public func removeItems() -> [Item] {
        var array : [Item] = []
        let newItemArray = itemArray.filter {
            // Perform a remove action if needed
            if $0.removeItem(scene: scene!) {
                // Remove this item from the array
                array.append($0)
                return false
            }
            // Keep this item in the array
            return true
        }
        
        itemArray = newItemArray
        
        return array
    }
    
    public func canAddRow(groundHeight: CGFloat) -> Bool {
        for item in itemArray {
            if (item.getNode().position.y - itemWidth!) < groundHeight {
                return false
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
}
