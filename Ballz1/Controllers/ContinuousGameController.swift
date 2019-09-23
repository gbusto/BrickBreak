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
import FirebaseAnalytics

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
    @IBOutlet var heartImageView: UIImageView!
    
    private var rewardAdViewController: RewardAdViewController!
    
    // Made this conditional because I want it to be nil when we start to know whether or not it's been initialized
    private var startingScore: Int?
    private var reviewer: Review?
    
    private var userWasRescued = false
    // Number of times the user has undone their turn in this current session
    private var numTimesUndoTurn = 0
    
    private var showedReward = false
    private var rewardType = ContinuousGameController.NO_REWARD
    static private var NO_REWARD = Int(0)
    static private var UNDO_REWARD = Int(1)
    static private var RESCUE_REWARD = Int(2)
    
    static private var DISABLED_ALPHA = CGFloat(0.1)
    static private var ENABLED_ALPHA = CGFloat(1.0)
    
    override func viewDidAppear(_ animated: Bool) {
        Analytics.setScreenName("ClassicGame", screenClass: NSStringFromClass(ContinousGameScene.classForCoder()))
        
        // Check if we need to show the tutorial
        if let initialOnboardingState = DataManager.shared.loadInitialOnboardingState() {
            if false == initialOnboardingState.showedClassicOnboarding {
                showInitialOnboarding()
            }
            else {
                // Already showed classic onboarding
            }
        }
        else {
            // Haven't saved/loaded any onboarding state
            showInitialOnboarding()
        }
        
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
        
        // Register these notifications here
        
        // Notification that says the app is going into the background
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive(notification:)), name: UIApplication.willResignActiveNotification, object: nil)
        
        // Notification that says the app is going into the foreground
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(notification:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        // Notification that the app will terminate
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillTerminate(notification:)), name: UIApplication.willTerminateNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // Remove ourselves from observing notifications
        // We need to do this in THIS function because something maintains a strong reference to this ViewController and we can't use deinit because this will not get deallocated. Meaning these background/foreground/app-terminate notifications will keep firing for classic in the background even after switching game modes. Worse yet, since we add observers for these notifications each time viewDidAppear is called, it will register more observers and so when the app goes into the background, these notifications will stack up and trigger multiple times
        
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func applicationWillTerminate(notification: Notification) {
        // Analytics log event; log when app terminates during classic game
        Analytics.logEvent("classic_game_terminate", parameters: /* None */ [:])
        
        // Analytics log event: when the user stops playing classic mode, see how many turns they played
        analyticsLogClassicStop()
        
        let contScene = scene as! ContinousGameScene
        contScene.saveState()
    }
    
    @objc func applicationWillResignActive(notification: Notification) {
        // App is going into the background
        
        // Analytics log event; log when classic comes back into the background
        Analytics.logEvent("classic_game_background", parameters: /* None */ [:])
        
        let scene = self.scene as! ContinousGameScene
        
        scene.saveState()
        
        // Don't pause the game when it goes to the background if the gameover overlay is showing
        if scene.isGameOverShowing() {
            return
        }
        
        // View will automatically be paused here; manually pause the scene here
        scene.isPaused = true
        scene.showPauseScreen()
    }
    
    @objc func applicationDidBecomeActive(notification: Notification) {
        // App is coming back into the foreground
        
        // Analytics log event; log when classic comes back into the foreground
        Analytics.logEvent("classic_game_foreground", parameters: /* None */ [:])
        
        if let view = self.view as! SKView? {
            // Keep this variable set to true; the app will automatically set isPaused to false when the app comes back into view
            view.isPaused = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
            let scene = ContinousGameScene(size: view.bounds.size)
            self.scene = scene
            
            scene.scaleMode = .aspectFill
            scene.gameController = self
            
            disableUndoButton()
            
            pauseMenuView.center = CGPoint(x: view.frame.midX, y: view.frame.midY)
            // XXX These lines might not be needed anymore since we're not using images
            resumeButton.imageView?.contentMode = .scaleAspectFit
            returnGameMenuButton.imageView?.contentMode = .scaleAspectFit
            
            resumeButton.layer.cornerRadius = resumeButton.frame.height * 0.5
            returnGameMenuButton.layer.cornerRadius = returnGameMenuButton.frame.height * 0.5
            
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
            userWasSaved()
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
        
        // Unpause the game
        let scene = self.scene as! ContinousGameScene
        // Set these isPaused variables to false to unpause the game after a reward ad
        scene.isPaused = false
        if let view = self.view as! SKView? {
            view.isPaused = false
        }
        print("Unpaused game")
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
            // Pause the game before showing the ad
            let scene = self.scene as! ContinousGameScene
            scene.isPaused = true
            if let view = self.view as! SKView? {
                view.isPaused = true
            }
            print("Pausing game")
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
            // Pause the game while the continue/rescue button is showing
            view.isPaused = true
            
            let alert = UIAlertController(title: "Continue", message: "Watch a sponsored ad to save yourself", preferredStyle: .alert)
            let yesAction = UIAlertAction(title: "Yes", style: .default) { (handler: UIAlertAction) in
                // Analytics log event: log that the user didn't accept to rescue themselves after losing in classic mode
                Analytics.logEvent("classic_rescue", parameters: [
                    "accepted": 1 as NSNumber
                ])
                
                // Show a reward ad
                // Set this variable so we know what type of reward to give the user
                self.rewardType = ContinuousGameController.RESCUE_REWARD
                self.showRewardAd()
            }
            let noAction = UIAlertAction(title: "No", style: .default) { (handler: UIAlertAction) in
                // Analytics log event: log that the user didn't accept to rescue themselves after losing in classic mode
                Analytics.logEvent("classic_rescue", parameters: [
                    "accepted": 0 as NSNumber
                ])
                
                let scene = self.scene as! ContinousGameScene
                // Should be able to just call handleGameOver()
                scene.endGame()
            }
            
            alert.addAction(yesAction)
            alert.addAction(noAction)
            
            present(alert, animated: false, completion: nil)
        }
    }
    
    public func enableUndoButton(force: Bool = false) {
        // Enable the undo button IF AND ONLY IF: 1) force is true, or 2) if a reward ad is loaded
        if GADRewardBasedVideoAd.sharedInstance().isReady && false == undoButtonIsEnabled() {
            // If we've loaded a reward ad, enable the button
            undoButton.alpha = ContinuousGameController.ENABLED_ALPHA
        }
        else if force {
            undoButton.alpha = ContinuousGameController.ENABLED_ALPHA
        }
    }
    
    public func disableUndoButton() {
        if undoButtonIsEnabled() {
            undoButton.alpha = ContinuousGameController.DISABLED_ALPHA
        }
    }
    
    public func userWasSaved() {
        // Also called by the game scene when loading classic game state so this should be correct between game sessions
        heartImageView.image = UIImage(named: "used_life")
        userWasRescued = true
    }
    
    public func undoButtonIsEnabled() -> Bool {
        return undoButton.alpha >= ContinuousGameController.ENABLED_ALPHA
    }
    
    // XXX Should update this function name to gameMenuButtonPressed
    @IBAction func returnToGameMenu(_ sender: Any) {
        // Return to Game Menu button pressed on pause screen
        
        // Analytics log event; user went to game menu after pausing
        Analytics.logEvent("classic_pause_gamemenu", parameters: /* None */ [:])
        
        // Analytics log event: when the user stops playing classic mode, see how many turns they played
        analyticsLogClassicStop()
        
        let contScene = scene as! ContinousGameScene
        contScene.saveState()
        
        handleGameOver()
    }
    
    @IBAction func resumeGame(_ sender: Any) {
        // Analytics log event; user resumed game after pausing it
        Analytics.logEvent("classic_pause_resume", parameters: /* None */ [:])
        
        // Unpause the game (view and scene)
        let contScene = scene as! ContinousGameScene
        if let view = self.view as! SKView? {
            contScene.resumeGame()
            view.isPaused = false
            contScene.isPaused = false
        }
    }
    
    @IBAction func statusBarTapped(_ sender: Any) {
        // Analytics log event; user paused classic game by tapping on the status bar
        Analytics.logEvent("classic_pause_game", parameters: /* None */ [:])
        
        let scene = self.scene as! ContinousGameScene
        // Pause the game when the status bar is tapped
        if let view = self.view as! SKView? {
            scene.isPaused = true
            view.isPaused = true
            scene.showPauseScreen()
        }
    }

    public func handleGameOver() {
        let userRescuedInt = userWasRescued ? 1 : 0
        // Analytics log event: the user lost in classic mode; still need classic_stop (stopping a game, but not losing)
        Analytics.logEvent("classic_end", parameters: [
            AnalyticsParameterScore: Int("\(gameScoreLabel.text!)")! as NSNumber,
            "user_was_rescued": userRescuedInt as NSNumber
        ])
        
        // Pause the game now
        if let view = self.view as! SKView? {
            view.isPaused = true
        }
        
        // Show interstitial ad here if we have one loaded
        if interstitialAd.isReady {
            interstitialAd.present(fromRootViewController: self)
        }
        else {
            self.performSegue(withIdentifier: "unwindToGameMenu", sender: self)
        }
    }
    
    @IBAction func undoTurn(_ sender: Any) {
        // Analytics log event: log when the user presses the undo button
        Analytics.logEvent("classic_undo_button", parameters: /* None */ [:])
        numTimesUndoTurn += 1
        
        // If the button isn't enabled, notify the user
        if false == undoButtonIsEnabled() {
            // If it's disabled, inform the user that they can't undo at this time
            let contScene = scene as! ContinousGameScene
            contScene.notifyCantUndo()
        }
        // If the button is enabled, either show an ad if it's loaded or undo the turn if the ad isn't loaded
        else {
            // Check if a reward ad is loaded
            if GADRewardBasedVideoAd.sharedInstance().isReady {
                // Set this variable so we know what type of reward to give the user
                rewardType = ContinuousGameController.UNDO_REWARD
                showRewardAd()
            }
            else {
                // If no reward ad is loaded, just undo the turn
                let contScene = scene as! ContinousGameScene
                contScene.loadPreviousTurnState()
            }
        }
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
        
        if nil == startingScore {
            // The user just started playing classic mode (either a new game or from saved state)
            
            if 0 == gameScore {
                // The user is starting a new classic game
                Analytics.logEvent("classic_start", parameters: /* None */ [:])
            }
            else {
                // The user returned to a classic game
                Analytics.logEvent("classic_return", parameters: /* None */ [:])
            }
            startingScore = gameScore
        }
        
        // If the user's game score is > 100 and they've played at least 10 turns, ask them if they want to leave a review
        if gameScore >= 50 && (gameScore - startingScore!) > 10 {
            Review.shared.promptForReview()
        }
    }
    
    // MARK: View override functions
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
    
    private func showInitialOnboarding() {
        // Analytics log event; classic tutorial end
        Analytics.logEvent("classic_tutorial_begin", parameters: /* None */ [:])
        
        let viewController = UIStoryboard.init(name: "BrickBreak", bundle: nil).instantiateViewController(withIdentifier: "ClassicTutorialController")
        self.present(viewController, animated: true, completion: nil)
    }
    
    private func analyticsLogClassicStop() {
        // Analytics log event: when the user stops playing classic mode, see how many turns they played
        let numTurnsPlayed = Int(gameScoreLabel!.text!)! - startingScore!
        Analytics.logEvent("classic_stop", parameters: [
            "turns_played": numTurnsPlayed as NSNumber,
            "number_turns_undone": numTimesUndoTurn as NSNumber,
        ])
    }
}
