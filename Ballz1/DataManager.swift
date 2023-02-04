//
//  DataManager.swift
//  Ballz1
//
//  Created by hemingway on 7/2/19.
//  Copyright © 2019 Self. All rights reserved.
//

import Foundation
import GameplayKit

class DataManager {
    
    /* Paths:
     Classic Persistent Data: /<AppDocumentDir>/BB/PersistentData
     Classic Game State: /<AppDocumentDir>/BB/ContinuousDir/GameState
     Classic Ball State: /<AppDocumentDir>/BB/ContinuousDir/BallManager
     Classic Item State: /<AppDocumentDir>/BB/ContinuousDir/ItemGenerator
    */

    // For storing data
    static let AppDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    // This is the main app directory
    static let AppDirURL = AppDirectory.appendingPathComponent("BB")
    
    // This is persistent data that will contain the high score
    static let PersistentDataURL = AppDirURL.appendingPathComponent("PersistentData")
    // The directory to store game state for this game type (classic mode)
    static let ClassicDirURL = AppDirURL.appendingPathComponent("ContinuousDir")
    // The path where game state is stored for this game mode
    static let ClassicGameStateURL = ClassicDirURL.appendingPathComponent("GameState")

    // The directory to store game state for this game type
    static let LevelsDirURL = AppDirURL.appendingPathComponent("LevelsDir")
    // The path where game state is stored for this game mode
    static let LevelsPersistentDataURL = LevelsDirURL.appendingPathComponent("PersistentData")
    
    static let OnboardingDirURL = AppDirURL.appendingPathComponent("OnboardingDir")
    static let InitialOnboardingStateURL = OnboardingDirURL.appendingPathComponent("InitialOnboardingState")
    
    static let ReviewPromptDataURL = AppDirURL.appendingPathComponent("ReviewPromptData")
    
    // Path for saving ball manager state
    static let BallManagerPath = "BallManager"
    // Path for saving item generator state
    static let ItemGeneratorPath = "ItemGenerator"
    
    // Struct to save/load ball state
    struct BallManagerState: Codable {
        var numberOfBalls: Int
        var originPoint: CGPoint?
        
        enum CodingKeys: String, CodingKey {
            case numberOfBalls
            case originPoint
        }
    }
    
    // Struct to save/load item state
    struct ItemGeneratorState: Codable {
        var numberOfBalls: Int
        var itemTypeDict: [Int: Int]
        // An array of tuples where index 0 is the item type (SPACER, HIT_BLOCK, BALL, etc) and index 1 is the hit block count (it's only really needed for hit block items)
        var itemArray: [[Int]]
        // TODO: Fix this. This is really dumb; in code, hit count should be a property contained by an object, not in a separate array like this.
        var itemHitCountArray: [[Int]]
        var blockTypeArray: [Int]
        var nonBlockTypeArray: [Int]
        
        enum CodingKeys: String, CodingKey {
            case numberOfBalls
            case itemTypeDict
            case itemArray
            case itemHitCountArray
            case blockTypeArray
            case nonBlockTypeArray
        }
    }
    
    // Struct to save/load persistent level data
    struct LevelsPersistentData: Codable {
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
    
    // Struct to save/load classic game data
    struct ClassicPersistentData: Codable {
        var highScore: Int
        var showedTutorials: Bool
        
        // This serves as the authoritative list of properties that must be included when instances of a codable type are encoded or decoded
        // Read Apple's documentation on CodingKey protocol and Codable
        enum CodingKeys: String, CodingKey {
            case highScore
            case showedTutorials
        }
    }
    
    func createClassicPersistentData(highScore: Int, showedTutorials: Bool) -> ClassicPersistentData {
        return ClassicPersistentData(highScore: highScore, showedTutorials: showedTutorials)
    }
    
    // This struct is used for managing any state from this class that is required to save the user's place
    struct ClassicGameState: Codable {
        var gameScore: Int
        var userWasSaved: Bool
        
        enum CodingKeys: String, CodingKey {
            case gameScore
            case userWasSaved
        }
    }
    
