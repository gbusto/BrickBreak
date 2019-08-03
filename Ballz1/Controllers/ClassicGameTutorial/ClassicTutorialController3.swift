//
//  ClassTutorialController.swift
//  Ballz1
//
//  Created by Gabriel Busto on 7/28/19.
//  Copyright © 2019 Self. All rights reserved.
//

import Foundation
import UIKit

class ClassicTutorialController3: UIViewController {
    
    @IBOutlet var backgroundGradientView: UIView!
    @IBOutlet var playButton: UIButton!
    
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
        
        let leftColor = UIColor(red: 36/255, green: 110/255, blue: 159/255, alpha: 1.0)
        let rightColor = UIColor(red: 52/255, green: 152/255, blue: 219/255, alpha: 1.0)
        let buttonGradientLayer = CAGradientLayer()
        buttonGradientLayer.colors = [leftColor.cgColor, rightColor.cgColor]
        buttonGradientLayer.transform = CATransform3DMakeRotation(CGFloat.pi / 2, 0, 0, 1)
        buttonGradientLayer.frame = playButton.bounds
        buttonGradientLayer.shouldRasterize = true
        playButton.layer.insertSublayer(buttonGradientLayer, at: 0)
    }
}

