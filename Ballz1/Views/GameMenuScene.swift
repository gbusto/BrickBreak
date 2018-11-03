//
//  GameMenuView.swift
//  Ballz1
//
//  View to display the game menu
//
//  Created by Gabriel Busto on 10/6/18.
//  Copyright © 2018 Self. All rights reserved.
//

import UIKit
import SpriteKit

/*
 Things to control by color theme:
 - Background
 - Text/Labels
 - Buttons
 - Hit blocks
 - Line dividing game play area vs top/bottom margin area
 - Balls
 */

class GameMenuScene: SKScene {
    
    // MARK: Override functions
    override func didMove(to view: SKView) {
        print("Loaded GameMenuScene")
        
        let numItemsPerRow = 8
        let rowHeight = view.frame.width / CGFloat(numItemsPerRow)
        let blockSize = CGSize(width: rowHeight * 0.95, height: rowHeight * 0.95)
        
        let theme = LightTheme(backgroundSize: view.frame.size, blockSize: blockSize)
        
        let node = SKSpriteNode(texture: theme.backgroundTexture)
        node.size = view.frame.size
        node.anchorPoint = CGPoint(x: 0, y: 0)
        node.position = CGPoint(x: 0, y: 0)
        
        self.addChild(node)
    }
}
