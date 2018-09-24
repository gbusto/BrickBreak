//
//  GameScene.swift
//  Ballz1
//
//  Created by Gabriel Busto on 9/13/18.
//  Copyright © 2018 Self. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: Private attributes
    private var numberOfItems = Int(8)
    private var numberOfBalls = Int(10)
    private var margin : CGFloat?
    private var radius : CGFloat?
    
    private var groundNode : SKSpriteNode?
    private var ceilingNode : SKSpriteNode?
    private var leftWallNode : SKNode?
    private var rightWallNode : SKNode?
    
    private var scoreLabel : SKLabelNode?
    private var gameScore = Int(0)
    
    private var ballManager : BallManager?
    private var itemGenerator : ItemGenerator?
    private var arrowNode : SKShapeNode?
    
    private var currentTouch : CGPoint?
        
    private var turnOver = true
    private var arrowIsShowing = false
    
    private var numTicksGap = 6
    private var numTicks = 0
    
    private var rightSwipeGesture : UISwipeGestureRecognizer?
    private var addedGesture = false

    private var sceneColor = UIColor.init(red: 20/255, green: 20/255, blue: 20/255, alpha: 1)
    private var marginColor = UIColor.init(red: 50/255, green: 50/255, blue: 50/255, alpha: 1)
    
    // Stuff for collisions
    private var categoryBitMask = UInt32(0b0001)
    private var contactTestBitMask = UInt32(0b0001)
    private var groundCategoryBitmask = UInt32(0b0101)
    
    
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
                itemGenerator!.hit(name: nameB!)
            }
            else if (nameB?.starts(with: "ball"))! {
                // A ball hit a ball item
                itemGenerator!.hit(name: nameB!)
            }
        }
        
        if (nameB?.starts(with: "ball"))! {
            if nameA! == "ground" {
                // Stop the ball at this exact point if it's the first ball to hit the ground
                ballManager!.markBallInactive(name: nameB!)
            }
            else if (nameA?.starts(with: "block"))! {
                // A block was hit
                itemGenerator!.hit(name: nameA!)
            }
            else if (nameA?.starts(with: "ball"))! {
                itemGenerator!.hit(name: nameA!)
            }
        }
    }
    
    // MARK: Override functions
    override func didMove(to view: SKView) {
        initWalls(view: view)
        initItemGenerator(view: view)
        initBallManager(view: view, numBalls: numberOfBalls)
        initArrowNode(view: view)
        initScoreLabel()
        
        rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeRight(_:)))
        rightSwipeGesture!.direction = .right
        rightSwipeGesture!.numberOfTouchesRequired = 1
        
        physicsWorld.contactDelegate = self
        self.backgroundColor = sceneColor
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let point = touch.location(in: self)
            if ballManager!.isReady() && itemGenerator!.isReady() {
                // Check to see if the touch is in the game area
                if inGame(point: point) {
                    let originPoint = ballManager!.getOriginPoint()
                    if false == arrowIsShowing {
                        showArrow()
                        arrowIsShowing = true
                    }
                    updateArrow(startPoint: originPoint, touchPoint: point)
                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            if ballManager!.isReady() && itemGenerator!.isReady() && arrowIsShowing {
                let point = touch.location(in: self)
                let originPoint = ballManager!.getOriginPoint()
                updateArrow(startPoint: originPoint, touchPoint: point)
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let point = touch.location(in: self)
            if ballManager!.isReady() && itemGenerator!.isReady() && arrowIsShowing {
                ballManager!.setDirection(point: point)
                ballManager!.incrementState()
            }
        }
        
        hideArrow()
        arrowIsShowing = false
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    // MARK: Scene update
    override func update(_ currentTime: TimeInterval) {
        if turnOver {
            // Return physics simulation back to normal speed
            if 2.0 == self.physicsWorld.speed {
                self.physicsWorld.speed = 1.0
            }
            if 3 == numTicksGap {
                numTicksGap = 6
            }
            
            // Clear the gesture recognizers for now
            view!.gestureRecognizers = []
            addedGesture = false
            
            // Generate a row
            itemGenerator!.generateRow(scene: self)
            // In the event that we just collected a ball, it will not be at the origin point so move all balls to the origin point
            ballManager!.checkNewArray()
            updateScore()
            turnOver = false
        }
        
        // After rows have been added, check to see if we can add any more rows
        if itemGenerator!.isReady() {
            if false == itemGenerator!.canAddRow(groundHeight: margin!) {
                // Game over!!!
                self.isPaused = true
                showGameOverLabel()
            }
        }
        
        if ballManager!.isShooting() {
            if numTicks >= numTicksGap {
                ballManager!.shootBall()
                numTicks = 0
            }
            else {
                numTicks += 1
            }
        }
        
        if ballManager!.isShooting() || ballManager!.isWaiting() {
            if (false == addedGesture) {
                view!.gestureRecognizers = [rightSwipeGesture!]
                addedGesture = true
            }
            ballManager!.stopInactiveBalls()
        }
        
        if ballManager!.isDone() {
            turnOver = true
            ballManager!.incrementState()
        }
        
        let removedItems = itemGenerator!.removeItems(scene: self)
        
        // If the item generator removed an item from it's list, check to see if it removed a ball; if it does, it now needs to be moved under the BallManager
        for item in removedItems {
            if item.getNode().name!.starts(with: "ball") {
                let ball = item as! BallItem
                let newPoint = CGPoint(x: ball.getNode().position.x, y: margin! + radius!)
                ballManager!.addBall(ball: ball, atPoint: newPoint)
                print("Added ball \(ball.getNode().name!) to ball manager")
            }
        }
    }
    
    // MARK: Public functions
    // Handle right swipes
    @objc public func handleSwipeRight(_ sender: UISwipeGestureRecognizer) {
        let point = sender.location(in: view!)
        if inGame(point: point) {
            if ballManager!.isShooting() || ballManager!.isWaiting() {
                print("Speeding up physics simulation")
                physicsWorld.speed = 2.0
                numTicksGap = 3
                flashSpeedupImage()
            }
        }
    }
    
    // MARK: Private functions
    private func inGame(point: CGPoint) -> Bool {
        return ((point.y < ceilingNode!.position.y) && (point.y > groundNode!.size.height))
    }
    
    private func initWalls(view: SKView) {
        margin = view.frame.height * 0.10
        
        initGround(view: view, margin: margin!)
        initCeiling(view: view, margin: margin!)
        initSideWalls(view: view, margin: margin!)
    }
    
    private func initGround(view: SKView, margin: CGFloat) {
        let size = CGSize(width: view.frame.width, height: margin)
        groundNode = SKSpriteNode(color: marginColor, size: size)
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
        physBody.categoryBitMask = groundCategoryBitmask
        physBody.contactTestBitMask = contactTestBitMask
        groundNode?.physicsBody = physBody
        
        self.addChild(groundNode!)
    }
    
    private func initCeiling(view: SKView, margin: CGFloat) {
        let size = CGSize(width: view.frame.width, height: margin)
        ceilingNode = SKSpriteNode(color: marginColor, size: size)
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
    
    private func initItemGenerator(view: SKView) {
        itemGenerator = ItemGenerator()
        itemGenerator?.initGenerator(view: view, numBalls: numberOfBalls, numItems: numberOfItems, ceiling: view.frame.height - margin!, ground: margin!)
    }
    
    private func initBallManager(view: SKView, numBalls: Int) {
        radius = CGFloat(view.frame.width * 0.018)
        ballManager = BallManager()
        let position = CGPoint(x: view.frame.midX, y: margin! + radius!)
        ballManager!.initBallManager(scene: self, generator: itemGenerator!, numBalls: numBalls, position: position, radius: radius!)
        ballManager!.addBalls()
    }
    
    private func initArrowNode(view: SKView) {
        arrowNode = SKShapeNode()
    }
    
    private func updateArrow(startPoint: CGPoint, touchPoint: CGPoint) {
        // The "box" we create around the origin point
        let maxX = startPoint.x + view!.frame.width * 0.75
        let maxY = startPoint.y + view!.frame.width * 0.75
        let minX = startPoint.x - view!.frame.width * 0.75
        
        let slope = calcSlope(originPoint: startPoint, touchPoint: touchPoint)
        let intercept = calcYIntercept(point: touchPoint, slope: slope)
        
        var newX = CGFloat(0)
        var newY = CGFloat(0)
        
        if (slope >= 1) || (slope <= -1) {
            newY = maxY
            newX = (newY - intercept) / slope
        }
        else if (slope < 1) && (slope > -1) {
            if (slope < 0) {
                newX = minX
            }
            else if (slope > 0) {
                newX = maxX
            }
            newY = (slope * newX) + intercept
        }
        
        let endPoint = CGPoint(x: newX, y: newY)
        
        let path = CGMutablePath()
        path.move(to: startPoint)
        path.addLine(to: endPoint)
        
        arrowNode!.path = path
        arrowNode!.strokeColor = .white
        arrowNode!.lineWidth = 2
    }
    
    private func showArrow() {
        self.addChild(arrowNode!)
    }
    
    private func hideArrow() {
        self.removeChildren(in: [arrowNode!])
    }
    
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
    
    private func showGameOverLabel() {
        let fontSize = view!.frame.height * 0.2
        let label = SKLabelNode()
        label.position = CGPoint(x: view!.frame.midX, y: view!.frame.midY - fontSize)
        label.fontSize = fontSize
        label.color = .white
        label.text = "Game Over"
        label.numberOfLines = 2
        label.zPosition = 102
        label.preferredMaxLayoutWidth = view!.frame.width
        self.addChild(label)
    }
    
    private func initScoreLabel() {
        let pos = CGPoint(x: view!.frame.midX, y: ceilingNode!.position.y + (margin! / 3))
        scoreLabel = SKLabelNode()
        scoreLabel!.zPosition = 103
        scoreLabel!.position = pos
        scoreLabel!.fontSize = margin! * 0.50
        scoreLabel!.text = "0"
        self.addChild(scoreLabel!)
    }
    
    private func updateScore() {
        gameScore += 1
        scoreLabel!.text = "\(gameScore)"
    }
    
    private func flashSpeedupImage() {
        let pos = CGPoint(x: self.view!.frame.midX, y: self.view!.frame.midY)
        let size = CGSize(width: self.view!.frame.width * 0.8, height: self.view!.frame.width * 0.8)
        let imageNode = SKSpriteNode(imageNamed: "fast_forward.png")
        imageNode.alpha = 0
        imageNode.position = pos
        imageNode.size = size
        self.addChild(imageNode)
        
        let action1 = SKAction.fadeAlpha(to: 0.5, duration: 0.2)
        let action2 = SKAction.fadeAlpha(to: 0, duration: 0.2)
        
        imageNode.run(SKAction.sequence([action1, action2, action1, action2, action1, action2])) {
            self.removeChildren(in: [imageNode])
        }
    }
}
