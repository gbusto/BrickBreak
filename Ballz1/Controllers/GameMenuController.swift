//
//  GameMenuController.swift
//  Ballz1
//
//  Controller for the game menu to handle button clicks and taps
//
//  Created by Gabriel Busto on 10/6/18.
//  Copyright © 2018 Self. All rights reserved.
//

import UIKit
import GameKit
import SpriteKit
import GameplayKit
import AVFoundation

class GameMenuController: UIViewController, GKGameCenterControllerDelegate {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var levelsButton: UIButton!
    @IBOutlet var gameCenterButton: UIButton!
    @IBOutlet var rateButton: UIButton!
    
    /* Variables */
    var gcEnabled = Bool() // Check if the user has Game Center enabled
    var gcDefaultLeaderBoard = String() // Check the default leaderboardID
    var isAuthenticated = false
    var localPlayer: GKLocalPlayer?
    
    // IMPORTANT: replace the red string below with your own Leaderboard ID (the one you've set in iTunes Connect)
    let LEADERBOARD_ID = "xyz.ashgames.brickbreak"
    let LEVELS_LEADERBOARD_ID = "xyz.ashgames.brickbreak.levelnumber"
    
    private var classicButtonColorValue1 = 0x1599FF
    private var classicButtonColorValue2 = 0x3F6CFF
    private var levelsButtonColorValue1 = 0xD4008E
    private var levelsButtonColorValue2 = 0xFF1597

    // Get the user's current level number from Levels game mode (saved to disk)
    func loadLevelNumber() -> Int {
        let persistentData = DataManager.shared.loadLevelsPersistentData()
        if nil == persistentData {
            return 0
        }
        print("Read level number '\(persistentData!.levelCount)' from disk")
        return persistentData!.levelCount
    }
    
    // Get the user's high score from Classic game mode (saved to disk)
    func loadHighScore() -> Int {
        let persistentData = DataManager.shared.loadClassicPeristentData()
        if nil == persistentData {
            return 0
        }
        print("Read high score '\(persistentData!.highScore)' from disk")
        return persistentData!.highScore
    }
    
    // Update the user's high score locally (when game center has a higher score on record than is on disk)
    func updateHighScore(score: Int64) {
        print("Saving high score '\(Int(score))' to disk")
        let persistentData = DataManager.shared.loadClassicPeristentData()
        DataManager.shared.saveClassicPersistentData(highScore: Int(score), showedTutorials: persistentData!.showedTutorials)
    }
    
    // XXX Not currently being used but will be in the future
    func updateLevelNumber(level: Int64) {
        print("Saving high score '\(Int(level))' to disk")
        let persistentData = DataManager.shared.loadLevelsPersistentData()
        DataManager.shared.saveLevelsPersistentData(levelCount: Int(level), highScore: persistentData!.highScore, cumulativeScore: persistentData!.cumulativeScore, showedTutorials: persistentData!.showedTutorials)
    }
    
