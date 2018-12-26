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

class GameMenuController: UIViewController, GKGameCenterControllerDelegate {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet var gameCenterButton: UIButton!
    
    /* Variables */
    var gcEnabled = Bool() // Check if the user has Game Center enabled
    var gcDefaultLeaderBoard = String() // Check the default leaderboardID
    
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
        let localPlayer: GKLocalPlayer = GKLocalPlayer.local
        localPlayer.authenticateHandler = {(ViewController, error) -> Void in
            if ((ViewController) != nil) {
                // 1. Show login if player is not logged in
                self.present(ViewController!, animated: true, completion: nil)
            }
            else if (localPlayer.isAuthenticated) {
                // 2. Player is already authenticated and logged in; load game center
                self.gcEnabled = true
                
                // Get the default leaderboard ID
                localPlayer.loadDefaultLeaderboardIdentifier(completionHandler: { (leaderboardIdentifier, error) in
                    if error != nil {
                        print("Error getting leaderboard: \(error!)")
                    }
                    else {
                        // I'm assuming the app uses the default leaderboard until one is created for the game
                        // When the first score is reported to a leaderboard, that board is now the default one
                        self.gcDefaultLeaderBoard = leaderboardIdentifier!
                        
                        // Try to get the player's high score from storage
                        let highScore = self.loadHighScore()
                        
                        // Report the game score to the game center
                        let gkscore = GKScore(leaderboardIdentifier: self.LEADERBOARD_ID, player: localPlayer)
                        gkscore.value = Int64(highScore)
                        GKScore.report([gkscore]) { (error) in
                            if error != nil {
                                print("Error reporting score: \(error!)")
                            }
                        }
                        
                        // Enable the game center button
                        self.gameCenterButton.isEnabled = true
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
        authenticatePlayer()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
            let scene = GameMenuScene(size: view.bounds.size)
            scene.scaleMode = .aspectFill
            
            playButton.imageView?.contentMode = .scaleAspectFit
            gameCenterButton.imageView?.contentMode = .scaleAspectFit
            
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
    
    @IBAction func playGame(_ sender: Any) {
        // Launch game
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
}
