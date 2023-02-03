//
//  Review.swift
//  Ballz1
//
//  Created by Gabriel Busto on 4/10/19.
//  Copyright © 2019 Self. All rights reserved.
//

import Foundation
import StoreKit
import FirebaseAnalytics

class Review {
    
    private var reviewPrompt1 = false
    private var reviewPrompt2 = false
    private var reviewPrompt3 = false
    private var reviewPrompt4 = false
    
    private var dataManager: DataManager = DataManager.shared
    
    struct PersistentData: Codable {
        // The last date on which the user was prompted for a review
        var lastDatePrompted: TimeInterval
    }
    
    static var shared = Review()
    
    private init() {
        if let reviewPromptData = DataManager.shared.loadReviewPromptData() {
            reviewPrompt1 = reviewPromptData.reviewPrompt1
            reviewPrompt2 = reviewPromptData.reviewPrompt2
            reviewPrompt3 = reviewPromptData.reviewPrompt3
            reviewPrompt4 = reviewPromptData.reviewPrompt4
        }
    }
    
    public func promptForReview() {
        if false == reviewPrompt1 {
            // Set this variable so we don't prompt again for reviewPrompt1 within this same session
            reviewPrompt1 = true
            
            // Analytics log event; log when the user gets prompted to leave a review
            Analytics.logEvent("reviewPrompt1", parameters: /* None */ [:])
            dataManager.saveReviewPromptData(reviewPrompt1: reviewPrompt1, reviewPrompt2: reviewPrompt2, reviewPrompt3: reviewPrompt3, reviewPrompt4: reviewPrompt4)
            SKStoreReviewController.requestReview()
        }
        else {
            print("Already prompted user for review!")
        }
    }
}