    func createClassicGameState(gameScore: Int, userWasSaved: Bool) -> ClassicGameState {
        return ClassicGameState(gameScore: gameScore, userWasSaved: userWasSaved)
    }
    
    struct InitialOnboardingState: Codable {
        var showedClassicOnboarding: Bool
        var showedLevelOnboarding: Bool
        
        enum CodingKeys: String, CodingKey {
            case showedClassicOnboarding
            case showedLevelOnboarding
        }
    }
    
    struct ReviewPromptData: Codable {
        var reviewPrompt1: Bool
        var reviewPrompt2: Bool
        var reviewPrompt3: Bool
        var reviewPrompt4: Bool
        
        enum CodingKeys: String, CodingKey {
            case reviewPrompt1
            case reviewPrompt2
            case reviewPrompt3
            case reviewPrompt4
        }
    }
    
    
    // MARK: Initializer
    static let shared = DataManager()
    
    
    private init() {}
    
    
    // MARK: Public functions to save data
    
    // Function to save ball manager state
    public func saveClassicBallState(numberOfBalls: Int, originPoint: CGPoint) -> Bool {
        let url = DataManager.ClassicDirURL.appendingPathComponent(DataManager.BallManagerPath)
        
        do {
            let bmState = BallManagerState(numberOfBalls: numberOfBalls, originPoint: originPoint)
            let data = try PropertyListEncoder().encode(bmState)
            try data.write(to: url, options: .completeFileProtectionUnlessOpen)
            print("Saved classic ball state: \(bmState)")
            return true
        }
        catch {
            print("Error saving ball manager state: \(error)")
            return false
        }
    }
    
    // Function to save item generator state
    public func saveClassicItemGeneratorState(numberOfBalls: Int, itemTypeDict: [Int: Int], itemArray: [[Int]], itemHitCountArray: [[Int]], blockTypeArray: [Int], nonBlockTypeArray: [Int]) -> Bool {
        
        let url = DataManager.ClassicDirURL.appendingPathComponent(DataManager.ItemGeneratorPath)
        
        do {
            let igState = ItemGeneratorState(numberOfBalls: numberOfBalls, itemTypeDict: itemTypeDict, itemArray: itemArray, itemHitCountArray: itemHitCountArray, blockTypeArray: blockTypeArray, nonBlockTypeArray: nonBlockTypeArray)
            
            let data = try PropertyListEncoder().encode(igState)
            try data.write(to: url, options: .completeFileProtectionUnlessOpen)
            print("Saved classic item generator state: \(igState)")
            return true
        }
        catch {
            print("Error saving item generator state: \(error)")
            return false
        }
    }
    
    public func saveClassicPersistentData(highScore: Int, showedTutorials: Bool) -> Bool {
        do {
            // Create the App directory Documents/BB
            if false == FileManager.default.fileExists(atPath: DataManager.AppDirURL.path) {
                try FileManager.default.createDirectory(at: DataManager.AppDirURL, withIntermediateDirectories: true, attributes: nil)
            }
            
            let classicPersistentData = ClassicPersistentData(highScore: highScore, showedTutorials: showedTutorials)
            
            // Save the persistent data
            let pData = try PropertyListEncoder().encode(classicPersistentData)
            try pData.write(to: DataManager.PersistentDataURL, options: .completeFileProtectionUnlessOpen)
            print("Saved classic persistent data: \(classicPersistentData)")
            return true
        }
        catch {
            print("Error saving persistent state: \(error)")
            return false
        }
    }
    
    public func saveClassicGameState(gameScore: Int, userWasSaved: Bool) -> Bool {
        do {
            // Create the directory for this game mode (Documents/BB/ContinuousDir)
            if false == FileManager.default.fileExists(atPath: DataManager.ClassicDirURL.path) {
                try FileManager.default.createDirectory(at: DataManager.ClassicDirURL, withIntermediateDirectories: true, attributes: nil)
            }
            
            let classicGameState: ClassicGameState = ClassicGameState(gameScore: gameScore, userWasSaved: userWasSaved)
            
            // Save the game data
            let pData = try PropertyListEncoder().encode(classicGameState)
            try pData.write(to: DataManager.ClassicGameStateURL, options: .completeFileProtectionUnlessOpen)
            print("Saved classic game state: \(classicGameState)")
            return true
        }
        catch {
            print("Error encoding game state: \(error)")
            return false
        }
    }
    
