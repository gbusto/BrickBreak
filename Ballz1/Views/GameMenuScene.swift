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
    public var theme: GameMenuColorScheme?
    // MARK: Override functions
    override func didMove(to view: SKView) {
        print("Loaded GameMenuScene")
        
        theme = GameMenuColorScheme()
        self.backgroundColor = theme!.backgroundColor
    }
    
}
