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
import GoogleMobileAds

class ContinuousGameController: UIViewController, GADBannerViewDelegate {
    
    private var scene: SKScene?
    
    @IBOutlet var bannerView: GADBannerView!
    @IBOutlet var undoButton: UIButton!
    @IBOutlet weak var gameScoreLabel: UILabel!
    @IBOutlet weak var highScoreLabel: UILabel!
    @IBOutlet var pauseMenuView: UIView!
    @IBOutlet var resumeButton: UIButton!
    @IBOutlet var returnGameMenuButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("Loaded continuous game view")
        
        // Notification that says the app is going into the background
        let backgroundNotification = Notification(name: .NSExtensionHostWillResignActive)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppGoingBackground), name: backgroundNotification.name, object: nil)
        
        // Notification that the app will terminate
        let notification = Notification(name: .init("appTerminate"))
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppTerminate), name: notification.name, object: nil)
        
        if let view = self.view as! SKView? {
            let scene = ContinousGameScene(size: view.bounds.size)
            self.scene = scene
            
            scene.scaleMode = .aspectFill
            scene.gameController = self
            
            undoButton.isEnabled = false
            
            pauseMenuView.center = CGPoint(x: view.frame.midX, y: view.frame.midY)
            resumeButton.imageView?.contentMode = .scaleAspectFit
            returnGameMenuButton.imageView?.contentMode = .scaleAspectFit
            
            bannerView.adUnitID = AdHandler.getBannerAdID()
            bannerView.rootViewController = self
            bannerView.delegate = self
            
            let adRequest = GADRequest()
            adRequest.testDevices = AdHandler.getTestDevices()
            bannerView.load(adRequest)
            
            view.presentScene(scene)
            
            view.ignoresSiblingOrder = true
        }
    }
    
    public func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        bannerView.isHidden = true
        print("Error loading ad: \(error.localizedDescription)")
    }
    
    public func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        bannerView.isHidden = false
    }
    
    public func getPauseMenu() -> UIView {
        return pauseMenuView
    }
    
    public func showContinueButton() {
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
    
    public func enableUndoButton() {
        if false == undoButton.isEnabled {
            undoButton.isEnabled = true
        }
    }
    
    public func disableUndoButton() {
        if undoButton.isEnabled {
            undoButton.isEnabled = false
        }
    }
    
    @IBAction func returnToGameMenu(_ sender: Any) {
        let contScene = scene as! ContinousGameScene
        contScene.saveState()
        
        handleGameOver()
    }
    
    @IBAction func resumeGame(_ sender: Any) {
        let contScene = scene as! ContinousGameScene
        contScene.resumeGame()
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

    public func handleGameOver() {
        self.performSegue(withIdentifier: "unwindToGameMenu", sender: self)
    }
    
    @IBAction func undoTurn(_ sender: Any) {
        // MARK: TODO - Add code here to show an ad

        let contScene = scene as! ContinousGameScene
        contScene.loadPreviousTurnState()
    }
    
    // Prepare for a segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Necessary for loading views
    }

    @IBAction func prepareForUnwind(segue: UIStoryboardSegue) {
        // Necessary for unwinding views
    }
    
    public func updateScore(gameScore: Int, highScore: Int) {
        self.gameScoreLabel.text = "\(gameScore)"
        self.highScoreLabel.text = "\(highScore)"
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