    // MARK: Gamecenter delegate protocol
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }
    
    func authenticatePlayer() {
        localPlayer = GKLocalPlayer.local
        localPlayer!.authenticateHandler = {(ViewController, error) -> Void in
            if ((ViewController) != nil) {
                // 1. Show login if player is not logged in
                self.present(ViewController!, animated: true, completion: nil)
            }
            else if (self.localPlayer!.isAuthenticated) {
                // 2. Player is already authenticated and logged in; load game center
                self.gcEnabled = true
                
                // Get the default leaderboard ID
                self.localPlayer!.loadDefaultLeaderboardIdentifier(completionHandler: { (leaderboardIdentifier, error) in
                    if error != nil {
                        print("Error getting leaderboard: \(error!)")
                    }
                    else {
                        // I'm assuming the app uses the default leaderboard until one is created for the game
                        // When the first score is reported to a leaderboard, that board is now the default one
                        self.gcDefaultLeaderBoard = leaderboardIdentifier!
                        
                        // Enable the game center button
                        self.gameCenterButton.isEnabled = true
                        
                        self.checkHighScore()
                        self.checkLevelNumber()
                    }
                })
            }
            else {
                // 3. Game center is not enabled on the users device
                self.gcEnabled = false
                print("Local player could not be authenticated! \(error!)")
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let classicGradientLayer = createButtonGradient(button: playButton, color1: UIColor(rgb: classicButtonColorValue1), color2: UIColor(rgb: classicButtonColorValue2))
        playButton.backgroundColor = .clear
        playButton.layer.insertSublayer(classicGradientLayer, at: 0)
        playButton.addTarget(self, action: #selector(classicButtonTouchEvent), for: .allEvents)
        
        let levelsGradientLayer = createButtonGradient(button: levelsButton, color1: UIColor(rgb: levelsButtonColorValue1), color2: UIColor(rgb: levelsButtonColorValue2))
        levelsButton.backgroundColor = .clear
        levelsButton.layer.insertSublayer(levelsGradientLayer, at: 0)
        levelsButton.addTarget(self, action: #selector(levelsButtonTouchEvent), for: .allEvents)
        
        gameCenterButton.layer.cornerRadius = gameCenterButton.frame.height * 0.5
        rateButton.layer.cornerRadius = rateButton.frame.height * 0.5
        
        // Authenticate the player and submit their high score
        if let lp = localPlayer {
            // Player is already auth'ed, load their high score
            if lp.isAuthenticated {
                checkHighScore()
                checkLevelNumber()
            }
        }
        else {
            authenticatePlayer()
        }
        
        // Allow background music/apps to keep playing
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: .defaultToSpeaker)
        }
        catch let error as NSError {
            print("AVAudioSession error: \(error)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
            let scene = GameMenuScene(size: view.bounds.size)
            scene.scaleMode = .aspectFill
            
            playButton.imageView?.contentMode = .scaleAspectFit
            levelsButton.imageView?.contentMode = .scaleAspectFit
            gameCenterButton.imageView?.contentMode = .scaleAspectFit
            rateButton.imageView?.contentMode = .scaleAspectFit
            
            view.presentScene(scene)
            
            view.ignoresSiblingOrder = true
        }
    }
    
    @IBAction private func classicButtonTouchEvent(sender: Any?, forEvent event: UIEvent) {
        // This is the only way I found to get the button background color to change on press; the events and states aren't enough
        // Get all touch associated with the play button
        if let touches = event.touches(for: playButton) {
            // There should only be one, so attempt to get the only touch event
            if let touch = touches.first {
                // Check for the touch began phase
                if touch.phase == .began {
                    // The button has been pressed
                    let color1 = adjustColor(color: classicButtonColorValue1, offset: 0x101010, add: false)
                    let color2 = adjustColor(color: classicButtonColorValue2, offset: 0x101010, add: false)
                    let gradientLayer = createButtonGradient(button: playButton, color1: color1, color2: color2)
                    playButton.backgroundColor = .clear
                    playButton.layer.insertSublayer(gradientLayer, at: 0)
                    playButton.layer.sublayers!.remove(at: 1)
                }
                    // Check for the touch ended phase
                else if touch.phase == .ended {
                    // The button has been depressed
                    let color1 = UIColor(rgb: classicButtonColorValue1)
                    let color2 = UIColor(rgb: classicButtonColorValue2)
                    let gradientLayer = createButtonGradient(button: playButton, color1: color1, color2: color2)
                    playButton.backgroundColor = .clear
                    playButton.layer.insertSublayer(gradientLayer, at: 0)
                    playButton.layer.sublayers!.remove(at: 1)
                }
            }
        }
    }
    
    @IBAction private func levelsButtonTouchEvent(sender: Any?, forEvent event: UIEvent) {
        // This is the only way I found to get the button background color to change on press; the events and states aren't enough
        // Get all touch associated with the play button
        if let touches = event.touches(for: levelsButton) {
            // There should only be one, so attempt to get the only touch event
            if let touch = touches.first {
                // Check for the touch began phase
                if touch.phase == .began {
                    // The button has been pressed
                    let color1 = adjustColor(color: levelsButtonColorValue1, offset: 0x101010, add: false)
                    let color2 = adjustColor(color: levelsButtonColorValue2, offset: 0x101010, add: false)
                    let gradientLayer = createButtonGradient(button: levelsButton, color1: color1, color2: color2)
                    levelsButton.backgroundColor = .clear
                    levelsButton.layer.insertSublayer(gradientLayer, at: 0)
                    levelsButton.layer.sublayers!.remove(at: 1)
                }
                    // Check for the touch ended phase
                else if touch.phase == .ended {
                    // The button has been depressed
                    let color1 = UIColor(rgb: levelsButtonColorValue1)
                    let color2 = UIColor(rgb: levelsButtonColorValue2)
                    let gradientLayer = createButtonGradient(button: levelsButton, color1: color1, color2: color2)
                    levelsButton.backgroundColor = .clear
                    levelsButton.layer.insertSublayer(gradientLayer, at: 0)
                    levelsButton.layer.sublayers!.remove(at: 1)
                }
            }
        }
    }
    
    @IBAction func showGameCenter(_ sender: Any) {
        if self.gcEnabled {
            let gameCenterController = GKGameCenterViewController()
            gameCenterController.gameCenterDelegate = self
            gameCenterController.viewState = .leaderboards
            gameCenterController.leaderboardIdentifier = LEADERBOARD_ID
            self.present(gameCenterController, animated: true, completion: nil)
        }
    }
    
    @IBAction func goToAppStore(_ sender: Any) {
        let appleID = "1445634396"
        let appStoreLink = "https://itunes.apple.com/app/id\(appleID)?action=write-review"
        UIApplication.shared.open(URL(string: appStoreLink)!, options: [:], completionHandler: nil)
    }
    
    @IBAction func playGame(_ sender: Any) {
        // Launch game
    }
    
    @IBAction func playLevels(_ sender: Any) {
        // Launch level gameplay
    }
    
    @IBAction func prepareForUnwind(segue: UIStoryboardSegue) {
        // Apparently this is necessary for unwinding views
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
    
    private func checkLevelNumber() {
        let leaderBoard = GKLeaderboard(players: [localPlayer!])
        leaderBoard.identifier = LEVELS_LEADERBOARD_ID
        leaderBoard.timeScope = .allTime
        
        leaderBoard.loadScores(completionHandler: {(scores, error) -> Void in
            if error != nil {
                // Error when attempting to get the level numbers from the leaderboard
                print("Error loading level numbers: \(error)")
            }
            else {
                // XXX Here is where we will add code to make sure the level number on disk matches the level number in GameCenter
                let levelNumber = self.loadLevelNumber()
                self.reportLevelNumber(level: Int64(levelNumber))
            }
        })
    }
    
    /*
     * This function checks the user's high score in game center and compares it to the one locally (on disk)
     * If the score in game center is > than the score on disk, update the user's high score locally
     * If the score locally is > than the score in game center, update the user's high score in game center
     */
    private func checkHighScore() {
        // Get the user's instance of the leaderboard to retrieve their scores
        let leaderBoard = GKLeaderboard(players: [localPlayer!])
        // Set the identifier so it knows what leaderboard to check
        leaderBoard.identifier = gcDefaultLeaderBoard
        // Set the time scopre for the score to return (we just set this to all time to go back to the very beginning of time)
        leaderBoard.timeScope = .allTime
        
        leaderBoard.loadScores(completionHandler: {(scores, error) -> Void in
            if error != nil {
                print("Error loading scores: \(error)")
                // Report a high score of 0 (game center won't overwrite this unless it's higher than what it has on record)
                // I'm also assuming an error would be thrown here if the user doesn't have a score on the leaderboard yet which is why I'm including this in this code block
                self.reportHighScore(score: 0)
            }
            else {
                if let userScores = scores {
                    // Get the user's high score saved to disk
                    let diskScore = self.loadHighScore()
                    // Get the user's high score from the game center
                    let gcScore = userScores[0].value
                    
                    if diskScore > gcScore {
                        self.reportHighScore(score: Int64(diskScore))
                    }
                    
                    if gcScore > diskScore {
                        self.updateHighScore(score: gcScore)
                    }
                }
            }
        })
    }
    
    // Report the high score to game center
    private func reportHighScore(score: Int64) {
        // Report the game score to the game center
        let gkscore = GKScore(leaderboardIdentifier: LEADERBOARD_ID, player: localPlayer!)
        gkscore.value = Int64(score)
        GKScore.report([gkscore]) { (error) in
            if error != nil {
                print("Error reporting score: \(error!)")
            }
        }
    }
    
    private func reportLevelNumber(level: Int64) {
        let gkscore = GKScore(leaderboardIdentifier: LEVELS_LEADERBOARD_ID, player: localPlayer!)
        gkscore.value = level
        GKScore.report([gkscore]) { (error) in
            if error != nil {
                print("Error reporting score: \(error!)")
            }
        }
    }
    
    private func createButtonGradient(button: UIButton, color1: UIColor, color2: UIColor) -> CAGradientLayer {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = button.bounds
        gradientLayer.colors = [color1.cgColor, color2.cgColor]
        gradientLayer.cornerRadius = button.frame.height * 0.5
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0)
        gradientLayer.locations = [0.0, 1.0]
        return gradientLayer
    }
    
    private func adjustColor(color: Int, offset: Int, add: Bool) -> UIColor {
        /*
            Params:
                color - An int that is the RGB color as an Int
                offset - The offset int to subtract from the RGB int
        */
        
        var int1 = (color & 0xff0000) >> 16
        var int2 = (color & 0x00ff00) >> 8
        var int3 = color & 0x0000ff
        
        let off1 = (offset & 0xff0000) >> 16
        let off2 = (offset & 0x00ff00) >> 8
        let off3 = offset & 0x0000ff
        
        if add {
            int1 += off1
            int2 += off2
            int3 += off3
        }
        else {
            int1 -= off1
            int2 -= off2
            int3 -= off3
        }
        
        if int1 < 0 {
            int1 = 0
        }
        else if int1 > 0xff {
            int1 = 0xff
        }
        
        if int2 < 0 {
            int2 = 0
        }
        else if int2 > 0xff {
            int2 = 0xff
        }
        
        if int3 < 0 {
            int3 = 0
        }
        else if int3 > 0xff {
            int3 = 0xff
        }
        
        return UIColor(rgb: (int1 << 16) + (int2 << 8) + (int3))
    }
}
