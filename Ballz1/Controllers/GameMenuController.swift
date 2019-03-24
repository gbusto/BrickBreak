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
                print("Player is already authenticated")
                checkHighScore()
            }
        }
        else {
            print("Player is not yet authenticated")
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
            }
            else {
                if let userScores = scores {
                    print("Got user score: \(userScores[0].value)")
                    
                    // Get the user's high score saved to disk
                    let highScore = self.loadHighScore()
                    // Get the user's high score from the game center
                    let score = userScores[0].value
                    
                    var submitScore = Int64(highScore)
                    if score > highScore {
                        submitScore = score
                    }
                    
                    // Report the game score to the game center
                    let gkscore = GKScore(leaderboardIdentifier: self.LEADERBOARD_ID, player: self.localPlayer!)
                    gkscore.value = Int64(submitScore)
                    GKScore.report([gkscore]) { (error) in
                        if error != nil {
                            print("Error reporting score: \(error!)")
                        }
                    }
                }
            }
        })
    }
}
