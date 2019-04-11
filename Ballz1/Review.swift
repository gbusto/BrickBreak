//
//  Review.swift
//  Ballz1
//
//  Created by Gabriel Busto on 4/10/19.
//  Copyright © 2019 Self. All rights reserved.
//

import Foundation
import StoreKit

class Review {
    
    private var currentDate: NSDate?
    
    // For storing data
    static let AppDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    // This is the main app directory
    static let AppDirURL = AppDirectory.appendingPathComponent("BB")
    // This is persistent data that will contain the high score
    // The directory to store game state for this game type
    static let ReviewDataURL = AppDirURL.appendingPathComponent("ReviewData")
    // The path where game state is stored for this game mode
    static let PersistentDataURL = ReviewDataURL.appendingPathComponent("PersistentData")
    
    //static private var SEVEN_DAYS = TimeInterval(60 * 60 * 24 * 7)
    static private var SEVEN_DAYS = TimeInterval(60 * 60 * 24)
    
    struct PersistentData: Codable {
        // The last date on which the user was prompted for a review
        var lastDatePrompted: TimeInterval
    }
    
    init() {
        currentDate = NSDate()
    }
    
    public func attemptReview() {
        let pData = loadState()
        if nil != pData {
            let timeDifference = currentDate!.timeIntervalSince(Date(timeIntervalSince1970: pData!.lastDatePrompted))
            // If it's been longer than 7 days, prompt the user for a review again
            if timeDifference > Review.SEVEN_DAYS {
                if #available(iOS 10.3, *) {
                    SKStoreReviewController.requestReview()
                    saveState()
                } else {
                    // Fallback on earlier versions
                    // Try any other 3rd party or manual method here.
                }
            }
            else {
                print("Time difference is only \(timeDifference) as opposed to \(Review.SEVEN_DAYS)")
            }
        }
        if nil == pData {
            if #available(iOS 10.3, *) {
                SKStoreReviewController.requestReview()
                saveState()
            } else {
                // Fallback on earlier versions
                // Try any other 3rd party or manual method here.
            }
        }
    }
    
    private func saveState() {
        do {
            if false == FileManager.default.fileExists(atPath: Review.ReviewDataURL.path) {
                try FileManager.default.createDirectory(at: Review.ReviewDataURL, withIntermediateDirectories: true, attributes: nil)
            }
            
            let pData = try PropertyListEncoder().encode(PersistentData(lastDatePrompted: currentDate!.timeIntervalSince1970))
            try pData.write(to: Review.PersistentDataURL, options: .completeFileProtectionUnlessOpen)
        }
        catch {
            print("Error saving persistent data for reviews: \(error)")
        }
    }
    
    private func loadState() -> PersistentData? {
        do {
            let pData = try Data(contentsOf: Review.PersistentDataURL)
            return try PropertyListDecoder().decode(PersistentData.self, from: pData)
            
        }
        catch {
            print("Error decoding persistent review data: \(error)")
            return nil
        }
    }
}
