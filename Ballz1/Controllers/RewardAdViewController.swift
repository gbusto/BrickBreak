//
//  RewardAdViewController.swift
//  Ballz1
//
//  Created by Gabriel Busto on 12/7/18.
//  Copyright © 2018 Self. All rights reserved.
//

import UIKit
import GoogleMobileAds

class RewardAdViewController: UIViewController, GADRewardBasedVideoAdDelegate {
    
    func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd, didRewardUserWith reward: GADAdReward) {
        // Give user a reward
        print("Reward user")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
