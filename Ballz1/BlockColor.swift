//
//  BlockColor.swift
//  Ballz1
//
//  Created by Gabriel Busto on 9/17/18.
//  Copyright © 2018 Self. All rights reserved.
//

import SpriteKit
import GameplayKit

class BlockColor {
    
    private var red : CGFloat?
    private var green : CGFloat?
    private var blue : CGFloat?
    
    private var colorsToChange : [Int] = []
    private var RED = 0
    private var GREEN = 1
    private var BLUE = 2
    
    private var decrementAmount = CGFloat(0.01)
    
    public func initColor(red: CGFloat, green: CGFloat, blue: CGFloat) {
        self.red = red
        self.green = green
        self.blue = blue
        
        if red == 1 {
            colorsToChange.append(RED)
        }
        else if green == 1 {
            colorsToChange.append(GREEN)
        }
        else if blue == 1 {
            colorsToChange.append(BLUE)
        }
    }
    
    public func changeColor() -> UIColor {
        if colorsToChange.contains(RED) {
            red! -= decrementAmount
        }
        if colorsToChange.contains(GREEN) {
            green! -= decrementAmount
        }
        if colorsToChange.contains(BLUE) {
            blue! -= decrementAmount
        }
        
        return getColor()
    }
    
    public func getColor() -> UIColor {
        return UIColor.init(red: red!, green: green!, blue: blue!, alpha: 1)
    }
}
