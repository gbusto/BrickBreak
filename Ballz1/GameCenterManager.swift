//
//  GameCenterManager.swift
//  Ballz1
//
//  Created by Gabriel Busto on 9/13/19.
//  Copyright © 2019 Self. All rights reserved.
//

import Foundation
import GameKit
import GameplayKit

class GameCenterManager {
    
    /* Variables */
    public var gcEnabled = Bool() // Check if the user has Game Center enabled
    public var gcDefaultLeaderBoard = String() // Check the default leaderboardID
    public var isAuthenticated = false
    public var localPlayer = GKLocalPlayer.local
    
    // Variables for keeping track of their current scores in level and classic
    public var levelCount = 0
    public var classicScore = 0
    
    // Variables for keeping track of their current rank in each of the leaderboards
    public var levelRank = 0
    public var classicRank = 0
    
    // IMPORTANT: replace the red string below with your own Leaderboard ID (the one you've set in iTunes Connect)
    static var LEADERBOARD_ID = "xyz.ashgames.brickbreak"
    static var LEVELS_LEADERBOARD_ID = "xyz.ashgames.brickbreak.levelnumber"
    
    static var shared = GameCenterManager()
    
    private init() {}
    
    // Get the user's current level number from Levels game mode (saved to disk)
    public func loadLevelNumber() -> Int {
        let persistentData = DataManager.shared.loadLevelsPersistentData()
        if nil == persistentData {
            return 0
        }
        return persistentData!.levelCount
    }
    
    // Get the user's high score from Classic game mode (saved to disk)
    public func loadHighScore() -> Int {
        let persistentData = DataManager.shared.loadClassicPeristentData()
        if nil == persistentData {
            return 0
        }
        return persistentData!.highScore
    }
    
    // Update the user's high score locally (when game center has a higher score on record than is on disk)
    public func updateHighScore(score: Int64) {
        let persistentData = DataManager.shared.loadClassicPeristentData()
        DataManager.shared.saveClassicPersistentData(highScore: Int(score), showedTutorials: persistentData!.showedTutorials)
    }
    
    // XXX Not currently being used but will be in the future
    public func updateLevelNumber(level: Int64) {
        let persistentData = DataManager.shared.loadLevelsPersistentData()
        DataManager.shared.saveLevelsPersistentData(levelCount: Int(level), highScore: persistentData!.highScore, cumulativeScore: persistentData!.cumulativeScore, showedTutorials: persistentData!.showedTutorials)
    }
    
    // XXX UPDATE THIS FUNCTION
    // This function reports the level number and calls loeadLevelNumber
    public func checkLevelNumber() {
        let leaderBoard = GKLeaderboard(players: [localPlayer])
        leaderBoard.identifier = GameCenterManager.LEVELS_LEADERBOARD_ID
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
    
    // XXX UPDATE THIS FUNCTION
    /*
     * This function checks the user's high score in game center and compares it to the one locally (on disk)
     * If the score in game center is > than the score on disk, update the user's high score locally
     * If the score locally is > than the score in game center, update the user's high score in game center
     */
    public func checkHighScore() {
        // Get the user's instance of the leaderboard to retrieve their scores
        let leaderBoard = GKLeaderboard(players: [localPlayer])
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
    
    // XXX UPDATE THIS FUNCTION
    // Report the high score to game center
    public func reportHighScore(score: Int64) {
        // Report the game score to the game center
        let gkscore = GKScore(leaderboardIdentifier: GameCenterManager.LEADERBOARD_ID, player: localPlayer)
        gkscore.value = Int64(score)
        GKScore.report([gkscore]) { (error) in
            if error != nil {
                print("Error reporting score: \(error!)")
            }
        }
    }
    
    // XXX UPDATE THIS FUNCTION
    public func reportLevelNumber(level: Int64) {
        let gkscore = GKScore(leaderboardIdentifier: GameCenterManager.LEVELS_LEADERBOARD_ID, player: localPlayer)
        gkscore.value = level
        GKScore.report([gkscore]) { (error) in
            if error != nil {
                print("Error reporting score: \(error!)")
            }
        }
    }
}
