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

class ContinuousGameController: UIViewController {
    
    private var scene: SKScene?
    
    @IBOutlet weak var gameScoreLabel: UILabel!
    @IBOutlet weak var highScoreLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("Loaded continuous game view")
        
        let backgroundNotification = Notification(name: .NSExtensionHostWillResignActive)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppGoingBackground), name: backgroundNotification.name, object: nil)
        
        let continueNotification = Notification(name: .init("continueGame"))
        NotificationCenter.default.addObserver(self, selector: #selector(showContinueButton), name: continueNotification.name, object: nil)
        
        let notification = Notification(name: .init("appTerminate"))
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppTerminate), name: notification.name, object: nil)
        
        let gameOverNotification = Notification(name: .init("gameOver"))
        NotificationCenter.default.addObserver(self, selector: #selector(handleGameOver), name: gameOverNotification.name, object: nil)
        
        let updateScoreNotification = Notification(name: .init("updateScore"))
        NotificationCenter.default.addObserver(self, selector: #selector(updateScore(_:)), name: updateScoreNotification.name, object: nil)
        
        if let view = self.view as! SKView? {
            let scene = ContinousGameScene(size: view.bounds.size)
            self.scene = scene
            
            scene.scaleMode = .aspectFill
            
            view.presentScene(scene)
            
            view.ignoresSiblingOrder = true
        }
    }
    
    @objc func showContinueButton() {
        if let view = self.view as! SKView? {
            view.isPaused = true
            
            let alert = UIAlertController(title: "Continue", message: "Watch a sponsored ad to save yourself", preferredStyle: .alert)
            let yesAction = UIAlertAction(title: "Yes", style: .default) { (handler: UIAlertAction) in
                print("Pressed yes button")
                let scene = self.scene as! ContinousGameScene
                // Save the user!
                scene.saveUser()
                view.isPaused = false
            }
            let noAction = UIAlertAction(title: "No", style: .default) { (handler: UIAlertAction) in
                print("Pressed no button")
                let scene = self.scene as! ContinousGameScene
                // Should be able to just call handleGameOver()
                scene.endGame()
            }
            
            alert.addAction(yesAction)
            alert.addAction(noAction)
            
            present(alert, animated: false, completion: nil)
        }
    }
    
    @IBAction func statusBarTapped(_ sender: Any) {
        let scene = self.scene as! ContinousGameScene
        if let view = self.view as! SKView? {
            scene.isPaused = true
            view.isPaused = true
            scene.showPauseScreen()
        }
    }
    
    @objc func handleAppGoingBackground() {
        let scene = self.scene as! ContinousGameScene
        if let view = self.view as! SKView? {
            scene.isPaused = true
            view.isPaused = true
            scene.showPauseScreen()
        }
    }
    
    @objc func handleAppTerminate() {
        let contScene = scene as! ContinousGameScene
        contScene.saveState()
    }
    
    @objc func handleGameOver() {
        self.performSegue(withIdentifier: "unwindToGameMenu", sender: self)
    }
    
    // Necessary for the currency button to be able to perform actions
    @IBAction func showStoreScene(_ sender: Any) {
        print("Showing store scene now")
    }

    @IBAction func prepareForUnwind(segue: UIStoryboardSegue) {
        // Necessary for unwinding views
    }
    
    @objc func updateScore(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            let score = userInfo["score"]!
            let highScore = userInfo["highScore"]!
            
            self.gameScoreLabel.text = "\(score)"
            self.highScoreLabel.text = "\(highScore)"
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
