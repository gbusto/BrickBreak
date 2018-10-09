//
//  BallProjection.swift
//  Ballz1
//
//  Created by hemingway on 10/8/18.
//  Copyright © 2018 Self. All rights reserved.
//

import SpriteKit

class BallProjection {
    
    // MARK: Properties
    public var arrowNode = SKShapeNode()
    
    public var arrowShowing = false
    
    private func calcSlope(originPoint: CGPoint, touchPoint: CGPoint) -> CGFloat {
        let rise = touchPoint.y - originPoint.y
        let run  = touchPoint.x - originPoint.x
        
        return CGFloat(rise / run)
    }
    
    private func calcYIntercept(point: CGPoint, slope: CGFloat) -> CGFloat {
        // y = mx + b <- We want to find 'b'
        // (point.y - (point.x * slope)) = b
        let intercept = point.y - (point.x * slope)
        
        return intercept
    }
    
    // Updates where the ball path projection is pointing
    public func updateArrow(startPoint: CGPoint, touchPoint: CGPoint) {
        let maxOffset = CGFloat(200)
        
        let slope = calcSlope(originPoint: startPoint, touchPoint: touchPoint)
        let intercept = calcYIntercept(point: touchPoint, slope: slope)
        
        var newX = CGFloat(0)
        var newY = CGFloat(0)
        
        if (slope >= 1) || (slope <= -1) {
            newY = touchPoint.y + maxOffset
            newX = (newY - intercept) / slope
        }
        else if (slope < 1) && (slope > -1) {
            if (slope < 0) {
                newX = touchPoint.x - maxOffset
            }
            else if (slope > 0) {
                newX = touchPoint.x + maxOffset
            }
            newY = (slope * newX) + intercept
        }
        
        let endPoint = CGPoint(x: newX, y: newY)
        
        let pattern: [CGFloat] = [10, 10]
        let path = CGMutablePath()
        path.move(to: startPoint)
        path.addLine(to: endPoint)
        let dashedPath = path.copy(dashingWithPhase: 0, lengths: pattern)
        
        let color = UIColor(red: 119/255, green: 136/255, blue: 153/255, alpha: 1)
        arrowNode.path = dashedPath
        arrowNode.strokeColor = color
        arrowNode.lineWidth = 4
    }
    
    // Shows the ball path projection
    public func showArrow(scene: SKScene) {
        if false == arrowShowing {
            scene.addChild(arrowNode)
            arrowShowing = true
        }
    }
    
    // Hides the ball path projection (after the user shoots the balls or moves their finger out of game play)
    public func hideArrow(scene: SKScene) {
        if arrowShowing {
            scene.removeChildren(in: [arrowNode])
            arrowShowing = false
        }
    }
}
