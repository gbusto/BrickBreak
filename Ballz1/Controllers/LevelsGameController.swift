//
//  LevelsGameController.swift
//  Ballz1
//
//  Created by hemingway on 1/13/19.
//  Copyright © 2019 Self. All rights reserved.
//

import UIKit
import SpriteKit
import GoogleMobileAds

class LevelsGameController: UIViewController,
                            GADBannerViewDelegate,
                            GADInterstitialDelegate {
    
    @IBOutlet weak var levelCount: UILabel!
    @IBOutlet weak var levelScore: UILabel!
    
    @IBOutlet var pauseMenuView: UIView!
    @IBOutlet weak var resumeButton: UIButton!
    @IBOutlet weak var gameMenuButton: UIButton!
    
    @IBOutlet weak var bannerAdView: UIView!
    
    private var scene: SKScene?
    
    override func viewDidAppear(_ animated: Bool) {
        // Load the stuff for ads
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Notification that says the app is going into the background
        let backgroundNotification = Notification(name: .NSExtensionHostWillResignActive)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppGoingBackground), name: backgroundNotification.name, object: nil)
        
        // Notification that the app will terminate
        let notification = Notification(name: .init("appTerminate"))
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppTerminate), name: notification.name, object: nil)
        
        if let view = self.view as! SKView? {
            let scene = LevelsGameScene(size: view.bounds.size)
            self.scene = scene
            
            scene.scaleMode = .aspectFill
            
            pauseMenuView.center = CGPoint(x: view.frame.midX, y: view.frame.midY)
            resumeButton.imageView?.contentMode = .scaleAspectFit
            gameMenuButton.imageView?.contentMode = .scaleAspectFit
            
            view.presentScene(scene)
            view.ignoresSiblingOrder = true
        }
    }
    
    @IBAction func statusBarTapped(_ sender: UITapGestureRecognizer) {
        let scene = self.scene as! LevelsGameScene
        if let view = self.view as! SKView? {
            scene.isPaused = true
            view.isPaused = true
            scene.showPauseScreen(pauseView: pauseMenuView)
        }
    }
    
    @IBAction func resumeButtonPressed(_ sender: Any) {
        let scene = self.scene as! LevelsGameScene
        scene.resumeGame()
    }
    
    @IBAction func gameMenuButtonPressed(_ sender: Any) {
        // Show an interstitial ad here
        self.performSegue(withIdentifier: "unwindToGameMenu", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Prepare for a segue
    }
    
    @IBAction func prepareForUnwind(segue: UIStoryboardSegue) {
        // Necessary for unwinding views
    }
    
    // MARK: View override functions
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
    
    // MARK: Notification functions
    @objc func handleAppGoingBackground() {
        // App is going into the background so pause it
        
        let scene = self.scene as! LevelsGameScene
        
        if let view = self.view as! SKView? {
            // If the view is paused from showing the Continue? dialog then don't pause the game when it moves to the background
            if false == view.isPaused {
                scene.isPaused = true
                view.isPaused = true
                scene.showPauseScreen(pauseView: pauseMenuView)
            }
        }
    }
    
    @objc func handleAppTerminate() {
        // App is about to terminate
    }
}
