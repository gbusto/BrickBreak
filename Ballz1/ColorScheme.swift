//
//  ColorScheme.swift
//  Ballz1
//
//  Created by Gabriel Busto on 11/3/18.
//  Copyright © 2018 Self. All rights reserved.
//

import Foundation
import SpriteKit

extension SKTexture {
    
    enum GradientDirection {
        case up
        case left
        case upLeft
        case upRight
    }
    
    convenience init(size: CGSize, startColor: SKColor, endColor: SKColor, direction: GradientDirection = .up) {
        let context = CIContext(options: nil)
        let filter = CIFilter(name: "CILinearGradient")
        let startVector: CIVector
        let endVector: CIVector
        
        filter?.setDefaults()
        
        switch direction {
        case .up:
            startVector = CIVector(x: size.width / 2, y: 0)
            endVector = CIVector(x: size.width / 2, y: size.height)
        case .left:
            startVector = CIVector(x: size.width, y: size.height / 2)
            endVector = CIVector(x: 0, y: size.height / 2)
        case .upLeft:
            startVector = CIVector(x: size.width, y: 0)
            endVector = CIVector(x: 0, y: size.height)
        case .upRight:
            startVector = CIVector(x: 0, y: 0)
            endVector = CIVector(x: size.width, y: size.height)
        }
        
        filter!.setValue(startVector, forKey: "inputPoint0")
        filter!.setValue(endVector, forKey: "inputPoint1")
        filter!.setValue(CIColor(color: startColor), forKey: "inputColor0")
        filter!.setValue(CIColor(color: endColor), forKey: "inputColor1")
        
        let image = context.createCGImage(filter!.outputImage!, from: CGRect(origin: .zero, size: size))
        
        self.init(cgImage: image!)
    }
}

protocol ColorScheme {
    var backgroundTexture: SKTexture { get set }
    var blockTexture: SKTexture { get set }
}

// MARK: Light theme struct
class LightTheme: ColorScheme {
    // MARK: Protocol properties
    var backgroundTexture: SKTexture
    var blockTexture: SKTexture
    
    // MARK: Theme colors
    // For the background
    let darkerBlue = SKColor(red: 5/255, green: 15/255, blue: 55/255, alpha: 1)
    let lighterBlue = SKColor(red: 15/255, green: 25/255, blue: 65/255, alpha: 1)
    
    // For the blocks
    let darkerPink = SKColor(red: 140/255, green: 40/255, blue: 140/255, alpha: 1)
    let lighterPink = SKColor(red: 210/255, green: 100/255, blue: 210/255, alpha: 1)
    
    required init(backgroundSize: CGSize, blockSize: CGSize) {
        backgroundTexture = SKTexture(size: backgroundSize, startColor: lighterBlue, endColor: darkerBlue, direction: .up)
        blockTexture = SKTexture(size: blockSize, startColor: lighterPink, endColor: darkerPink, direction: .upRight)
    }
}
