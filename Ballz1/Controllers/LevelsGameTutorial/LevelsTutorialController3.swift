//
//  LevelsTutorialController3.swift
//  Ballz1
//
//  Created by Gabriel Busto on 8/3/19.
//  Copyright © 2019 Self. All rights reserved.
//

import Foundation
import UIKit

class LevelsTutorialController3: UIViewController {
    
    @IBOutlet var backgroundGradientView: UIView!
    @IBOutlet var playButton: UIButton!
    
    private var buttonColor = UIColor(red: 22/255, green: 110/255, blue: 238/255, alpha: 1.0)
    private var pressedButtonColor = UIColor(red: 17/255, green: 94/255, blue: 205/255, alpha: 1.0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let bottomColor = UIColor(red: 30/255, green: 30/255, blue: 30/255, alpha: 1.0)
        let topColor = UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1.0)
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [topColor.cgColor, bottomColor.cgColor]
        gradientLayer.shouldRasterize = true
        backgroundGradientView.layer.insertSublayer(gradientLayer, at: 0)
        
        playButton.layer.cornerRadius = 10
        playButton.backgroundColor = buttonColor
        playButton.addTarget(self, action: #selector(buttonTouchEvent), for: .allEvents)
    }
    
    @IBAction private func buttonTouchEvent(sender: Any?, forEvent event: UIEvent) {
        // This is the only way I found to get the button background color to change on press; the events and states aren't enough
        // Get all touch associated with the play button
        if let touches = event.touches(for: playButton) {
            // There should only be one, so attempt to get the only touch event
            if let touch = touches.first {
                // Check for the touch began phase
                if touch.phase == .began {
                    // The button has been pressed
                    playButton.backgroundColor = pressedButtonColor
                }
                    // Check for the touch ended phase
                else if touch.phase == .ended {
                    // The button has been depressed
                    playButton.backgroundColor = buttonColor
                }
            }
        }
    }
    
    @IBAction func dismissLevelsTutorial(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
}

