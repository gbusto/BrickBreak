//
//  GameMenuController.swift
//  Ballz1
//
//  Controller for the game menu to handle button clicks and taps
//
//  Created by Gabriel Busto on 10/6/18.
//  Copyright © 2018 Self. All rights reserved.
//

import UIKit
import GameKit
import SpriteKit
import GameplayKit
import AVFoundation
import FirebaseAnalytics

class GameMenuController: UIViewController, GKGameCenterControllerDelegate {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var levelsButton: UIButton!
    @IBOutlet var gameCenterButton: UIButton!
    @IBOutlet var rateButton: UIButton!
    
    // IMPORTANT: replace the red string below with your own Leaderboard ID (the one you've set in iTunes Connect)
    let LEADERBOARD_ID = "xyz.ashgames.brickbreak"
    let LEVELS_LEADERBOARD_ID = "xyz.ashgames.brickbreak.levelnumber"
    
    private var classicButtonColorValue1 = 0x1599FF
    private var classicButtonColorValue2 = 0x3F6CFF
    private var levelsButtonColorValue1 = 0xD4008E
    private var levelsButtonColorValue2 = 0xFF1597
    
    // MARK: Gamecenter delegate protocol
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }
    
    func authenticatePlayer() {
        let localPlayer = GameCenterManager.shared.localPlayer
        localPlayer.authenticateHandler = {(ViewController, error) -> Void in
            if ((ViewController) != nil) {
                // 1. Show login if player is not logged in
                self.present(ViewController!, animated: true, completion: nil)
            }
            else if (localPlayer.isAuthenticated) {
                // 2. Player is already authenticated and logged in; load game center
                GameCenterManager.shared.gcEnabled = true
                
                // Get the default leaderboard ID
                localPlayer.loadDefaultLeaderboardIdentifier(completionHandler: { (leaderboardIdentifier, error) in
                    if error != nil {
                        print("Error getting leaderboard: \(error!)")
                    }
                    else {
                        // I'm assuming the app uses the default leaderboard until one is created for the game
                        // When the first score is reported to a leaderboard, that board is now the default one
                        GameCenterManager.shared.gcDefaultLeaderBoard = leaderboardIdentifier!
                        
                        // Enable the game center button
                        self.gameCenterButton.isEnabled = true
                        
                        GameCenterManager.shared.checkHighScore()
                        GameCenterManager.shared.checkLevelNumber()
                    }
                })
            }
            else {
                // 3. Game center is not enabled on the users device
                GameCenterManager.shared.gcEnabled = false
                print("Local player could not be authenticated! \(error!)")
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        Analytics.setScreenName("GameMenu", screenClass: NSStringFromClass(GameMenuController.classForCoder()))

        let classicGradientLayer = createButtonGradient(button: playButton, color1: UIColor(rgb: classicButtonColorValue1), color2: UIColor(rgb: classicButtonColorValue2))
        playButton.backgroundColor = .clear
        playButton.layer.insertSublayer(classicGradientLayer, at: 0)
        playButton.addTarget(self, action: #selector(classicButtonTouchEvent), for: .allEvents)
        
        let levelsGradientLayer = createButtonGradient(button: levelsButton, color1: UIColor(rgb: levelsButtonColorValue1), color2: UIColor(rgb: levelsButtonColorValue2))
        levelsButton.backgroundColor = .clear
        levelsButton.layer.insertSublayer(levelsGradientLayer, at: 0)
        levelsButton.addTarget(self, action: #selector(levelsButtonTouchEvent), for: .allEvents)
        
        gameCenterButton.layer.cornerRadius = gameCenterButton.frame.height * 0.5
        rateButton.layer.cornerRadius = rateButton.frame.height * 0.5
        
        // Authenticate the player and submit their high score
        if GameCenterManager.shared.localPlayer.isAuthenticated {
            GameCenterManager.shared.checkHighScore()
            GameCenterManager.shared.checkLevelNumber()
        }
        else {
            authenticatePlayer()
        }
        
        // Allow background music/apps to keep playing
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: .defaultToSpeaker)
        }
        catch let error as NSError {
            print("AVAudioSession error: \(error)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
            let scene = GameMenuScene(size: view.bounds.size)
            scene.scaleMode = .aspectFill
            
            playButton.imageView?.contentMode = .scaleAspectFit
            levelsButton.imageView?.contentMode = .scaleAspectFit
            gameCenterButton.imageView?.contentMode = .scaleAspectFit
            rateButton.imageView?.contentMode = .scaleAspectFit
            
            view.presentScene(scene)
            
            view.ignoresSiblingOrder = true
        }
    }
    
    @IBAction private func classicButtonTouchEvent(sender: Any?, forEvent event: UIEvent) {
        // This is the only way I found to get the button background color to change on press; the events and states aren't enough
        // Get all touch associated with the play button
        if let touches = event.touches(for: playButton) {
            // There should only be one, so attempt to get the only touch event
            if let touch = touches.first {
                // Check for the touch began phase
                if touch.phase == .began {
                    // The button has been pressed
                    let color1 = adjustColor(color: classicButtonColorValue1, offset: 0x101010, add: false)
                    let color2 = adjustColor(color: classicButtonColorValue2, offset: 0x101010, add: false)
                    let gradientLayer = createButtonGradient(button: playButton, color1: color1, color2: color2)
                    playButton.backgroundColor = .clear
                    playButton.layer.insertSublayer(gradientLayer, at: 0)
                    playButton.layer.sublayers!.remove(at: 1)
                }
                    // Check for the touch ended phase
                else if touch.phase == .ended {
                    // The button has been depressed
                    let color1 = UIColor(rgb: classicButtonColorValue1)
                    let color2 = UIColor(rgb: classicButtonColorValue2)
                    let gradientLayer = createButtonGradient(button: playButton, color1: color1, color2: color2)
                    playButton.backgroundColor = .clear
                    playButton.layer.insertSublayer(gradientLayer, at: 0)
                    playButton.layer.sublayers!.remove(at: 1)
                }
            }
        }
    }
    
    @IBAction private func levelsButtonTouchEvent(sender: Any?, forEvent event: UIEvent) {
        // This is the only way I found to get the button background color to change on press; the events and states aren't enough
        // Get all touch associated with the play button
        if let touches = event.touches(for: levelsButton) {
            // There should only be one, so attempt to get the only touch event
            if let touch = touches.first {
                // Check for the touch began phase
                if touch.phase == .began {
                    // The button has been pressed
                    let color1 = adjustColor(color: levelsButtonColorValue1, offset: 0x101010, add: false)
                    let color2 = adjustColor(color: levelsButtonColorValue2, offset: 0x101010, add: false)
                    let gradientLayer = createButtonGradient(button: levelsButton, color1: color1, color2: color2)
                    levelsButton.backgroundColor = .clear
                    levelsButton.layer.insertSublayer(gradientLayer, at: 0)
                    levelsButton.layer.sublayers!.remove(at: 1)
                }
                    // Check for the touch ended phase
                else if touch.phase == .ended {
                    // The button has been depressed
                    let color1 = UIColor(rgb: levelsButtonColorValue1)
                    let color2 = UIColor(rgb: levelsButtonColorValue2)
                    let gradientLayer = createButtonGradient(button: levelsButton, color1: color1, color2: color2)
                    levelsButton.backgroundColor = .clear
                    levelsButton.layer.insertSublayer(gradientLayer, at: 0)
                    levelsButton.layer.sublayers!.remove(at: 1)
                }
            }
        }
    }
    
    @IBAction func showGameCenter(_ sender: Any) {
        // Need to prompt the user if game center is not enabled; maybe they don't know what it is and want it enabled?
        if GameCenterManager.shared.gcEnabled {
            // Analytics log event; the user clicked the game center button
            Analytics.logEvent("game_center_button", parameters: /* None */ [:])
            
            let gameCenterController = GKGameCenterViewController()
            gameCenterController.gameCenterDelegate = self
            gameCenterController.viewState = .leaderboards
            gameCenterController.leaderboardIdentifier = GameCenterManager.LEADERBOARD_ID
            self.present(gameCenterController, animated: true, completion: nil)
        }
    }
    
    @IBAction func goToAppStore(_ sender: Any) {
        // Analytics log event; the user clicked the app review button
        Analytics.logEvent("app_review_button", parameters: /* None */ [:])
        
        let appleID = "1445634396"
        let appStoreLink = "https://itunes.apple.com/app/id\(appleID)?action=write-review"
        UIApplication.shared.open(URL(string: appStoreLink)!, options: [:], completionHandler: nil)
    }
    
    @IBAction func playGame(_ sender: Any) {
        // Launch game
        print("Clicked classic button")
        Analytics.logEvent("play_classic_mode", parameters: /* None */ [:])
    }
    
    @IBAction func playLevels(_ sender: Any) {
        // Launch level gameplay
        print("Clicked levels button")
        Analytics.logEvent("play_levels_mode", parameters: /* None */ [:])
    }
    
    @IBAction func prepareForUnwind(segue: UIStoryboardSegue) {
        // Apparently this is necessary for unwinding views
        print("Preparing for unwind!")
        segue.source.dismiss(animated: true, completion: nil)
    }
    
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
    
    private func createButtonGradient(button: UIButton, color1: UIColor, color2: UIColor) -> CAGradientLayer {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = button.bounds
        gradientLayer.colors = [color1.cgColor, color2.cgColor]
        gradientLayer.cornerRadius = button.frame.height * 0.5
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0)
        gradientLayer.locations = [0.0, 1.0]
        return gradientLayer
    }
    
    private func adjustColor(color: Int, offset: Int, add: Bool) -> UIColor {
        /*
            Params:
                color - An int that is the RGB color as an Int
                offset - The offset int to subtract from the RGB int
        */
        
        var int1 = (color & 0xff0000) >> 16
        var int2 = (color & 0x00ff00) >> 8
        var int3 = color & 0x0000ff
        
        let off1 = (offset & 0xff0000) >> 16
        let off2 = (offset & 0x00ff00) >> 8
        let off3 = offset & 0x0000ff
        
        if add {
            int1 += off1
            int2 += off2
            int3 += off3
        }
        else {
            int1 -= off1
            int2 -= off2
            int3 -= off3
        }
        
        if int1 < 0 {
            int1 = 0
        }
        else if int1 > 0xff {
            int1 = 0xff
        }
        
        if int2 < 0 {
            int2 = 0
        }
        else if int2 > 0xff {
            int2 = 0xff
        }
        
        if int3 < 0 {
            int3 = 0
        }
        else if int3 > 0xff {
            int3 = 0xff
        }
        
        return UIColor(rgb: (int1 << 16) + (int2 << 8) + (int3))
    }
}
