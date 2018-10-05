//
//  GameViewController.swift
//  Ballz1
//
//  Created by Gabriel Busto on 9/13/18.
//  Copyright © 2018 Self. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
            //let scene = GameScene(size: view.bounds.size)
            let scene = GameMenu(size: view.bounds.size)
            
            scene.scaleMode = .aspectFill
            
            view.presentScene(scene)
            
            view.ignoresSiblingOrder = true
            view.showsFPS = true
            view.showsNodeCount = true
            
            NotificationCenter.default.addObserver(self, selector: #selector(handleResignActive), name: Notification.Name.NSExtensionHostWillResignActive, object: nil)
        }
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .portrait
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: Handle notifications
    @objc func handleResignActive() {
        print("Got notification that app will resign active")
    }
}
