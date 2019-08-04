//
//  ClassicTutorialController1.swift
//  Ballz1
//
//  Created by Gabriel Busto on 7/28/19.
//  Copyright © 2019 Self. All rights reserved.
//

import Foundation
import UIKit

class ClassicTutorialController1: UIViewController {
    
    @IBOutlet var backgroundGradientView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        let bottomColor = UIColor(red: 30/255, green: 30/255, blue: 30/255, alpha: 1.0)
        let topColor = UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1.0)
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [topColor.cgColor, bottomColor.cgColor]
        gradientLayer.shouldRasterize = true
        backgroundGradientView.layer.insertSublayer(gradientLayer, at: 0)
    }
}
