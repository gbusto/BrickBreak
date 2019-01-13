//
//  LevelsGameController.swift
//  Ballz1
//
//  Created by hemingway on 1/13/19.
//  Copyright © 2019 Self. All rights reserved.
//

import UIKit
import SpriteKit
import GoogleMobileAds

class LevelsGameController: UIViewController,
                            GADBannerViewDelegate,
                            GADInterstitialDelegate {

    override func viewDidAppear(_ animated: Bool) {
        // Load the stuff for ads
        print("Levels view appeared!")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("Levels view loaded!")
        
        // Setup notifications
        
        if let view = self.view as! SKView? {
            let scene = LevelsGameScene(size: view.bounds.size)
            
            scene.scaleMode = .aspectFill
            
            view.presentScene(scene)
            view.ignoresSiblingOrder = true
        }
    }
}
