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
    
    private var numBallsFired : Int?
    
    private var firstBallReturned = false
    
    private var originPoint : CGPoint?
    
    
    // MARK: Public functions
    public func initBallManager(numBalls: Int, position: CGPoint, radius: CGFloat) {
        numberOfBalls = numBalls
        numBallsFired = 0
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
        let ball = ballArray[numBallsFired!]
        ball.fire(point: point)
        numBallsFired! += 1
        
        return numBallsFired! < numberOfBalls!
    }
    
    public func stop(name: String) {
        for ball in ballArray {
            if ball.node!.name == name {
                ball.stop()
                if false == firstBallReturned {
                    firstBallReturned = true
                    originPoint = ball.node!.position
                    return
                }
                else {
                    ball.returnToOrigin(point: originPoint!)
                    return
                }
            }
        }
        
        for ball in ballArray {
            if ball.isActive {
                return
            }
        }
        
        firstBallReturned = false
    }
}
