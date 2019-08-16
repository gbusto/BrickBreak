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
                            GADInterstitialDelegate,
                            GADRewardBasedVideoAdDelegate {
    
    @IBOutlet weak var levelCount: UILabel!
    @IBOutlet weak var levelScore: UILabel!
    @IBOutlet var rowCountLabel: UILabel!
    @IBOutlet var heartImageView: UIImageView!
    
    @IBOutlet var gameOverView: UIView!
    @IBOutlet var gameOverLevelCount: UILabel!
    @IBOutlet var gameOverLevelScore: UILabel!

    @IBOutlet var pauseMenuView: UIView!
    @IBOutlet weak var resumeButton: UIButton!
    @IBOutlet weak var gameMenuButton: UIButton!
    
    @IBOutlet weak var bannerAdView: GADBannerView!
    
    private var interstitialAd: GADInterstitial!
    
    private var rewardAdViewController: RewardAdViewController!
    
    private var userWasRewarded = false
    
    private var leaveGame = false
    private var gameEnded = false
    
    // Number of consecutive wins the user has had
    private var numConsecutiveWins = 0
    
    private var reviewer: Review?
    
    private var scene: SKScene?
    
    override func viewDidAppear(_ animated: Bool) {
        // Check if we need to show the tutorial
        if let initialOnboardingState = DataManager.shared.loadInitialOnboardingState() {
            if false == initialOnboardingState.showedLevelOnboarding {
                showInitialOnboarding()
            }
            else {
                // Already showed levels onboarding
            }
        }
        else {
            showInitialOnboarding()
        }
        
        // Load the banner ad view
        bannerAdView.adUnitID = AdHandler.getBannerAdID()
        bannerAdView.rootViewController = self
        bannerAdView.delegate = self
        
        // Load the banner ad
        let bannerAdRequest = GADRequest()
        bannerAdRequest.testDevices = AdHandler.getTestDevices()
        bannerAdView.load(bannerAdRequest)
        
        prepareInterstitialAd()
        
        // Load the reward ad
        let rewardAdRequest = GADRequest()
        rewardAdRequest.testDevices = AdHandler.getTestDevices()
        GADRewardBasedVideoAd.sharedInstance().load(rewardAdRequest, withAdUnitID: AdHandler.getRewardAdID())
        
        rewardAdViewController = RewardAdViewController()
        
        GADRewardBasedVideoAd.sharedInstance().delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Notification that says the app is going into the background
        let backgroundNotification = Notification(name: .NSExtensionHostWillResignActive)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppGoingBackground), name: backgroundNotification.name, object: nil)
        
        // Notification that the app will terminate
        let notification = Notification(name: .init("appTerminate"))
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppTerminate), name: notification.name, object: nil)
        
        goToGameScene()
        
        reviewer = Review()
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
    
    // MARK: Interstitial ad functions
    public func interstitialDidReceiveAd(_ ad: GADInterstitial) {
        // Received an interstitial ad
    }
    
    public func interstitial(_ ad: GADInterstitial, didFailToReceiveAdWithError error: GADRequestError) {
        // Failed to receive an interstitial ad
    }
    
    public func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        // Interstitial ad closed out; prepare a new one unless the user wants to exit the game
        if leaveGame {
            returnToMenu()
        }
        // The interstitialAd object can only be used once so we need to prepare a new one each time the ad object is used
        prepareInterstitialAd()
        
        if numConsecutiveWins == 2 {
            print("Attempting to prompt user for review")
            // After the user has won 2 consecutive games in a row, attempt to prompt them for a review
            // XXX UNCOMMENT THIS WHENEVER I HAVE A BETTER PLAN FOR IT
            //reviewer!.attemptReview()
        }
    }
    
    public func prepareInterstitialAd() {
        // Prepare to load interstitial ad
        interstitialAd = GADInterstitial(adUnitID: AdHandler.getInterstitialAdID())
        interstitialAd.delegate = self
        
        // Attempt to load the interstitial ad
        let intAdRequest = GADRequest()
        intAdRequest.testDevices = AdHandler.getTestDevices()
        interstitialAd.load(intAdRequest)
    }
    
    // MARK: Reward ad functions
    public func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd, didRewardUserWith reward: GADAdReward) {
        // User was rewarded
        let scene = self.scene as! LevelsGameScene
        scene.saveUser()
        heartImageView.image = UIImage(named: "used_life")
        userWasRewarded = true
    }
    
    public func rewardBasedVideoAdDidClose(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        // The reward ad closed out
        
        // Dismiss the reward ad view controller
        rewardAdViewController.dismiss(animated: true, completion: nil)
        
        let scene = self.scene as! LevelsGameScene
        if let view = self.view as! SKView? {
            scene.isPaused = false
            view.isPaused = false
        }
        
        if false == userWasRewarded {
            // Show the level loss screen because the user skipped the reward ad
            gameOver(win: false)
        }
    }
    
    @IBAction func statusBarTapped(_ sender: UITapGestureRecognizer) {
        let scene = self.scene as! LevelsGameScene
        if let view = self.view as! SKView? {
            scene.isPaused = true
            view.isPaused = true
            scene.showPauseScreen(pauseView: pauseMenuView)
        }
    }
    
    // MARK: Pause Menu Button Handlers
    @IBAction func resumeButtonPressed(_ sender: Any) {
        let scene = self.scene as! LevelsGameScene
        scene.resumeGame()
    }
    
    @IBAction func gameMenuButtonPressed(_ sender: Any) {
        // Show an interstitial ad here
        if interstitialAd.isReady {
            leaveGame = true
            interstitialAd.present(fromRootViewController: self)
        }
        else {
            returnToMenu()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Prepare for a segue
    }
    
    @IBAction func prepareForUnwind(segue: UIStoryboardSegue) {
        // Necessary for unwinding views
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
    
    // MARK: Notification functions
    @objc func handleAppGoingBackground() {
        // App is going into the background so pause it
        
        if gameEnded {
            // If the game ended, don't pause the screen
            return
        }
        
        let scene = self.scene as! LevelsGameScene
        
        if let view = self.view as! SKView? {
            // If the view is paused from showing the Continue? dialog then don't pause the game when it moves to the background
            if false == view.isPaused {
                scene.isPaused = true
                view.isPaused = true
                scene.showPauseScreen(pauseView: pauseMenuView)
            }
        }
    }
    
    @objc func handleAppTerminate() {
        // App is about to terminate
    }
    
    // MARK: Public controller functions
    public func goToGameScene() {
        // Reset the level score
        levelScore.text = "0"
        
        // Reset the heart (life) image
        heartImageView.image = UIImage(named: "unused_life")
        
        // Reset this boolean
        userWasRewarded = false
        
        // Reset this boolean so the game will pause correctly
        gameEnded = false
        
        if let view = self.view as! SKView? {
            let scene = LevelsGameScene(size: view.bounds.size)
            self.scene = scene
            
            scene.scaleMode = .aspectFill
            scene.gameController = self
            
            pauseMenuView.center = CGPoint(x: view.frame.midX, y: view.frame.midY)
            // XXX This code may not be necessary anymore
            resumeButton.imageView?.contentMode = .scaleAspectFit
            gameMenuButton.imageView?.contentMode = .scaleAspectFit
            
            resumeButton.layer.cornerRadius = resumeButton.frame.height * 0.5
            gameMenuButton.layer.cornerRadius = gameMenuButton.frame.height * 0.5
            
            gameOverView.center = CGPoint(x: view.frame.midX, y: view.frame.midY)
            
            view.presentScene(scene)
            view.ignoresSiblingOrder = true
        }
    }
    
    public func setLevelNumber(level: Int) {
        levelCount.text = "\(level)"
    }
    
    public func updateRowCountLabel(currentCount: Int, maxCount: Int) {
        rowCountLabel.text = "\(currentCount)/\(maxCount)"
    }
    
    public func updateScore(score: Int) {
        let currentScore = Int(levelScore.text!)!
        if currentScore < score {
            levelScore.text = "\(currentScore + 1)"
        }
    }
    
    public func gameOverLoss() {
        gameEnded = true
        
        let scene = self.scene as! LevelsGameScene
        
        if scene.gameModel!.savedUser {
            // If the user has already been saved, return to the game menu
            gameOver(win: false)
            return
        }
        
        if scene.gameModel!.getActualRowCount() <= 4 {
            // If the user loses and there are only 4 rows on the screen, don't save them. They need to restart the level
            gameOver(win: false)
            return
        }
        
        if false == GADRewardBasedVideoAd.sharedInstance().isReady {
            print("Reward ad isn't ready...")
            // If we failed to load a reward ad, don't allow the user to save themselves
            gameOver(win: false)
            return
        }
        else {
            print("Reward ad is ready")
        }
        
        let alert = UIAlertController(title: "Continue", message: "Watch a sponsored ad to save yourself", preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "Yes", style: .default) { (handler: UIAlertAction) in
            // Show a reward ad
            if GADRewardBasedVideoAd.sharedInstance().isReady {
                let scene = self.scene as! LevelsGameScene
                scene.isPaused = true
                if let view = self.view as! SKView? {
                    view.isPaused = true
                }
                self.gameEnded = false
                self.present(self.rewardAdViewController, animated: true, completion: nil)
            }
        }
        let noAction = UIAlertAction(title: "No", style: .default) { (handler: UIAlertAction) in
            // User doesn't want to watch an ad
            self.gameOver(win: false)
        }
        
        alert.addAction(yesAction)
        alert.addAction(noAction)
        
        present(alert, animated: false, completion: nil)
    }
    
    public func gameOver(win: Bool) {
        gameEnded = true
        
        let scene = self.scene as! LevelsGameScene
        
        let strokeTextAttributes: [NSAttributedString.Key: Any] = [
            .strokeColor: UIColor.white,
            .foregroundColor: UIColor.black,
            .strokeWidth: -1.0,
        ]
        
        var currentLevelCount = scene.gameModel!.levelCount
        if win {
            // At this point in the logic, if the user won then the level count will have incremented by 1
            // We want to show them the level they just beat/lost
            currentLevelCount -= 1
        }
        
        gameOverLevelCount.attributedText = NSAttributedString(string: "Level \(currentLevelCount)",
            attributes: strokeTextAttributes)
        gameOverLevelScore.attributedText = NSAttributedString(string: "\(scene.gameModel!.gameScore)",
            attributes: strokeTextAttributes)
        
        // If they beat their high score, let them know
        
        scene.showGameOverView(win: win, gameOverView: gameOverView)
        
        if win {
            numConsecutiveWins += 1
            print("User has had \(numConsecutiveWins) wins in a row")
        }
        else {
            numConsecutiveWins = 0
            print("User lost... zeroed out numConsecutiveWins")
        }
        
        let _ = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            let scene = self.scene as! LevelsGameScene
            if win {
                // We only want to remove the confetti if the user won
                scene.removeConfetti()
            }
            scene.removeGameOverView()
            
            // Show an interstitial ad
            if self.interstitialAd.isReady {
                self.interstitialAd.present(fromRootViewController: self)
            }
            
            // Replay the game scene; state should have already been saved
            self.goToGameScene()
        }
    }
    
    // MARK: Private functions
    private func returnToMenu() {
        self.performSegue(withIdentifier: "unwindToGameMenu", sender: self)
    }
    
    private func showInitialOnboarding() {
        print("Showing classic onboarding")
        let viewController = UIStoryboard.init(name: "BrickBreak", bundle: nil).instantiateViewController(withIdentifier: "LevelsTutorialController")
        self.present(viewController, animated: true, completion: nil)
    }
}
