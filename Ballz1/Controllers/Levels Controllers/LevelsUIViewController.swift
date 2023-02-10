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
import FirebaseAnalytics

class LevelsUIViewController: UIViewController {
    
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
    
    // TODO: Move all properties below this line to a new file eventually that will be the actual GameController
    
    // TODO: This should be used instead of going through scene.gameModel
    public var gameModel: LevelsGameModel?
    
    private var userWasRescued = false
    
    private var leaveGame = false
    private var gameEnded = false
    
    private var userJustWon = false
    
    // Number of consecutive wins the user has had
    private var numConsecutiveWins = 0
    // Number of levels completed in a session of playing levels
    private var numLevelsCompleted = 0
    private var numLevelsFailed = 0
    
    private var reviewer: Review?
    
    private var scene: SKScene?
    
    var dataManager: DataManager = DataManager.shared
    
    // - UIViewController function
    override func viewDidAppear(_ animated: Bool) {
        // TODO: Use dependency injection here; this event doesn't need to be fired in testing
        Analytics.setScreenName("LevelsGame", screenClass: NSStringFromClass(LevelsGameScene.classForCoder()))

        // Check if we need to show the tutorial
        if let initialOnboardingState = dataManager.loadInitialOnboardingState() {
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
        
        prepareBannerAd()
        
        prepareInterstitialAd()
        
        prepareRewardAd()
        
        registerForNotifications()
    }
    
    // - UIViewController function
    func registerForNotifications() {
        // Register these notifications
        
        // Notification that says the app is going into the background
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive(notification:)), name: UIApplication.willResignActiveNotification, object: nil)
        
