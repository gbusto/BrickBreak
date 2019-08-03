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
        
        print("ClassicTutorialController3 view loaded!")
        
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
        if let touches = event.touches(for: playButton) {
            if let touch = touches.first {
                if touch.phase == .began {
                    // The button has been pressed
                    playButton.backgroundColor = pressedButtonColor
                }
                else if touch.phase == .ended {
                    // The button has been depressed
                    playButton.backgroundColor = buttonColor
                }
            }
        }
    }
}

