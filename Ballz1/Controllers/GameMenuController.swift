//
//  GameMenuController.swift
//  Ballz1
//
//  Controller for the game menu to handle button clicks and taps
//
//  Created by Gabriel Busto on 10/6/18.
//  Copyright © 2018 Self. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameMenuController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
            let scene = GameMenuScene(size: view.bounds.size)
            scene.scaleMode = .aspectFill
            
            playButton.imageView?.contentMode = .scaleAspectFit
            
            view.presentScene(scene)
            
            view.ignoresSiblingOrder = true
        }
    }
    
    @IBAction func playGame(_ sender: Any) {
        print("Pressed button... loading continuous game scene")
    }
    
    @IBAction func prepareForUnwind(segue: UIStoryboardSegue) {
        // Apparently this is necessary for unwinding views
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