    public func saveLevelsPersistentData(levelCount: Int, highScore: Int, cumulativeScore: Int, showedTutorials: Bool) -> Bool {
        
        do {
            // Create the App directory Documents/BB
            if false == FileManager.default.fileExists(atPath: DataManager.LevelsDirURL.path) {
                try FileManager.default.createDirectory(at: DataManager.LevelsDirURL, withIntermediateDirectories: true, attributes: nil)
            }
            
            let levelsPersistentData: LevelsPersistentData = LevelsPersistentData(levelCount: levelCount, highScore: highScore, cumulativeScore: cumulativeScore, showedTutorials: showedTutorials)
            
            // Save the persistent data
            let pData = try PropertyListEncoder().encode(levelsPersistentData)
            try pData.write(to: DataManager.LevelsPersistentDataURL, options: .completeFileProtectionUnlessOpen)
            print("Saved levels persistent data: \(levelsPersistentData)")
            return true
        }
        catch {
            print("Error saving persistent state: \(error)")
            return false
        }
    }
    
    public func saveInitialOnboardingState(showedClassicOnboarding: Bool, showedLevelOnboarding: Bool) -> Bool {
        do {
            // Create the App directory Documents/BB
            if false == FileManager.default.fileExists(atPath: DataManager.OnboardingDirURL.path) {
                try FileManager.default.createDirectory(at: DataManager.OnboardingDirURL, withIntermediateDirectories: true, attributes: nil)
            }
            
            let onboardingState: InitialOnboardingState = InitialOnboardingState(showedClassicOnboarding: showedClassicOnboarding, showedLevelOnboarding: showedLevelOnboarding)
            
            // Save the onboarding data
            let pData = try PropertyListEncoder().encode(onboardingState)
            try pData.write(to: DataManager.InitialOnboardingStateURL, options: .completeFileProtectionUnlessOpen)
            print("Saved onboarding data: \(onboardingState)")
            return true
        }
        catch {
            print("Error saving onboarding state: \(error)")
            return false
        }
    }
    
    public func saveReviewPromptData(reviewPrompt1: Bool, reviewPrompt2: Bool, reviewPrompt3: Bool, reviewPrompt4: Bool) -> Bool {
        do {
            // Create the App directory Documents/BB
            if false == FileManager.default.fileExists(atPath: DataManager.AppDirURL.path) {
                try FileManager.default.createDirectory(at: DataManager.AppDirURL, withIntermediateDirectories: true, attributes: nil)
            }
            
            let reviewPromptData: ReviewPromptData = ReviewPromptData(reviewPrompt1: reviewPrompt1, reviewPrompt2: reviewPrompt2, reviewPrompt3: reviewPrompt3, reviewPrompt4: reviewPrompt4)
            
            // Save the review prompt data
            let pData = try PropertyListEncoder().encode(reviewPromptData)
            try pData.write(to: DataManager.ReviewPromptDataURL, options: .completeFileProtectionUnlessOpen)
            print("Saved review prompt state: \(reviewPromptData)")
            return true
        }
        catch {
            print("Error saving review data: \(error)")
            return false
        }
    }
    
    
    // MARK: Public functions to load data
    
    // Function to load ball manager data
    public func loadClassicBallState() -> BallManagerState? {
        do {
            let url = DataManager.ClassicDirURL.appendingPathComponent(DataManager.BallManagerPath)
            let data = try Data(contentsOf: url)
            let bmState: BallManagerState = try PropertyListDecoder().decode(BallManagerState.self, from: data)
            print("Loaded classic ball state: \(bmState)")
            return bmState
        }
        catch {
            print("Error loading ball manager state: \(error)")
            return nil
        }
    }
    