        // Notification that says the app is going into the foreground
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(notification:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        // Notification that the app will terminate
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillTerminate(notification:)), name: UIApplication.willTerminateNotification, object: nil)

    }
    
    // - UIViewController function
    override func viewWillDisappear(_ animated: Bool) {
        // Remove ourselves from observing notifications
        // We need to do this in THIS function because something maintains a strong reference to this ViewController and we can't use deinit because this will not get deallocated. Meaning these background/foreground/app-terminate notifications will keep firing for levels in the background even after switching game modes. Worse yet, since we add observers for these notifications each time viewDidAppear is called, it will register more observers and so when the app goes into the background, these notifications will stack up and trigger multiple times
        
        NotificationCenter.default.removeObserver(self)
    }
    
    // - UIViewController function
    @objc func applicationWillTerminate(notification: Notification) {
        // App is about to terminate
        
        // Analytics log event; log when the app terminates from levels
        Analytics.logEvent("levels_game_terminate", parameters: /* None */ [:])
        
        // Analytics log event: when the user stops playing classic mode, see how many turns they played
        analyticsLogLevelsStop()
    }
    
    // - UIViewController function
    @objc func applicationWillResignActive(notification: Notification) {
        // App is going into the background
        
        // Analytics log event; log when levels comes back into the background
        Analytics.logEvent("levels_game_background", parameters: /* None */ [:])
        
        // App is going into the background so pause it
        
        if gameEnded {
            // If the game ended, don't pause the screen
            return
        }
        
        pauseGame()
    }
    
    // - UIViewController function
    @objc func applicationDidBecomeActive(notification: Notification) {
        // App is coming back into the foreground
        
        // Analytics log event; log when levels goes into the foreground
        Analytics.logEvent("levels_game_foreground", parameters: /* None */ [:])
        
        pauseView()
    }
    
    // - UIViewController function
    deinit {
        // This function will never be called here because something maintains a strong reference to this view controller; I'm assuming it has something to do with the fact that it's created in the BrickBreak.storyboard file
    }
    
    // - UIViewController function
    override func viewDidLoad() {
        super.viewDidLoad()
        
        goToGameScene()
    }
    
    // - UIViewController function
    // TODO: I believe this code is very similar in the continuous game controller too. This could be moved to its own file.
    @IBAction func statusBarTapped(_ sender: UITapGestureRecognizer) {
        // Analytics log event; user paused classic game by tapping on the status bar
        Analytics.logEvent("levels_pause_game", parameters: /* None */ [:])
        
        // NOTE: Order matters here. Scene must be paused first, then the view.
        pauseGame()
    }
    
    // - UIViewController function
    func pauseGame() {
        let scene = getGameScene()
        scene.pauseGame(pauseMenuView: pauseMenuView)
    }
    
    // - UIViewController function
    func pauseView() {
        if let view = self.view as! SKView? {
            view.isPaused = true
        }
    }
    
    // MARK: Pause Menu Button Handlers
    // - UIViewController function
    @IBAction func resumeButtonPressed(_ sender: Any) {
        // Analytics log event; user resumed game after pausing it
        Analytics.logEvent("levels_pause_resume", parameters: /* None */ [:])
        
        unpauseGame()
    }
    
    // - UIViewController function
    func unpauseGame() {
        let scene = getGameScene()
        scene.unpauseGame()
    }
    
    // - UIViewController function
    func unpauseView() {
        if let view = self.view as! SKView? {
            view.isPaused = false
        }
    }
    
    // - UIViewController function
    @IBAction func gameMenuButtonPressed(_ sender: Any) {
        // Analytics log event; user went to game menu after pausing
        Analytics.logEvent("levels_pause_gamemenu", parameters: /* None */ [:])
        
        // Analytics log event: when the user stops playing classic mode, see how many turns they played
        analyticsLogLevelsStop()
        
        // Show an interstitial ad here
        if interstitialAd.isReady {
            leaveGame = true
            interstitialAd.present(fromRootViewController: self)
        }
        else {
            returnToMenu()
        }
    }
    
    // - UIViewController function
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Prepare for a segue
    }
    
    // - UIViewController function
    @IBAction func prepareForUnwind(segue: UIStoryboardSegue) {
        // Necessary for unwinding views
    }
    
    // MARK: View override functions
    override var shouldAutorotate: Bool {
        return true
    }
    
    // - UIViewController function
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .portrait
        } else {
            return .portrait
        }
    }
    
    // - UIViewController function
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: Public controller functions
    /*
     This is a helper function to load the levels game scene
     */
    // - UIViewController function (mixed with some GameController code)
    public func goToGameScene() {
        // Reset the level score
        levelScore.text = "0"
        
        // Reset the heart (life) image
        heartImageView.image = UIImage(named: "unused_life")
        
        // Reset this boolean
        userWasRescued = false
        
        // Reset this boolean so the game will pause correctly
        gameEnded = false
        
        // TODO: Fix this anti-pattern; controller should not communicate directly with a view
        if let view = self.view as! SKView? {
            let scene = getNewLevelsGameScene()
            
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
    
    // - UIViewController function
    func getNewLevelsGameScene() -> SKScene {
        let scene = LevelsGameScene(size: view.bounds.size)
        self.scene = scene
        
        scene.scaleMode = .aspectFill
        scene.gameController = self

        return scene
    }
    
    // - UIViewController function
    public func setLevelNumber(level: Int) {
        levelCount.text = "\(level)"
        
        // Analytics log event: start of a level; this is a provided analytics method from google, not a custom event
        // This function (setLevelNumber()) is called when the level starts after initializing the game model
        Analytics.logEvent("level_start", parameters: [
            AnalyticsParameterLevel: level as NSNumber,
        ])
    }
    
    // - UIViewController function
    public func updateRowCountLabel(currentCount: Int, maxCount: Int) {
        rowCountLabel.text = "\(currentCount)/\(maxCount)"
    }
    
    // - UIViewController function
    public func updateScore(score: Int) {
        levelScore.text = "\(score)"
    }
    
    // - UIViewController function
    public func setScore(score: Int) {
        // Used for app demos
        levelScore.text = "\(score)"
    }
    
    func getGameScene() -> LevelsGameScene {
        return self.scene as! LevelsGameScene
    }
    
    // - GameController function (mixed with some UIViewController code)
    public func gameOverLoss() {
        // Pause the game here
        pauseView()
        
        gameEnded = true
        
        let scene = getGameScene()
        
        // TODO: This is horrible! The controller should not access the model through the view! Fix this
        // The controller should have direct access to the model, and it should actually tell the model whether or not the game should be over
        if scene.gameModel!.savedUser {
            // If the user has already been saved, return to the game menu
            gameOver(win: false)
            return
        }
        
        if scene.gameModel!.getActualRemainingRowCount() <= 4 {
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
        
        showRewardAdAlertView()
    }
    
    // - UIViewController function (mixed with some GameController code)
    func showRewardAdAlertView() {
        // TODO: Fix this. I don't think the controller should be creating UI Alert, that should be a responsibility of the UI/View
        let alert = UIAlertController(title: "Continue", message: "Watch a sponsored ad to save yourself", preferredStyle: .alert)
        // TODO: This is another area where we are creating a strong retain cycle with `self` in this closure. Fix it
        let yesAction = UIAlertAction(title: "Yes", style: .default) { (handler: UIAlertAction) in
            // Analytics log event: log that the user didn't accept to rescue themselves after losing a level
            Analytics.logEvent("level_rescue", parameters: [
                "accepted": 1 as NSNumber
            ])
            
            // Show a reward ad
            if GADRewardBasedVideoAd.sharedInstance().isReady {
                let scene = self.getGameScene()
                // Pause the game before showing the reward ad
                scene.realPaused = true
                if let view = self.view as! SKView? {
                    view.isPaused = true
                }
                self.gameEnded = false
                if GADRewardBasedVideoAd.sharedInstance().isReady {
                    GADRewardBasedVideoAd.sharedInstance().present(fromRootViewController: self)
                }
            }
        }
        let noAction = UIAlertAction(title: "No", style: .default) { (handler: UIAlertAction) in
            // Analytics log event: log that the user didn't accept to rescue themselves after losing a level
            Analytics.logEvent("level_rescue", parameters: [
                "accepted": 0 as NSNumber
            ])
            
            // User doesn't want to watch an ad
            self.gameOver(win: false)
        }
        
        alert.addAction(yesAction)
        alert.addAction(noAction)
        
        present(alert, animated: false, completion: nil)
    }
    
    // - GameController function (mixed with UIViewController code)
    public func gameOver(win: Bool) {
        gameEnded = true
        
        let scene = getGameScene()
        let strokeTextAttributes: [NSAttributedString.Key: Any] = [
            .strokeColor: UIColor.white,
            .foregroundColor: UIColor.black,
            .strokeWidth: -1.0,
        ]
        
        // TODO: Fix this! Controller should not be accessing the model through the view!
        var currentLevelCount = scene.gameModel!.levelCount
        if win {
            // At this point in the logic, if the user won then the level count will have incremented by 1
            // We want to show them the level they just beat/lost
            currentLevelCount -= 1
            
            // Set this flag to true to let the game know the user just won to show them a review prompt if they haven't seen it yet
            userJustWon = true
            
            // Used for determining when we might be able to prompt the use for a positive review (they're more likely to be happy if they've completed more than 1 level successfully)
            numConsecutiveWins += 1
            // Used in analytics to determine how many levels were completed in a session
            numLevelsCompleted += 1
        }
        else {
            // Set this flag to false to let the game know the user just won to show them a review prompt if they haven't seen it yet
            userJustWon = false
            
            numConsecutiveWins = 0
            // Increment the number of levels failed
            numLevelsFailed += 1
        }
        
        gameOverLevelCount.attributedText = NSAttributedString(string: "Level \(currentLevelCount)",
            attributes: strokeTextAttributes)
        gameOverLevelScore.attributedText = NSAttributedString(string: "\(scene.gameModel!.gameScore)",
            attributes: strokeTextAttributes)
        
        // If they beat their high score, let them know
        
        // Unpause the game
        unpauseView()
        
        scene.showGameOverView(win: win, gameOverView: gameOverView)
        
        // Analytics log event: level ending; send over the level number that just endedNS whether or not they just beat this level
        logAnalyticsLevelEnded(win: win, userWasRescued: userWasRescued, levelCount: currentLevelCount)
        
        startTimerToKickOffNextGame(shouldRemoveConfetti: win)
    }
    
    func boolToInt(value: Bool) -> Int {
        return value ? 1 : 0
    }
    
    // - GameController functions
    func logAnalyticsLevelEnded(win: Bool, userWasRescued: Bool, levelCount: Int) {
        let winInt = boolToInt(value: win)
        let userWasRescuedInt = boolToInt(value: userWasRescued)

        Analytics.logEvent("level_end", parameters: [
            AnalyticsParameterLevel: levelCount as NSNumber,
            AnalyticsParameterSuccess: winInt as NSNumber,
            AnalyticsParameterScore: Int("\(levelScore.text!)")! as NSNumber,
            "rescued": userWasRescuedInt as NSNumber,
        ])
    }
    
    // - UIViewController functions
    func startTimerToKickOffNextGame(shouldRemoveConfetti: Bool) {
        let _ = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            let scene = self.getGameScene()
            if shouldRemoveConfetti {
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
        // Analytics log event; levels tutorial begin
        Analytics.logEvent("levels_tutorial_begin", parameters: /* None */ [:])
        
        let viewController = UIStoryboard.init(name: "BrickBreak", bundle: nil).instantiateViewController(withIdentifier: "LevelsTutorialController")
        self.present(viewController, animated: true, completion: nil)
    }
    
    private func analyticsLogLevelsStop() {
        // Analytics log event: when the user stops playing classic mode, see how many turns they played
        Analytics.logEvent("level_stop", parameters: [
            "levels_completed": numLevelsCompleted,
            "levels_failed": numLevelsFailed,
        ])
    }
}

// - UIViewController functions
// MARK: - Banner ad functions
extension LevelsUIViewController: GADBannerViewDelegate {
    public func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        // Error loading the ad; hide the banner
        bannerView.isHidden = true
        print("Error loading ad: \(error.localizedDescription)")
    }
    
    public func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        // Received an ad; show the banner now
        bannerView.isHidden = false
    }
    
    public func prepareBannerAd() {
        // Load the banner ad view
        // TODO: This could be encapsulated in a function call to another dependency; it doesn't need to be run when testing
        bannerAdView.adUnitID = AdHandler.getBannerAdID()
        bannerAdView.rootViewController = self
        bannerAdView.delegate = self
        
        // Load the banner ad
        let bannerAdRequest = GADRequest()
        bannerAdRequest.testDevices = AdHandler.getTestDevices()
        bannerAdView.load(bannerAdRequest)
    }
}

// - UIViewController functions
// MARK: - Interstitial ad functions
extension LevelsUIViewController: GADInterstitialDelegate {
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
            return
        }
        // The interstitialAd object can only be used once so we need to prepare a new one each time the ad object is used
        prepareInterstitialAd()
        
        // If the user just own, prompt them to leave a review
        if userJustWon {
            let levelNumber = Int(levelCount.text!)!
            if levelNumber >= 10 {
                Review.shared.promptForReview()
            }
        }
        
        // Reset this variable here after checking it; it was originally being reset to false when the game scene started over which would happen before this callback function gets called so it would never resolve to true
        userJustWon = false
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
    
}

// - UIViewController functions
// MARK: - Reward ad functions
extension LevelsUIViewController: GADRewardBasedVideoAdDelegate {
    public func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd, didRewardUserWith reward: GADAdReward) {
        // User was rewarded
        let scene = getGameScene()
        scene.saveUser()
        heartImageView.image = UIImage(named: "used_life")
        userWasRescued = true
    }
    
    public func rewardBasedVideoAdDidClose(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        // Analytics: I think google auto tracks whether or not the user compeleted the reward ad

        // The reward ad closed out
        
        let scene = getGameScene()
        if let view = self.view as! SKView? {
            // Unpause the game after the reward ad closes
            scene.realPaused = false
            view.isPaused = false
        }
        
        if false == userWasRescued {
            // Show the level loss screen because the user skipped the reward ad
            gameOver(win: false)
        }
    }
    
    public func prepareRewardAd() {
        // Load the reward ad
        let rewardAdRequest = GADRequest()
        rewardAdRequest.testDevices = AdHandler.getTestDevices()
        GADRewardBasedVideoAd.sharedInstance().load(rewardAdRequest, withAdUnitID: AdHandler.getRewardAdID())
        
        GADRewardBasedVideoAd.sharedInstance().delegate = self
    }
}