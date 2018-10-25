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
        
        // Notification that says the app is going into the background
        let backgroundNotification = Notification(name: .NSExtensionHostWillResignActive)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppGoingBackground), name: backgroundNotification.name, object: nil)
        
        // Notification to continue the game after the user was about to lose
        let continueNotification = Notification(name: .init("continueGame"))
        NotificationCenter.default.addObserver(self, selector: #selector(showContinueButton), name: continueNotification.name, object: nil)
        
        // Notification that the app will terminate
        let notification = Notification(name: .init("appTerminate"))
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppTerminate), name: notification.name, object: nil)
        
        // Notification to end the game and unwind to the game menu
        let gameOverNotification = Notification(name: .init("gameOver"))
        NotificationCenter.default.addObserver(self, selector: #selector(handleGameOver), name: gameOverNotification.name, object: nil)
        
        // Notification to update the score labels
        let updateScoreNotification = Notification(name: .init("updateScore"))
        NotificationCenter.default.addObserver(self, selector: #selector(updateScore(_:)), name: updateScoreNotification.name, object: nil)
        
        // Notification to undo the user's last turn
        let undoNotification = Notification(name: .init("undoTurn"))
        NotificationCenter.default.addObserver(self, selector: #selector(handleUndo), name: undoNotification.name, object: nil)
        
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
        
        // Don't pause the game when it goes to the background if the gameover overlay is showing
        if scene.isGameOverShowing() {
            return
        }
        
        if let view = self.view as! SKView? {
            // If the view is paused from showing the Continue? dialog then don't pause the game when it moves to the background
            if false == view.isPaused {
                scene.isPaused = true
                view.isPaused = true
                scene.showPauseScreen()
            }
        }
    }
    
    @objc func handleAppTerminate() {
        let contScene = scene as! ContinousGameScene
        contScene.saveState()
    }
    
    @objc func handleGameOver() {
        self.performSegue(withIdentifier: "unwindToGameMenu", sender: self)
    }
    
    @objc private func handleUndo() {
        print("Got undo notification")

        let contScene = scene as! ContinousGameScene
        contScene.loadPreviousTurnState()
    }
    
    // Prepare for a segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // If the next controller we're transitioning to is the StoreController, set the currency label to the amount of currency the user has
        if segue.destination is StoreController {
            let scene = self.scene as! ContinousGameScene
            let destController = segue.destination as! StoreController
            // Set the currency amount in the store scene controller
            destController.currencyAmount = scene.gameModel!.currencyAmount
            // Set a boolean letting the store scene controller know whether or not the purchase Undo button should be enabled
            destController.canPurchaseUndo = scene.gameModel!.prevTurnSaved
        }
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
