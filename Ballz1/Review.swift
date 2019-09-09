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
    
    private var reviewPrompt1 = false
    private var reviewPrompt2 = false
    private var reviewPrompt3 = false
    private var reviewPrompt4 = false
    
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
            print("Prompting user for a review")
            /* XXX UNCOMMENT THESE LINES
            DataManager.shared.saveReviewPromptData(reviewPrompt1: true, reviewPrompt2: reviewPrompt2, reviewPrompt3: reviewPrompt3, reviewPrompt4: reviewPrompt4)
            SKStoreReviewController.requestReview()
            */
        }
        else {
            print("Already prompted user for review!")
        }
    }
}
