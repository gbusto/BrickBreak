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
    
    // Not sure how this works exactly... copied from the internet
    convenience init(radialGradientWithColors colors: [UIColor], locations: [CGFloat], size: CGSize) {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { (context) in
            let colorSpace = context.cgContext.colorSpace ?? CGColorSpaceCreateDeviceRGB()
            let cgColors = colors.map({ $0.cgColor }) as CFArray
            guard let gradient = CGGradient(colorsSpace: colorSpace, colors: cgColors, locations: UnsafePointer<CGFloat>(locations)) else {
                fatalError("Failed creating gradient.")
            }
            
            let radius = max(size.width, size.height) / 2.0
            let midPoint = CGPoint(x: size.width / 2.0, y: size.height / 2.0)
            context.cgContext.drawRadialGradient(gradient, startCenter: midPoint, startRadius: 0, endCenter: midPoint, endRadius: radius, options: [])
        }
        
        self.init(image: image)
    }
}

// MARK: Light theme struct
class GameMenuColorScheme {
    // MARK: Properties
    var backgroundColor: SKColor
    var textColor: SKColor
    var fontName: String = "Menlo-Regular"
    
    required init() {
        backgroundColor = SKColor(red: 24/255, green: 26/255, blue: 25/255, alpha: 1)
        textColor = SKColor(red: 93/255, green: 173/255, blue: 226/255, alpha: 1)
    }
}

class GameSceneColorScheme {
    // MARK: Properties
    var backgroundColor: SKColor
    var backgroundTexture: SKTexture
    var blockTextColor: SKColor
    var textColor: SKColor
    var hitBallColor: SKColor
    var stoneTexture: SKTexture
    var blockTexture: SKTexture
    var dividingLine: SKTexture
    var fontName: String = "Menlo-Regular"
    
    required init(backgroundSize: CGSize, blockSize: CGSize) {
        var bottomColor = SKColor(red: 187/255, green: 143/255, blue: 206/255, alpha: 1)
        var topColor = SKColor(red: 165/255, green: 105/255, blue: 189/255, alpha: 1)
        let coloredTexture = SKTexture(size: blockSize, startColor: topColor, endColor: bottomColor, direction: .up)
        backgroundColor = SKColor(red: 24/255, green: 26/255, blue: 25/255, alpha: 1)
        blockTextColor = backgroundColor
        textColor = SKColor(red: 117/255, green: 206/255, blue: 235/255, alpha: 1)
        hitBallColor = SKColor(red: 247/255, green: 220/255, blue: 111/255, alpha: 1)
        blockTexture = coloredTexture
        dividingLine = SKTexture()
        
        bottomColor = SKColor(red: 192/255, green: 192/255, blue: 192/255, alpha: 1)
        topColor = SKColor(red: 169/255, green: 169/255, blue: 169/255, alpha: 1)
        stoneTexture = SKTexture(size: blockSize, startColor: topColor, endColor: bottomColor, direction: .up)
        
        bottomColor = SKColor(red: 95/255, green: 150/255, blue: 142/255, alpha: 1)
        topColor = SKColor(red: 191/255, green: 220/255, blue: 207/255, alpha: 1)
        backgroundTexture = SKTexture(size: backgroundSize, startColor: topColor, endColor: bottomColor, direction: .upLeft)
    }
}
