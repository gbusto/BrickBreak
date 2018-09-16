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
    private var numberOfBlocks = Int(10)
    private var numberOfBalls = Int(10)
    private var margin : CGFloat?
    private var radius : CGFloat?
    
    private var groundNode : SKSpriteNode?
    private var ceilingNode : SKSpriteNode?
    private var leftWallNode : SKNode?
    private var rightWallNode : SKNode?
    
    private var ballManager : BallManager?
    
    private var blockGenerator : BlockGenerator?
    
    private var currentTouch : CGPoint?
    
    private var prevTime : TimeInterval?
    
    private var turnOver = true
    
    // Stuff for collisions
    private var categoryBitMask = UInt32(0b0001)
    private var contactTestBitMask = UInt32(0b0001)
    
    
    func didBegin(_ contact: SKPhysicsContact) {
        let nameA = contact.bodyA.node?.name!
        let nameB = contact.bodyB.node?.name!
        
        if (nameA?.starts(with: "ball"))! {
            if nameB! == "ground" {
                // Stop the ball at this exact point if it's the first ball to hit the ground
                ballManager!.markBallInactive(name: nameA!)
            }
            else if (nameB?.starts(with: "block"))! {
                // A block was hit
                blockGenerator!.hit(name: nameB!)
            }
        }
        
        if (nameB?.starts(with: "ball"))! {
            if nameA! == "ground" {
                // Stop the ball at this exact point if it's the first ball to hit the ground
                ballManager!.markBallInactive(name: nameB!)
            }
            else if (nameA?.starts(with: "block"))! {
                // A block was hit
                blockGenerator!.hit(name: nameA!)
            }
        }
    }
    
    // MARK: Override functions
    override func didMove(to view: SKView) {
        initWalls(view: view)
        initBallManager(view: view, numBalls: numberOfBalls)
        initBlockGenerator(view: view)
        
        physicsWorld.contactDelegate = self
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if ballManager!.isReady() && blockGenerator!.isReady() {
            if let touch = touches.first {
                let direction = touch.location(in: self)
                ballManager!.setDirection(point: direction)
                ballManager!.incrementState()
            }
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    // MARK: Scene update
    override func update(_ currentTime: TimeInterval) {
        if turnOver {
            addRow()
            turnOver = false
        }
        
        if ballManager!.isShooting() {
            ballManager!.shootBall()
        }
        
        if ballManager!.isWaiting() {
            ballManager!.stopInactiveBalls()
        }
        
        if ballManager!.isDone() {
            turnOver = true
            ballManager!.incrementState()
        }
        
        blockGenerator?.removeBlocks(scene: self)
    }
    
    // MARK: Private functions
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
        ceilingNode?.zPosition = 101
        
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
    
    private func initBlockGenerator(view: SKView) {
        blockGenerator = BlockGenerator()
        blockGenerator?.initBlockGenerator(view: view, numBalls: numberOfBalls, numBlocks: numberOfBlocks,
                                           ceiling: view.frame.height - margin!, ground: margin!)
    }
    
    private func addRow() {
        blockGenerator!.generateRow(scene: self)
    }
}
