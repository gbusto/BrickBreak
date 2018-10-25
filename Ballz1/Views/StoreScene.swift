//
//  StoreView.swift
//  Ballz1
//
//  Created by hemingway on 10/19/18.
//  Copyright © 2018 Self. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class StoreScene: SKScene {
    
    private let fontName = "Helvetica-Bold"
    private var marginColor = UIColor.init(red: 90/255, green: 90/255, blue: 90/255, alpha: 1)
    
    // MARK: Override functions
    override func didMove(to view: SKView) {
        print("Loaded Store scene")
        
        self.backgroundColor = marginColor
    }
    
    // This will display an action to give the user feedback that they purchased an item
    public func madePurchase(amount: Int, textSize: CGFloat) {
        let position = CGPoint(x: view!.frame.midX, y: view!.frame.minY + 20)
        let amountLabel = SKLabelNode(fontNamed: fontName)
        amountLabel.text = "-\(amount)"
        amountLabel.fontColor = UIColor(red: 255/255, green: 153/255, blue: 153/255, alpha: 1)
        amountLabel.position = position
        amountLabel.fontSize = textSize / 1.5
        amountLabel.alpha = 0
        
        let vect = CGVector(dx: 0, dy: textSize * 3)
        let action1 = SKAction.fadeIn(withDuration: 0.5)
        let action2 = SKAction.move(by: vect, duration: 1.5)
        let action3 = SKAction.fadeOut(withDuration: 0.5)
        self.addChild(amountLabel)
        amountLabel.run(action2)
        amountLabel.run(SKAction.sequence([action1, action3])) {
            self.scene!.removeChildren(in: [amountLabel])
        }
    }
}
