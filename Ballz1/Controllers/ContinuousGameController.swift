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

class ContinuousGameController: UIViewController,
                                GADBannerViewDelegate,
                                GADRewardBasedVideoAdDelegate,
                                GADInterstitialDelegate {
    
    private var scene: SKScene?
    
    private var interstitialAd: GADInterstitial!
    
    @IBOutlet var bannerView: GADBannerView!
    @IBOutlet var undoButton: UIButton!
    @IBOutlet weak var gameScoreLabel: UILabel!
    @IBOutlet weak var highScoreLabel: UILabel!
    @IBOutlet var pauseMenuView: UIView!
    @IBOutlet var resumeButton: UIButton!
    @IBOutlet var returnGameMenuButton: UIButton!
    
    private var rewardAdViewController: RewardAdViewController!
    
    private var showedReward = false
    private var rewardType = ContinuousGameController.NO_REWARD
    static private var NO_REWARD = Int(0)
    static private var UNDO_REWARD = Int(1)
    static private var RESCUE_REWARD = Int(2)
    
    override func viewDidAppear(_ animated: Bool) {
        // Set up the banner ad
        bannerView.adUnitID = AdHandler.getBannerAdID()
        bannerView.rootViewController = self
        bannerView.delegate = self
        
        // Load the banner ad
        let bannerAdRequest = GADRequest()
        bannerAdRequest.testDevices = AdHandler.getTestDevices()
        bannerView.load(bannerAdRequest)
        
        // Prepare to load interstitial ads
        GADRewardBasedVideoAd.sharedInstance().delegate = self
        
        // Attempt to load the reward ad
        let rewardAdRequest = GADRequest()
        rewardAdRequest.testDevices = AdHandler.getTestDevices()
        GADRewardBasedVideoAd.sharedInstance().load(rewardAdRequest, withAdUnitID: AdHandler.getRewardAdID())
        
        // Prepare to load interstitial ads
        interstitialAd = GADInterstitial(adUnitID: AdHandler.getInterstitialAdID())
        interstitialAd.delegate = self
        
        // Attempt to load the interstitial ad
        let intAdRequest = GADRequest()
        intAdRequest.testDevices = AdHandler.getTestDevices()
        interstitialAd.load(intAdRequest)
        
        // This is a view controller to fix buggy behavior with the reward ads
        rewardAdViewController = RewardAdViewController()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
    }
    
    public func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd, didRewardUserWith reward: GADAdReward) {
        // User was rewarded; let the game model know to save the user or undo the turn (depending on what the reward is supposed to be)
        if rewardType == ContinuousGameController.NO_REWARD {
            print("No reward type specified... oops?")
        }
        else if rewardType == ContinuousGameController.UNDO_REWARD {
            // Undo the last turn
            let contScene = scene as! ContinousGameScene
            contScene.loadPreviousTurnState()
        }
        else if rewardType == ContinuousGameController.RESCUE_REWARD {
            // Save the user!
            let contScene = scene as! ContinousGameScene
            contScene.saveUser()
        }
        
        // Reset the reward type since we just rewarded the user
        rewardType = ContinuousGameController.NO_REWARD
        
        showedReward = true
    }
    
    public func rewardBasedVideoAdDidCompletePlaying(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        // The video ad completed; might not need to use this either since the function above this handles rewards
    }
    
    public func rewardBasedVideoAdDidClose(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        // Get ready to load up a new reward ad right away
        // Dismiss the reward ad view controller
        rewardAdViewController.dismiss(animated: true, completion: nil)
        
        // Ensure the undo button is disabled after showing a reward ad
        disableUndoButton()
        
        // Load a new reward ad
        let rewardAdRequest = GADRequest()
        rewardAdRequest.testDevices = AdHandler.getTestDevices()
        GADRewardBasedVideoAd.sharedInstance().load(rewardAdRequest, withAdUnitID: AdHandler.getRewardAdID())
        
        if false == showedReward {
            if rewardType == ContinuousGameController.NO_REWARD {
                print("Skipped reward ad and no reward type specified... oops?")
            }
            else if rewardType == ContinuousGameController.UNDO_REWARD {
                // Don't do anything since they didn't watch the ad
            }
            else if rewardType == ContinuousGameController.RESCUE_REWARD {
                // Don't save the user since they didn't watch the ad
                let scene = self.scene as! ContinousGameScene
                scene.endGame()
            }
        }
        else {
            // Set showedReward to false
            showedReward = false
        }
    }
    
    public func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd, didFailToLoadWithError error: Error) {
        // Failed to load a reward ad; need to handle this case when the user isn't on the network
        
        // Disable the undo button if it's loaded because we don't have an ad loaded
        disableUndoButton()
    }
    
    // MARK: Interstitial ad functions
    public func interstitialDidReceiveAd(_ ad: GADInterstitial) {
        // Received an interstitial ad
    }
    
    public func interstitial(_ ad: GADInterstitial, didFailToReceiveAdWithError error: GADRequestError) {
        // Failed to receive an interstitial ad
    }
    
    public func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        // Interstitial ad closed out; return to game menu now
        self.performSegue(withIdentifier: "unwindToGameMenu", sender: self)
    }
    
    public func showRewardAd() {
        // Show the reward ad if we can
        if GADRewardBasedVideoAd.sharedInstance().isReady {
            // MARK: Bug - to avoid a weird bug, I need to load a new view with its own View Controller
            self.present(rewardAdViewController, animated: true, completion: nil)
        }
        else {
            // If we didn't load an ad don't give the user a reward (maybe they're offline?)
        }
    }
    
    // MARK: Public view controller functions
    public func getPauseMenu() -> UIView {
        return pauseMenuView
    }
    
    public func showContinueButton() {
        if false == GADRewardBasedVideoAd.sharedInstance().isReady {
            // If we failed to load a reward ad, don't allow the user to save themselves
            let scene = self.scene as! ContinousGameScene
            scene.endGame()
            return
        }
        
        if let view = self.view as! SKView? {
            view.isPaused = true
            
            let alert = UIAlertController(title: "Continue", message: "Watch a sponsored ad to save yourself", preferredStyle: .alert)
            let yesAction = UIAlertAction(title: "Yes", style: .default) { (handler: UIAlertAction) in
                // Show a reward ad
                // Set this variable so we know what type of reward to give the user
                self.rewardType = ContinuousGameController.RESCUE_REWARD
                self.showRewardAd()
                view.isPaused = false
            }
            let noAction = UIAlertAction(title: "No", style: .default) { (handler: UIAlertAction) in
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
        if GADRewardBasedVideoAd.sharedInstance().isReady && false == undoButton.isEnabled {
            // If we've loaded a reward ad, enable the button
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
        
        scene.saveState()
        
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
        // Show interstitial ad here if we have one loaded
        if interstitialAd.isReady {
            interstitialAd.present(fromRootViewController: self)
        }
        else {
            self.performSegue(withIdentifier: "unwindToGameMenu", sender: self)
        }
    }
    
    @IBAction func undoTurn(_ sender: Any) {
        // Set this variable so we know what type of reward to give the user
        rewardType = ContinuousGameController.UNDO_REWARD
        showRewardAd()
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
