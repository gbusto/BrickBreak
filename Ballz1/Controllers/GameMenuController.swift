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
    
    struct PersistentData: Codable {
        var highScore: Int
        var showedTutorials: Bool
        
        // This serves as the authoritative list of properties that must be included when instances of a codable type are encoded or decoded
        // Read Apple's documentation on CodingKey protocol and Codable
        enum CodingKeys: String, CodingKey {
            case highScore
            case showedTutorials
        }
    }
    
    // This struct is used for managing persistent data (such as your overall high score, what level you're on, etc)
    struct PersistentLevelsData: Codable {
        var levelCount: Int
        var highScore: Int
        var cumulativeScore: Int
        var showedTutorials: Bool
        
        // This serves as the authoritative list of properties that must be included when instances of a codable type are encoded or decoded
        // Read Apple's documentation on CodingKey protocol and Codable
        enum CodingKeys: String, CodingKey {
            case levelCount
            case highScore
            case cumulativeScore
            case showedTutorials
        }
    }
    
    func loadLevelNumber() -> Int {
        do {
            let pData = try Data(contentsOf: LevelsGameModel.PersistentDataURL)
            let persistentData = try PropertyListDecoder().decode(PersistentLevelsData.self, from: pData)
            
            return persistentData.levelCount
        }
        catch {
            print("Error decoding persistent levels data: \(error)")
            return 0
        }
    }
    
    // Get the user's high score from disk
    func loadHighScore() -> Int {
        do {
            let pData = try Data(contentsOf: ContinuousGameModel.PersistentDataURL)
            let persistentData = try PropertyListDecoder().decode(PersistentData.self, from: pData)
        
            return persistentData.highScore
        }
        catch {
            print("Error decoding persistent game state: \(error)")
            return 0
        }
    }
    
    // Update the user's high score locally (when game center has a higher score on record than is on disk)
    func updateHighScore(score: Int64) {
        do {
            // Bail out if the path to the persistent data doesn't exist
            if false == FileManager.default.fileExists(atPath: ContinuousGameModel.AppDirURL.path) {
                return
            }
            
            var pData = try Data(contentsOf: ContinuousGameModel.PersistentDataURL)
            var persistentData = try PropertyListDecoder().decode(PersistentData.self, from: pData)
            
            // Update the high score for the persistent data saved to disk
            persistentData.highScore = Int(score)
            
            // Save the persistent data
            pData = try PropertyListEncoder().encode(persistentData)
            try pData.write(to: ContinuousGameModel.PersistentDataURL, options: .completeFileProtectionUnlessOpen)
        }
        catch {
            print("Error saving persistent state: \(error)")
        }
    }
    
    // XXX Not currently being used but will be in the future
    func updateLevelNumber(level: Int64) {
        do {
            if false == FileManager.default.fileExists(atPath: LevelsGameModel.AppDirURL.path) {
                return
            }
            
            var pData = try Data(contentsOf: LevelsGameModel.PersistentDataURL)
            var persistentData = try PropertyListDecoder().decode(PersistentLevelsData.self, from: pData)
            
            persistentData.levelCount = Int(level)
            
            pData = try PropertyListEncoder().encode(persistentData)
            try pData.write(to: LevelsGameModel.PersistentDataURL, options: .completeFileProtectionUnlessOpen)
        }
        catch {
            print("Error saving persistent level state: \(error)")
        }
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
}
