//
//  SpacerItem.swift
//  Ballz1
//
//  Created by Gabriel Busto on 10/9/18.
//  Copyright © 2018 Self. All rights reserved.
//

import SpriteKit

// This is an item that we use as a placeholder empty item
class SpacerItem: Item {
    
    func initItem(generator: ItemGenerator, num: Int, size: CGSize) {
        // Pass
    }
    
    func loadItem(position: CGPoint) -> Bool {
        return true
    }
    
    func hitItem() {
        // Pass
    }
    
    func removeItem() -> Bool {
        return false
    }
    
    func getNode() -> SKNode {
        return SKNode()
    }
    
}