    // Function to load item generator data
    public func loadClassicItemGeneratorState() -> ItemGeneratorState? {
        do {
            let url = DataManager.ClassicDirURL.appendingPathComponent(DataManager.ItemGeneratorPath)
            let data = try Data(contentsOf: url)
            let igState: ItemGeneratorState = try PropertyListDecoder().decode(ItemGeneratorState.self, from: data)
            print("Loaded classic item generator state: \(igState)")
            return igState
        }
        catch {
            print("Error loading item generator state: \(error)")
            return nil
        }
    }
    
    // Function to load classic persistent data
    public func loadClassicPeristentData() -> ClassicPersistentData? {
        do {
            let data = try Data(contentsOf: DataManager.PersistentDataURL)
            let persistentData: ClassicPersistentData = try PropertyListDecoder().decode(DataManager.ClassicPersistentData.self, from: data)
            print("Loaded classic persistent data: \(persistentData)")
            return persistentData
        }
        catch {
            print("Error loading persistent data state: \(error)")
            return nil
        }
    }
    
    // Function to load classic game state
    public func loadClassicGameState() -> ClassicGameState? {
        do {
            let data = try Data(contentsOf: DataManager.ClassicGameStateURL)
            let gameState: ClassicGameState = try PropertyListDecoder().decode(DataManager.ClassicGameState.self, from: data)
            print("Loaded classic game state: \(gameState)")
            return gameState
        }
        catch {
            print("Error loading persistent data state: \(error)")
            return nil
        }
    }
    
    public func loadLevelsPersistentData() -> LevelsPersistentData? {
        do {
            let data = try Data(contentsOf: DataManager.LevelsPersistentDataURL)
            let persistentData: LevelsPersistentData = try PropertyListDecoder().decode(DataManager.LevelsPersistentData.self, from: data)
            print("Loaded levels persistent data: \(persistentData)")
            return persistentData
        }
        catch {
            print("Error loading persistent data state: \(error)")
            return nil
        }
    }
    
    public func loadInitialOnboardingState() -> InitialOnboardingState? {
        do {
            let data = try Data(contentsOf: DataManager.InitialOnboardingStateURL)
            let onboardingState: InitialOnboardingState = try PropertyListDecoder().decode(DataManager.InitialOnboardingState.self, from: data)
            print("Loaded initial onboarding state: \(onboardingState)")
            return onboardingState
        }
        catch {
            print("Error loading initial onboarding state: \(error)")
            return nil
        }
    }
    
    public func loadReviewPromptData() -> ReviewPromptData? {
        do {
            let data = try Data(contentsOf: DataManager.ReviewPromptDataURL)
            let reviewState: ReviewPromptData = try PropertyListDecoder().decode(DataManager.ReviewPromptData.self, from: data)
            print("Loaded review prompt state: \(reviewState)")
            return reviewState
        }
        catch {
            print("Error loading review prompt data: \(error)")
            return nil
        }
    }
    
    
    // MARK: Public functions to clear game state/data
    
    // Function to remove classic game state after the user loses (so we don't load it up next time they go to play classic mode)
    // THIS DOES NOT CLEAR ANY PERSISTENT DATA
    public func clearClassicGameState() {
        do {
            try FileManager.default.removeItem(atPath: DataManager.ClassicGameStateURL.path)
            try FileManager.default.removeItem(atPath: DataManager.ClassicDirURL.path)
            print("Successfully cleared classic game state")
        }
        catch {
            print("Error clearing classic game state: \(error)")
        }
    }
    
    public func clearLevelsPersistentData() {
        do {
            return
            // UNCOMMENT THIS LINE TO TRULY REMOVE LEVELS PERSISTENT GAME DATA
            //try FileManager.default.removeItem(atPath: LevelsGameModel.LevelsDirURL.path)
        }
        catch {
            print("Error clearing state: \(error)")
        }
    }
}
