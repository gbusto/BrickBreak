//
//  RewardAdViewController.swift
//  Ballz1
//
//  Created by Gabriel Busto on 12/8/18.
//  Copyright © 2018 Self. All rights reserved.
//

import UIKit
import GoogleMobileAds

class RewardAdViewController: UIViewController {
    
    override func viewDidAppear(_ animated: Bool) {
        // Can only present after the view has appeared and it is in the window view's heirarchy
        // Overriding viewDidLoad() doesn't work because the view hasn't appeared yet and so we can't display an ad before then
        print("Loaded reward ad view controller")
                
        GADRewardBasedVideoAd.sharedInstance().present(fromRootViewController: self)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
