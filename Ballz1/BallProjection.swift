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
    public func updateArrow(startPoint: CGPoint, touchPoint: CGPoint, ceilingHeight: CGFloat, groundHeight: CGFloat) -> CGPoint {
        let maxOffset = CGFloat(400)
        var newTouchPoint = touchPoint
        
        // This correction is here to fix a bug:
        // When the touch point's Y value goes below the start point's Y value, the slope changes sign (- to + or + to -) which causes it to "jump" around a bit as the user's finger gets closer to the ground. The reason is because - assuming your finger is to the left of the origin point - the slope is negative. When it gets closer to the ground, the touch point Y value drops below that of the origin point's Y value and so even though the finger is on the left side and the slope should be negative, it switches to positive and draws a projection path to the RIGHT of the ball instead of the left. It seems like it's jumping around and might cause the user to fire in the wrong direction by accident.
        if newTouchPoint.y <= startPoint.y {
            newTouchPoint.y = startPoint.y + 0.1
        }
        
        var slope = calcSlope(originPoint: startPoint, touchPoint: newTouchPoint)
        let intercept = calcYIntercept(point: newTouchPoint, slope: slope)
        
        var newX = CGFloat(0)
        var newY = CGFloat(0)
        
        if (slope >= 1) || (slope <= -1) {
            newY = newTouchPoint.y + maxOffset
            newX = (newY - intercept) / slope
        }
        else if (slope < 1) && (slope > -1) {
            if (slope < 0) {
                newX = newTouchPoint.x - maxOffset
            }
            else if (slope > 0) {
                newX = newTouchPoint.x + maxOffset
            }
            newY = (slope * newX) + intercept
        }
        
        if newY > ceilingHeight {
            newY = ceilingHeight
        }
        else if newY < groundHeight + 50 {
            newY = groundHeight + 50
            newTouchPoint = CGPoint(x: newX, y: newY)
            slope = calcSlope(originPoint: startPoint, touchPoint: newTouchPoint)
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
        
        return newTouchPoint
    }
    
    // Shows the ball path projection
    public func showArrow(scene: SKScene) {
        if false == arrowShowing {
            arrowNode.zPosition = 0
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
