//
//  Confetti.swift
//  Ballz1
//
//  Created by Gabriel Busto on 2/9/19.
//  Copyright © 2019 Self. All rights reserved.
//

import UIKit

class Confetti {
    
    private var view: UIView?
    
    private var frame: CGRect!
    
    private var numCells = 16
    
    private var colors: [UIColor] = [
        UIColor(rgb: 0xff6666),
        UIColor(rgb: 0xffb266),
        UIColor(rgb: 0xffff66),
        UIColor(rgb: 0x66ffb2),
        UIColor(rgb: 0x66b2ff),
        UIColor(rgb: 0x6666ff),
        UIColor(rgb: 0xb266ff),
        UIColor(rgb: 0xff66b2)
    ]
    
    private var shapes: [CGImage] = [
        UIImage(named: "circle_confetti.png")!.cgImage!,
        UIImage(named: "curved_confetti.png")!.cgImage!,
        UIImage(named: "square_confetti.png")!.cgImage!,
        UIImage(named: "swirl_confetti.png")!.cgImage!,
    ]
    
    public func getEmitter(frame: CGRect) -> CAEmitterLayer {
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: frame.width / 2, y: -10)
        emitter.emitterSize = CGSize(width: frame.width, height: 2.0)
        emitter.emitterShape = CAEmitterLayerEmitterShape.line
        emitter.emitterCells = generateEmitterCells()
        return emitter
    }
    
    private func generateEmitterCells() -> [CAEmitterCell] {
        var cells: [CAEmitterCell] = []
        for _ in 1...numCells {
            let cell = CAEmitterCell()
            // The number of objects emitted every second
            cell.birthRate = 4.0
            // How long each particle lasts before being removed
            cell.lifetime = 10
            // The mean value by which lifetime can range
            cell.lifetimeRange = 2
            // The velocity of each particle
            cell.velocity = CGFloat.random(in: 120...200)
            // The mean value by which the velocity can range
            cell.velocityRange = CGFloat(10)
            // The longitudinal orientation of the emission angle
            cell.emissionLongitude = CGFloat(Double.pi)
            // The mean value by which the emission angle can range
            cell.emissionRange = 0.5
            // Rotational velocity measured in radians per second
            cell.spin = 3.5
            // Possible spin range + or -
            cell.spinRange = 1
            // Set the color
            cell.color = colors.randomElement()!.cgColor
            // Contents of the cell
            cell.contents = shapes.randomElement()
            // Scale based on the png in assets
            cell.scale = 0.2
            // Possible scale range value
            cell.scaleRange = 0.05
            // Append the cell to the list
            cells.append(cell)
        }
        return cells
    }
}
