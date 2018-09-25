//
//  GameMenu.swift
//  Ballz1
//
//  Created by Gabriel Busto on 9/25/18.
//  Copyright © 2018 Self. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameMenu: SKScene {
    
    // MARK: Private properties
    private var fontName = "KohinoorBangla-Regular"
    private var startButton : SKSpriteNode?
    
    // MARK: Override functions
    override func didMove(to view: SKView) {
        initStartButton(view: view)
    }
    
    // MARK: Private functions
    private func initStartButton(view: SKView) {
        let size = CGSize(width: view.frame.width * 0.4, height: view.frame.height * 0.1)
        let color = UIColor(red: 51/255, green: 153/255, blue: 255/255, alpha: 1)
        let pos = CGPoint(x: view.frame.midX, y: view.frame.midY)
        startButton = SKSpriteNode(color: color, size: size)
        startButton!.position = pos
        
        let label = SKLabelNode(text: "Start")
        label.fontName = fontName
        label.fontSize = 30
        startButton!.addChild(label)
        
        self.addChild(startButton!)
    }
    
}
