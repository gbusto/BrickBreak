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
    
    public var node: SKNode?
    
    func initItem(num: Int, size: CGSize) {
        // Don't need to do anything here
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
        // This is to avoid issues when unwrapping node names
        if let node = self.node {
            return node
        }
        
        node = SKNode()
        node!.name = "spacer"
        return node!
    }
    
}
