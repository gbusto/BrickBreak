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
    struct PersistentLevelData: Codable {
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
    
    // This struct is used for managing any state from this class that is required to save the user's place
    struct ClassicGameState: Codable {
        var gameScore: Int
        var userWasSaved: Bool
        
        enum CodingKeys: String, CodingKey {
            case gameScore
            case userWasSaved
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
            return true
        }
        catch {
            print("Error saving persistent state: \(error)")
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
            return persistentData
        }
        catch {
            print("Error loading persistent data state: \(error)")
            return nil
        }
    }
}
