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

class ContinuousGameController: UIViewController, GADBannerViewDelegate, GADRewardBasedVideoAdDelegate {
    
    private var scene: SKScene?
    
    @IBOutlet var bannerView: GADBannerView!
    @IBOutlet var undoButton: UIButton!
    @IBOutlet weak var gameScoreLabel: UILabel!
    @IBOutlet weak var highScoreLabel: UILabel!
    @IBOutlet var pauseMenuView: UIView!
    @IBOutlet var resumeButton: UIButton!
    @IBOutlet var returnGameMenuButton: UIButton!
    
    private var loadedRewardAd = false
    
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
            
            // Set up the banner ad
            bannerView.adUnitID = AdHandler.getBannerAdID()
            bannerView.rootViewController = self
            bannerView.delegate = self
            
            // Load the banner ad request
            let bannerAdRequest = GADRequest()
            bannerAdRequest.testDevices = AdHandler.getTestDevices()
            bannerView.load(bannerAdRequest)
            
            // Set up reward ads
            GADRewardBasedVideoAd.sharedInstance().delegate = self
            
            // Load the undo reward ad request
            let undoRewardAd = GADRequest()
            undoRewardAd.testDevices = AdHandler.getTestDevices()
            GADRewardBasedVideoAd.sharedInstance().load(undoRewardAd, withAdUnitID: AdHandler.getRewardAdID())
            
            view.presentScene(scene)
            
            view.ignoresSiblingOrder = true
        }
    }
    
    // MARK: Banner ad functions
    public func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        // Error loading the ad; hide the banner
        bannerView.isHidden = true
        print("Error loading ad: \(error.localizedDescription)")
    }
    
    public func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        // Received an ad; show the banner now
        bannerView.isHidden = false
    }
    
    // MARK: Reward ad functions
    public func rewardBasedVideoAdDidReceive(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        // Received a reward based video ad; may not end up using this
        print("Received reward ad!")
        loadedRewardAd = true
    }
    
    public func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd, didRewardUserWith reward: GADAdReward) {
        // User was rewarded; let the game model know to save the user or undo the turn (depending on what the reward is supposed to be)
        print("User gets rewarded!")
    }
    
    public func rewardBasedVideoAdDidCompletePlaying(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        // The video ad completed; might not need to use this either since the function above this handles rewards
        print("The reward video completed")
    }
    
    public func rewardBasedVideoAdDidClose(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        // Get ready to load up a new reward ad right away
        print("Reward ad closed out")
        loadedRewardAd = false
        let undoRewardAd = GADRequest()
        undoRewardAd.testDevices = AdHandler.getTestDevices()
        GADRewardBasedVideoAd.sharedInstance().load(undoRewardAd, withAdUnitID: AdHandler.getRewardAdID())
    }
    
    public func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd, didFailToLoadWithError error: Error) {
        // Failed to load a reward ad; need to handle this case when the user isn't on the network
        print("Failed to load reward ad")
        loadedRewardAd = false
    }
    
    public func showRewardAd() {
        if loadedRewardAd {
            // Show the reward ad if we can
            if GADRewardBasedVideoAd.sharedInstance().isReady {
                // MARK: Bug - to avoid a weird bug, I need to load a new view with its own View Controller
                GADRewardBasedVideoAd.sharedInstance().present(fromRootViewController: self)
            }
        }
        else {
            // If we didn't load an ad just give the user a reward (maybe they're offline?)
            print("Failed to show reward ad")
        }
    }
    
    // MARK: Public view controller functions
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
        showRewardAd()
        //let contScene = scene as! ContinousGameScene
        //contScene.loadPreviousTurnState()
    }
    
    // Prepare for a segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Necessary for loading views
        print("Preparing for segue")
    }

    @IBAction func prepareForUnwind(segue: UIStoryboardSegue) {
        // Necessary for unwinding views
        print("Preparing for unwind")
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
