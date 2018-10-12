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
    
    private var scene: SKScene?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("Loaded continuous game view")
        
        if let view = self.view as! SKView? {
            let scene = ContinousGameScene(size: view.bounds.size)
            self.scene = scene
            
            scene.scaleMode = .aspectFill
            
            view.presentScene(scene)
            
            view.ignoresSiblingOrder = true
            view.showsFPS = true
            view.showsNodeCount = true
        }
        
        let notification = Notification(name: .init("appTerminate"))
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppTerminate), name: notification.name, object: nil)
        
        let gameOverNotification = Notification(name: .init("gameOver"))
        NotificationCenter.default.addObserver(self, selector: #selector(handleGameOver), name: gameOverNotification.name, object: nil)
    }
    
    @objc func handleAppTerminate() {
        let contScene = scene as! ContinousGameScene
        contScene.saveState()
    }
    
    @objc func handleGameOver() {
        self.performSegue(withIdentifier: "unwindToGameMenu", sender: self)
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
