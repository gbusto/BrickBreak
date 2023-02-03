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
    public var gcEnabled = false // Check if the user has Game Center enabled
    public var gcDefaultLeaderBoard = String() // Check the default leaderboardID
    public var isAuthenticated = false
    public var localPlayer = GKLocalPlayer.local
    
    // Variables for keeping track of their current scores in level and classic
    public var levelCount = 0
    public var classicScore = 0
    
    // Variables for keeping track of their current rank in each of the leaderboards
    public var levelRank = 0
    public var classicRank = 0
    
    // The next player up in level rank and what their level count is
    public var nextLevelRank = 0
    public var nextLevelCount = 0
    // The next player up in classic rank and what their score is
    public var nextClassicRank = 0
    public var nextClassicScore = 0
    
    // IMPORTANT: replace the red string below with your own Leaderboard ID (the one you've set in iTunes Connect)
    static var LEADERBOARD_ID = "xyz.ashgames.brickbreak"
    static var LEVELS_LEADERBOARD_ID = "xyz.ashgames.brickbreak.levelnumber"
    
    var dataManager: DataManager = DataManager.shared
    
    static var shared = GameCenterManager()
    
    private init() {}
    
    public func userIsAuthenticated() {
        gcEnabled = true
        
        // Get the default leaderboard ID
        localPlayer.loadDefaultLeaderboardIdentifier(completionHandler: { (leaderboardIdentifier, error) in
            if error != nil {
                print("Error getting leaderboard: \(error!)")
            }
            else {
                // I'm assuming the app uses the default leaderboard until one is created for the game
                // When the first score is reported to a leaderboard, that board is now the default one
                self.gcDefaultLeaderBoard = leaderboardIdentifier!
                
                self.updateHighScore()
                self.updateLevelNumber()
            }
        })
    }
    
    // Get the user's current level number from Levels game mode (saved to disk)
    public func loadLevelNumber() -> Int {
        let persistentData = dataManager.loadLevelsPersistentData()
        if nil == persistentData {
            return 0
        }
        return persistentData!.levelCount
    }
    
    // Get the user's high score from Classic game mode (saved to disk)
    public func loadHighScore() -> Int {
        let persistentData = dataManager.loadClassicPeristentData()
        if nil == persistentData {
            return 0
        }
        return persistentData!.highScore
    }
    
    // Update the user's high score locally (when game center has a higher score on record than is on disk)
    public func updateHighScore(score: Int64) {
        let persistentData = dataManager.loadClassicPeristentData()
        dataManager.saveClassicPersistentData(highScore: Int(score), showedTutorials: persistentData!.showedTutorials)
    }
    
    public func updateLevelNumber(level: Int64) {
        let persistentData = dataManager.loadLevelsPersistentData()
        dataManager.saveLevelsPersistentData(levelCount: Int(level), highScore: persistentData!.highScore, cumulativeScore: persistentData!.cumulativeScore, showedTutorials: persistentData!.showedTutorials)
    }
    
    public func setNextClassicRank(currentRank: Int) {
        if 1 == currentRank {
            // The user is already ranked #1, no need to get the next player in rank
            return
        }
        
        let leaderBoard = GKLeaderboard()
        leaderBoard.identifier = GameCenterManager.LEADERBOARD_ID
        leaderBoard.range = NSRange(location: currentRank - 1, length: 2)
        
        // XXX Maybe switch to using leaderBoard.localPlayerScore instead of loadScores()
        leaderBoard.loadScores(completionHandler: {(scores, error) -> Void in
            if error != nil {
                // Error when attempting to get the level numbers from the leaderboard
                print("Error loading classic scores: \(error)")
            }
            else {
                if let _scores = scores {
                    for s in _scores {
                        let name = s.player.alias
                        let score = s.value
                        let rank = s.rank
                        self.nextClassicRank = rank
                        self.nextClassicScore = Int(score)
                    }
                }
            }
        })
    }
    
    public func setNextLevelRank(currentRank: Int) {
        if 1 == currentRank {
            // The user is already ranked #1, no need to get the next player in rank
            return
        }
        
        let leaderBoard = GKLeaderboard()
        leaderBoard.identifier = GameCenterManager.LEVELS_LEADERBOARD_ID
        leaderBoard.range = NSRange(location: currentRank - 1, length: 2)
        
        // XXX Maybe switch to using leaderBoard.localPlayerScore instead of loadScores()
        leaderBoard.loadScores(completionHandler: {(scores, error) -> Void in
            if error != nil {
                // Error when attempting to get the level numbers from the leaderboard
                print("Error loading level numbers: \(error)")
            }
            else {
                if let _scores = scores {
                    for s in _scores {
                        let name = s.player.alias
                        let score = s.value
                        let rank = s.rank
                        self.nextLevelRank = rank
                        self.nextLevelCount = Int(score)
                    }
                }
            }
        })
    }
    
    /*
     Should add some tests for these functions to ensure they're working appropriately.
     Separate out the logic for getting scores and rank from GC into another function that can be passed into here as parameters to ensure the correct action is being taken in every case.
    */
    // This function reports the level number and calls loeadLevelNumber
    public func updateLevelNumber() {
        let leaderBoard = GKLeaderboard(players: [localPlayer])
        leaderBoard.identifier = GameCenterManager.LEVELS_LEADERBOARD_ID
        leaderBoard.timeScope = .allTime
        
        // XXX Maybe switch to using leaderBoard.localPlayerScore instead of loadScores()
        leaderBoard.loadScores(completionHandler: {(scores, error) -> Void in
            if error != nil {
                // Error when attempting to get the level numbers from the leaderboard
                print("Error loading level numbers: \(error)")
            }
            else {
                // XXX Here is where we will add code to make sure the level number on disk matches the level number in GameCenter
                if let userScores = scores {
                    // Get the user's level number saved to disk
                    let diskLevelNumber = self.loadLevelNumber()
                    // Get the user's high score from game center
                    let gcLevelNumber = userScores[0].value
                    // Set the user's current rank based on game center
                    self.levelRank = userScores[0].rank
                    
                    self.setNextLevelRank(currentRank: self.levelRank)
                    
                    // Report the higher of the 2 scores between what's saved on disk and what game center reports to be the user's highest score
                    if diskLevelNumber > gcLevelNumber {
                        self.reportLevelNumber(level: Int64(diskLevelNumber))
                    }
            
                    if gcLevelNumber > diskLevelNumber {
                        self.updateLevelNumber(level: Int64(gcLevelNumber))
                    }
                }
            }
        })
    }
    
    /*
     * This function checks the user's high score in game center and compares it to the one locally (on disk)
     * If the score in game center is > than the score on disk, update the user's high score locally
     * If the score locally is > than the score in game center, update the user's high score in game center
     */
    public func updateHighScore() {
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
                    // Set the user's current rank based on game center
                    self.classicRank = userScores[0].rank
                    
                    self.setNextClassicRank(currentRank: self.classicRank)
                    
                    // Report the higher of the 2 scores between what's saved on disk and what game center reports to be the user's highest score
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
