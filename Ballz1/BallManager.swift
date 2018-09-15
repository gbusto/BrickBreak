//
//  BallManager.swift
//  Ballz1
//
//  Created by Gabriel Busto on 9/14/18.
//  Copyright © 2018 Self. All rights reserved.
//

import SpriteKit
import GameplayKit

class BallManager {
    
    // MARK: Private properties
    private var numberOfBalls : Int?
    private var ballArray : [Ball] = []
    private var activeBallArray : [Ball] = []
    
    private var firstBallReturned = false
    
    private var originPoint : CGPoint?
    
    
    // MARK: Public functions
    public func initBallManager(numBalls: Int, position: CGPoint, radius: CGFloat) {
        numberOfBalls = numBalls
        originPoint = position
        
        for i in 1...numBalls {
            let ball = Ball()
            ball.initBall(num: i, position: position, radius: radius)
            ballArray.append(ball)
        }
    }
    
    public func addBalls(scene: SKScene) {
        for ball in ballArray {
            scene.addChild(ball.node!)
        }
    }
    
    public func shootBalls(point: CGPoint) -> Bool {
        let ball = ballArray[activeBallArray.count]
        ball.fire(point: point)
        activeBallArray.append(ball)
        
        return activeBallArray.count < ballArray.count
    }
    
    public func markBallInactive(name: String) {
        for ball in ballArray {
            if ball.node!.name == name {
                ball.isActive = false
            }
        }
    }
    
    public func stopInactiveBalls() {
        if 0 == activeBallArray.count {
            firstBallReturned = false
            return
        }
        
        var indices : [Int] = []
        
        for i in 0...(activeBallArray.count - 1) {
            let ball = activeBallArray[i]
            if false == ball.isActive {
                ball.stop()
                indices.append(i)
                if false == firstBallReturned {
                    firstBallReturned = true
                    // Might need to change this; not sure if position updates depending on where it is
                    originPoint = ball.node!.position
                }
            }
        }
        
        for index in indices {
            activeBallArray.remove(at: index)
        }
    }
}
