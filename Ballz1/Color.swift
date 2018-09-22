//
//  Color.swift
//  Ballz1
//
//  Created by Gabriel Busto on 9/22/18.
//  Copyright © 2018 Self. All rights reserved.
//

import SpriteKit
import GameplayKit

class Color {
    
    // MARK: Private properties
    private var state = Int(4)
    private var GREEN_INC = Int(0)
    private var RED_DEC = Int(1)
    private var BLUE_INC = Int(2)
    private var GREEN_DEC = Int(3)
    private var RED_INC = Int(4)
    
    private var minValue = 50
    private var maxValue = 255
    
    private var red = 225
    private var green = 51
    private var blue = 51
    
    private var currentColor = UIColor.init(red: 255 / 255, green: 51 / 255, blue: 51 / 255, alpha: 1)
    
    
    // MARK: Public functions
    public func changeColor() -> UIColor {
        let diff = 32
        
        switch state {
        case GREEN_INC:
            print("GREEN_INC")
            green += diff
            break
        case RED_DEC:
            print("RED_DEC")
            red -= diff
            break
        case BLUE_INC:
            print("BLUE_INC")
            blue += diff
            break
        case GREEN_DEC:
            print("GREEN_DEC")
            green -= diff
            break
        case RED_INC:
            print("RED_INC")
            red += diff
            break
        default:
            print("Bad color state")
            break
        }
        
        if (green >= maxValue) && (GREEN_INC == state) {
            // Change from GREEN_INC to RED_DEC
            incrementState()
            green = maxValue
        }
        else if (red <= minValue) && (RED_DEC == state) {
            // Change from RED_DEC to BLUE_INC
            incrementState()
            red = minValue
        }
        else if (blue >= maxValue) && (BLUE_INC == state) {
            // BLUE_INC to GREEN_DEC
            incrementState()
            blue = maxValue
        }
        else if (green <= minValue) && (GREEN_DEC == state) {
            // GREEN_DEC to RED_INC
            incrementState()
            green = minValue
        }
        else if (red >= maxValue) && (RED_INC == state) {
            // RED_INC to GREEN_INC
            incrementState()
            red = maxValue
        }
        
        let r = CGFloat(red) / 255
        let g = CGFloat(green) / 255
        let b = CGFloat(blue) / 255
        print("r: \(r), g: \(g), b: \(b)")
        print("red: \(red), green: \(green), blue: \(blue)")
        
        return UIColor(red: r, green: g, blue: b, alpha: 1)
    }
    
    private func incrementState() {
        if RED_INC == state {
            state = GREEN_INC
            return
        }
        
        state += 1
    }
}
