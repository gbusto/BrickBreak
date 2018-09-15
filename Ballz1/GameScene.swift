//
//  GameScene.swift
//  Ballz1
//
//  Created by Gabriel Busto on 9/13/18.
//  Copyright © 2018 Self. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: Private attributes
    private var numberOfBalls = Int(10)
    private var margin : CGFloat?
    private var radius : CGFloat?
    
    private var groundNode : SKSpriteNode?
    private var ceilingNode : SKSpriteNode?
    private var leftWallNode : SKNode?
    private var rightWallNode : SKNode?
    
    private var ballManager : BallManager?
    
    private var currentState : Int?
    
    private var states : [Int] = []
    
    private var currentTouch : CGPoint?
    
    private var prevTime : TimeInterval?
    
    // Stuff for collisions
    private var categoryBitMask = UInt32(0b0001)
    private var contactTestBitMask = UInt32(0b0001)
    
    // MARK: State values
    private var READY = Int(0)
    private var SHOOT_BALLS = Int(1)
    private var WAIT_BALLS = Int(2)
    
    
    func didBegin(_ contact: SKPhysicsContact) {
        let nameA = contact.bodyA.node?.name!
        let nameB = contact.bodyB.node?.name!
        
        if (nameA?.starts(with: "ball"))! && nameB == "ground" {
            // Stop the ball at this exact point if it's the first ball to hit the ground
            print("\(nameA!) hit the ground")
            contact.bodyA.node!.physicsBody?.isResting = true
            //ballManager!.markBallInactive(name: nameA!)
        }
        
        if (nameB?.starts(with: "ball"))! && nameA == "ground" {
            // Stop the ball at this exact point if it's the first ball to hit the ground
            print("\(nameB!) hit the ground")
            contact.bodyB.node!.physicsBody?.isResting = true
            //ballManager!.markBallInactive(name: nameB!)
        }
    }
    
    // MARK: Override functions
    override func didMove(to view: SKView) {
        initState()
        initWalls(view: view)
        initBallManager(view: view, numBalls: numberOfBalls)
        
        physicsWorld.contactDelegate = self
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if currentState! == READY {
            if let touch = touches.first {
                currentTouch = touch.location(in: self)
                incrementState()
            }
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    // MARK: Scene update
    override func update(_ currentTime: TimeInterval) {
        if currentState! == SHOOT_BALLS {
            // This function returns false when all balls have been shot
            if false == ballManager?.shootBalls(point: currentTouch!) {
                incrementState()
            }
        }
        
        //ballManager!.stopInactiveBalls()
    }
    
    // MARK: Private functions
    private func initState() {
        currentState = READY
    }
    
    private func incrementState() {
        if currentState! == WAIT_BALLS {
            currentState! = READY
            return
        }
        
        currentState! += 1
    }
    
    private func initWalls(view: SKView) {
        margin = view.frame.height * 0.10
        
        initGround(view: view, margin: margin!)
        initCeiling(view: view, margin: margin!)
        initSideWalls(view: view, margin: margin!)
    }
    
    private func initGround(view: SKView, margin: CGFloat) {
        let size = CGSize(width: view.frame.width, height: margin)
        groundNode = SKSpriteNode(color: .darkGray, size: size)
        groundNode?.anchorPoint = CGPoint(x: 0, y: 0)
        groundNode?.position = CGPoint(x: 0, y: 0)
        groundNode?.name = "ground"
        
        let startPoint = CGPoint(x: 0, y: margin)
        let endPoint = CGPoint(x: view.frame.width, y: margin)
        let physBody = SKPhysicsBody(edgeFrom: startPoint, to: endPoint)
        physBody.usesPreciseCollisionDetection = true
        physBody.restitution = 0
        physBody.angularDamping = 1
        physBody.linearDamping = 1
        physBody.categoryBitMask = categoryBitMask
        physBody.contactTestBitMask = contactTestBitMask
        groundNode?.physicsBody = physBody
        
        self.addChild(groundNode!)
    }
    
    private func initCeiling(view: SKView, margin: CGFloat) {
        let size = CGSize(width: view.frame.width, height: margin)
        ceilingNode = SKSpriteNode(color: .darkGray, size: size)
        ceilingNode?.anchorPoint = CGPoint(x: 0, y: 0)
        ceilingNode?.position = CGPoint(x: 0, y: view.frame.height - margin)
        ceilingNode?.name = "ceiling"
        
        let startPoint = CGPoint(x: 0, y: 0)
        let endPoint = CGPoint(x: view.frame.width, y: 0)
        let physBody = SKPhysicsBody(edgeFrom: startPoint, to: endPoint)
        physBody.angularDamping = 0
        physBody.linearDamping = 0
        physBody.restitution = 1
        physBody.friction = 0
        physBody.categoryBitMask = categoryBitMask
        physBody.contactTestBitMask = contactTestBitMask
        ceilingNode?.physicsBody = physBody
        
        self.addChild(ceilingNode!)
    }
    
    private func initSideWalls(view: SKView, margin: CGFloat) {
        let lwStartPoint = CGPoint(x: 1, y: margin)
        let lwEndPoint = CGPoint(x: 1, y: view.frame.height - margin)
        let leftWallEdge = SKPhysicsBody(edgeFrom: lwStartPoint, to: lwEndPoint)
        leftWallEdge.angularDamping = 0
        leftWallEdge.linearDamping = 0
        leftWallEdge.restitution = 1
        leftWallEdge.friction = 0
        leftWallEdge.categoryBitMask = categoryBitMask
        leftWallEdge.contactTestBitMask = contactTestBitMask
        leftWallNode = SKNode()
        leftWallNode?.physicsBody = leftWallEdge
        leftWallNode?.name = "wall"
        
        let rwStartPoint = CGPoint(x: view.frame.width, y: margin)
        let rwEndPoint = CGPoint(x: view.frame.width, y: view.frame.height - margin)
        let rightWallEdge = SKPhysicsBody(edgeFrom: rwStartPoint, to: rwEndPoint)
        rightWallEdge.angularDamping = 0
        rightWallEdge.linearDamping = 0
        rightWallEdge.restitution = 1
        rightWallEdge.friction = 0
        rightWallEdge.categoryBitMask = categoryBitMask
        rightWallEdge.contactTestBitMask = contactTestBitMask
        rightWallNode = SKNode()
        rightWallNode?.physicsBody = rightWallEdge
        rightWallNode?.name = "wall"
        
        self.addChild(leftWallNode!)
        self.addChild(rightWallNode!)
    }
    
    private func initBallManager(view: SKView, numBalls: Int) {
        radius = CGFloat(view.frame.width * 0.015)
        ballManager = BallManager()
        let position = CGPoint(x: view.frame.midX, y: margin! + radius!)
        ballManager!.initBallManager(numBalls: numBalls, position: position, radius: radius!)
        ballManager!.addBalls(scene: self)
    }
}
