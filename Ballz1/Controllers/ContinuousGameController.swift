//
//  ContinuousGameController.swift
//  Ballz1
//
//  The view controller for continuous gameplay view
//
//  Created by Gabriel Busto on 10/6/18.
//  Copyright © 2018 Self. All rights reserved.
//

import UIKit
import SpriteKit

class ContinuousGameController: UIViewController, SKPhysicsContactDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("Loaded continuous game view")
        
        if let view = self.view as! SKView? {
            let scene = ContinousGameScene(size: view.bounds.size)
            scene.scaleMode = .aspectFill
            
            view.presentScene(scene)
            
            view.ignoresSiblingOrder = true
            view.showsFPS = true
            view.showsNodeCount = true
        }
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .portrait
        } else {
            return .portrait
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
