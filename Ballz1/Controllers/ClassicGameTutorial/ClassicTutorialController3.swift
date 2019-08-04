//
//  ClassTutorialController.swift
//  Ballz1
//
//  Created by Gabriel Busto on 7/28/19.
//  Copyright © 2019 Self. All rights reserved.
//

import Foundation
import UIKit

/*
private extension UIButton {
    override open var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? UIColor(red: 51/255, green: 109/255, blue: 193/255, alpha: 1.0) : UIColor(red: 58/255, green: 124/255, blue: 220/255, alpha: 1.0)
        }
    }
}
 */

class ClassicTutorialController3: UIViewController {
    
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
    
    @IBAction func dismissClassicTutorial(_ sender: Any) {
        if let initialOnboardingState = DataManager.shared.loadInitialOnboardingState() {
            // Set the classic onboarding boolean to true, but leave the level one set to whatever it currently is
            if DataManager.shared.saveInitialOnboardingState(showedClassicOnboarding: true, showedLevelOnboarding: initialOnboardingState.showedLevelOnboarding) {
                print("Successfully saved initial classic onboarding state")
            }
            else {
                print("Failed to save initial classic onboarding state")
            }
        }
        else {
            // If this data has never been loaded, follow this path instead
            if DataManager.shared.saveInitialOnboardingState(showedClassicOnboarding: true, showedLevelOnboarding: false) {
                print("Successfully saved inital classic onboarding state")
            }
            else {
                print("Failed to save initial classic onboarding state")
            }
        }
        dismiss(animated: true, completion: nil)
    }
}

