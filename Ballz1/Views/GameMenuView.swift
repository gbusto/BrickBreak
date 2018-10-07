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
import GameplayKit

class GameMenuView: SKScene {
    
    // MARK: Private properties
    private var fontName = "KohinoorBangla-Regular"
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let scene = ContinousGameView(size: self.view!.bounds.size)
        self.view!.presentScene(scene, transition: SKTransition.fade(withDuration: 0.5))
    }
    
    // MARK: Override functions
    override func didMove(to view: SKView) {
        let color = UIColor(red: 255/255, green: 204/255, blue: 229/255, alpha: 1)
        
        var pos = CGPoint(x: view.frame.midX, y: view.frame.height * 0.8)
        createLabel(position: pos, size: 80, text: "Brick", color: color)
        pos.y = view.frame.height * 0.68
        createLabel(position: pos, size: 80, text: "Break", color: color)
        
        pos.y = view.frame.height * 0.40
        createLabel(position: pos, size: 20, text: "Tap to start", color: .white)
    }
    
    private func createLabel(position: CGPoint, size: CGFloat, text: String, color: UIColor) {
        let label = SKLabelNode(fontNamed: fontName)
        label.fontColor = color
        label.text = text
        label.fontSize = size
        label.position = position
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        self.addChild(label)
    }
}
