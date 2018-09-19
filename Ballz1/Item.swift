//
//  Item.swift
//  Ballz1
//
//  Created by Gabriel Busto on 9/18/18.
//  Copyright © 2018 Self. All rights reserved.
//

import SpriteKit
import GameplayKit

protocol Item {
    
    // Initializes the item in question; the ItemGenerator will add the item to the scene using a public attribute named node
    //
    // Arguments:
    //   - num: A number to append to a name; used in collision dectection to tell what item was hit
    //   - size: Size of the item (circles will just use size.width as a radius
    //   - position: Where to position the node on the screen
    //
    // Returns nothing
    func initItem(generator: ItemGenerator, num: Int, size: CGSize, position: CGPoint)
    
    // This function is called to allow the item to perform any actions before being displayed
    //
    // Returns true if item loading was successful
    //
    // NOTE: To ensure all actions have been completed, each Item will have a ready attribute to determine if the item's action is complete
    func loadItem() -> Bool
    
    // This function is called when an item is hit by a ball; blocks will light up, change color, decrement count, etc
    //
    // Returns nothing
    func hitItem()
    
    // This function checks to see if the item should be removed from the item array in the generator and handles anything to be done before it removes the item from the scene; use this function for any animation before the item is removed
    //
    // Returns true if the item should be removed; false otherwise
    //
    // NOTE: ItemGenerator may take this item and hand it off to another handler or manager such as Balls being handed off to BallManager and Currency being handed off to CurrencyManager
    func removeItem() -> Bool
    
    // This returns an SKNode item contained within the class
    func getNode() -> SKNode
    
}
