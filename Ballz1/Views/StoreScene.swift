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
    
    private var marginColor = UIColor.init(red: 90/255, green: 90/255, blue: 90/255, alpha: 1)
    
    // MARK: Override functions
    override func didMove(to view: SKView) {
        print("Loaded Store scene")
        
        self.backgroundColor = marginColor
    }
}
