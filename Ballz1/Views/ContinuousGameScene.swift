//
//  ContinuousGameView.swift
//  Ballz1
//
//  This file handles the display for continous game mode
//
//  Created by Gabriel Busto on 10/6/18.
//  Copyright © 2018 Self. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit
import CoreGraphics

class ContinousGameScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: Private properties
    private var margin : CGFloat?
    private var radius : CGFloat?
    
    // Nodes that will be shown in the view
    private var groundNode : SKSpriteNode?
    private var ceilingNode : SKSpriteNode?
    private var leftWallNode : SKNode?
    private var rightWallNode : SKNode?
    private var arrowNode : SKShapeNode?
    
    // The game model
    private var gameModel: ContinuousGameModel?
    
    private var fontName = "KohinoorBangla-Regular"

    // Score labels
    private var scoreLabel : SKLabelNode?
    private var bestScoreLabel : SKLabelNode?
    
    // A counter for each time update is called
    private var numTicks = Int(0)
    // The number of update ticks to wait before shooting another ball
    private var ticksDelay = Int(6)
    
    // Variables for handling swipe gestures
    private var rightSwipeGesture : UISwipeGestureRecognizer?
    private var addedGesture = false
    
    private var arrowIsShowing = false
    
    // Colors for the scene
    private var sceneColor = UIColor.init(red: 20/255, green: 20/255, blue: 20/255, alpha: 1)
    private var marginColor = UIColor.init(red: 50/255, green: 50/255, blue: 50/255, alpha: 1)
    
    // Stuff for collisions
    private var categoryBitMask = UInt32(0b0001)
    private var contactTestBitMask = UInt32(0b0001)
    private var groundCategoryBitmask = UInt32(0b0101)
    
    
    // MARK: Override functions
    override func didMove(to view: SKView) {
        initWalls(view: view)
        initArrowNode()
        initGameModel()
        initScoreLabel()
        initBestScoreLabel()
        
        rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeRight(_:)))
        rightSwipeGesture!.direction = .right
        rightSwipeGesture!.numberOfTouchesRequired = 1
        
        self.backgroundColor = sceneColor
        physicsWorld.contactDelegate = self
    }
    
    // MVC: A view function; notifies the controller of contact between two bodies
    func didBegin(_ contact: SKPhysicsContact) {
        let nameA = contact.bodyA.node?.name!
        let nameB = contact.bodyB.node?.name!
        
        gameModel!.handleContact(nameA: nameA!, nameB: nameB!)
    }
    
    // MVC: View detects the touch; the code in this function should notify the GameSceneController to handle this event
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let point = touch.location(in: self)
         
            if gameModel!.isReady() {
                // Show the arrow and update it
                if inGame(point) {
                    showArrow()
                    updateArrow(startPoint: gameModel!.ballManager!.getOriginPoint(), touchPoint: point)
                }
            }
        }
    }
    
    // MVC: View detects the touch; the code in this function should notify the GameSceneController to handle this event
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let point = touch.location(in: self)
            
            if !inGame(point) {
                // Hide the arrow
                hideArrow()
            }
            else if gameModel!.isReady() && arrowIsShowing {
                // Update the arrow location
                updateArrow(startPoint: gameModel!.ballManager!.getOriginPoint(), touchPoint: point)
            }
        }
    }
    
    // MVC: View detects the touch; the code in this function should notify the GameSceneController to handle this event
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let point = touch.location(in: self)
            
            if gameModel!.isReady() && arrowIsShowing {
                // Set the direction for the balls to shoot
                gameModel!.prepareTurn(point: point)
                print("Prepped game model to start a turn")
            }
        }
        
        // Hide the arrow
        hideArrow()
    }
    
    // MVC: View detects the touch; the code in this function should notify the GameSceneController to handle this event
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    // MARK: Scene update
    override func update(_ currentTime: TimeInterval) {
        if gameModel!.isTurnOver() {
            print("Turn over")
            
            // Return physics simulation to normal speed
            physicsWorld.speed = 1.0
            
            // Reset the tick delay for firing balls
            ticksDelay = 6
            
            // Clear gesture recognizers in the view
            view!.gestureRecognizers = []
            addedGesture = false
            
            // Tell the game model to update now that the turn has ended
            // Returns false if the game is over
            if false == gameModel!.handleTurnOver() {
                // Show gameover overlay
                showGameOverNode()
                self.isPaused = true
                
                // Display Continue? graphic
                // Show an ad
            }
            
            // Check the model to update the score label
            updateScore(highScore: gameModel!.highScore, gameScore: gameModel!.gameScore)
        }
        
        // Ask the controller if the game is over
        
        if gameModel!.isMidTurn() {
            if false == addedGesture {
                // Ask the model if we showed the fast forward tutorial
                view!.gestureRecognizers = [rightSwipeGesture!]
                addedGesture = true
            }
            
            // Allow the model to handle a turn
            if numTicks >= ticksDelay {
                gameModel!.handleTurn(shootBall: true)
                numTicks = 0
            }
            else {
                numTicks += 1
                gameModel!.handleTurn(shootBall: false)
            }
        }
    }
    
    // MARK: Public functions
    // Handle a right swipe to fast forward
    @objc public func handleSwipeRight(_ sender: UISwipeGestureRecognizer) {
        let point = sender.location(in: view!)
        
        if inGame(point) {
            if gameModel!.isMidTurn() {
                if physicsWorld.speed < 3.0 {
                    physicsWorld.speed += 1.0
                    if 6 == ticksDelay {
                        ticksDelay = 3
                    }
                    else if 3 == ticksDelay {
                        ticksDelay = 1
                    }
                    
                    flashSpeedupImage()
                }
            }
        }
    }
    
    // Initialize the game model (this is where the code for loading a saved game model will go)
    private func initGameModel() {
        // The controller also needs a copy of this game model object
        gameModel = ContinuousGameModel(scene: self, view: view!, ceilingHeight: ceilingNode!.position.y, groundHeight: margin!)
    }
    
    // Checks whether or not a point is in the bounds of the game as opposed to the top or bottom margins
    private func inGame(_ point: CGPoint) -> Bool {
        return ((point.y < ceilingNode!.position.y) && (point.y > groundNode!.size.height))
    }
    
    // Initialize the different walls and physics edges
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
        let size = CGSize(width: view.frame.width, height: view.safeAreaInsets.top + margin)
        ceilingNode = SKSpriteNode(color: marginColor, size: size)
        ceilingNode?.anchorPoint = CGPoint(x: 0, y: 0)
        ceilingNode?.position = CGPoint(x: 0, y: view.frame.height - view.safeAreaInsets.top - margin)
        ceilingNode?.name = "ceiling"
        ceilingNode?.zPosition = 101
        
        let startPoint = CGPoint(x: 0, y: 0)
        let endPoint = CGPoint(x: view.frame.width, y: 0)
        let physBody = createPhysicsEdge(startPoint: startPoint, endPoint: endPoint)
        ceilingNode?.physicsBody = physBody
        
        self.addChild(ceilingNode!)
    }
    
    private func initSideWalls(view: SKView, margin: CGFloat) {
        let lwStartPoint = CGPoint(x: 1, y: margin)
        let lwEndPoint = CGPoint(x: 1, y: view.frame.height - margin)
        let leftWallEdge = createPhysicsEdge(startPoint: lwStartPoint, endPoint: lwEndPoint)
        leftWallNode = SKNode()
        leftWallNode?.physicsBody = leftWallEdge
        leftWallNode?.name = "wall"
        
        let rwStartPoint = CGPoint(x: view.frame.width, y: margin)
        let rwEndPoint = CGPoint(x: view.frame.width, y: view.frame.height - margin)
        let rightWallEdge = createPhysicsEdge(startPoint: rwStartPoint, endPoint: rwEndPoint)
        rightWallNode = SKNode()
        rightWallNode?.physicsBody = rightWallEdge
        rightWallNode?.name = "wall"
        
        self.addChild(leftWallNode!)
        self.addChild(rightWallNode!)
    }
    
    // Creates a physics edge; this code can be reused for side walls and the ceiling node
    private func createPhysicsEdge(startPoint: CGPoint, endPoint: CGPoint) -> SKPhysicsBody {
        let physBody = SKPhysicsBody(edgeFrom: startPoint, to: endPoint)
        physBody.angularDamping = 0
        physBody.linearDamping = 0
        physBody.restitution = 1
        physBody.friction = 0
        physBody.categoryBitMask = categoryBitMask
        physBody.contactTestBitMask = contactTestBitMask
        
        return physBody
    }
    
    // Initializes the current score
    private func initScoreLabel() {
        let pos = CGPoint(x: view!.frame.midX, y: ceilingNode!.size.height / 2)
        scoreLabel = SKLabelNode()
        scoreLabel!.zPosition = 103
        scoreLabel!.position = pos
        scoreLabel!.fontSize = margin! * 0.50
        scoreLabel!.fontName = fontName
        scoreLabel!.verticalAlignmentMode = .center
        scoreLabel!.horizontalAlignmentMode = .center
        scoreLabel!.text = "\(gameModel!.gameScore)"
        ceilingNode!.addChild(scoreLabel!)
    }
    
    // Initializes the high score label
    private func initBestScoreLabel() {
        let pos = CGPoint(x: ceilingNode!.size.width * 0.02, y: ceilingNode!.size.height / 2)
        bestScoreLabel = SKLabelNode()
        bestScoreLabel!.zPosition = 103
        bestScoreLabel!.position = pos
        bestScoreLabel!.fontName = fontName
        bestScoreLabel!.fontSize = margin! * 0.30
        bestScoreLabel!.verticalAlignmentMode = .center
        bestScoreLabel!.horizontalAlignmentMode = .left
        bestScoreLabel!.text = "Best: \(gameModel!.highScore)"
        ceilingNode!.addChild(bestScoreLabel!)
    }
    
    // This arrow code should be separated into its own file because the game mode with levels will also use this
    private func initArrowNode() {
        arrowNode = SKShapeNode()
    }
    
    // Updates where the ball path projection is pointing
    private func updateArrow(startPoint: CGPoint, touchPoint: CGPoint) {
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
        arrowNode!.path = dashedPath
        arrowNode!.strokeColor = color
        arrowNode!.lineWidth = 4
    }
    
    // Shows the ball path projection
    private func showArrow() {
        if (false == arrowIsShowing) {
            self.addChild(arrowNode!)
            arrowIsShowing = true
        }
    }
    
    // Hides the ball path projection (after the user shoots the balls or moves their finger out of game play)
    private func hideArrow() {
        if arrowIsShowing {
            self.removeChildren(in: [arrowNode!])
            arrowIsShowing = false
        }
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
    
    private func updateScore(highScore: Int, gameScore: Int) {
        scoreLabel!.text = "\(gameScore)"
        bestScoreLabel!.text = "Best: \(highScore)"
    }
    
    // Flashes the fast forward image to give the user some feedback about what's happening
    private func flashSpeedupImage() {
        let color = UIColor(red: 119/255, green: 136/255, blue: 153/255, alpha: 1)
        let pos = CGPoint(x: self.view!.frame.midX, y: self.view!.frame.midY)
        let size = CGSize(width: self.view!.frame.width * 0.8, height: self.view!.frame.width * 0.8)
        let imageNode = SKSpriteNode(imageNamed: "fast_forward.png")
        imageNode.alpha = 0
        imageNode.position = pos
        imageNode.size = size
        
        let label = SKLabelNode(fontNamed: fontName)
        label.fontSize = 50
        label.fontColor = color
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: 0)
        if (2.0 == physicsWorld.speed) {
            label.text = "x2"
        }
        else if (3.0 == physicsWorld.speed) {
            label.text = "x3"
        }
        imageNode.addChild(label)
        
        self.addChild(imageNode)
        
        let action1 = SKAction.fadeAlpha(to: 0.5, duration: 0.2)
        let action2 = SKAction.fadeAlpha(to: 0, duration: 0.2)
        
        imageNode.run(SKAction.sequence([action1, action2, action1, action2, action1, action2])) {
            self.removeChildren(in: [imageNode])
        }
    }
    
    // Shows the user how to fast forward the simulation (not currently being used)
    private func showFFTutorial() {
        let size = CGSize(width: view!.frame.width * 0.15, height: view!.frame.width * 0.15)
        let startPoint = CGPoint(x: view!.frame.width * 0.35, y: view!.frame.midY)
        let endPoint = CGPoint(x: view!.frame.width * 0.65, y: view!.frame.midY)
        
        let ffNode = SKSpriteNode(imageNamed: "touch_image.png")
        ffNode.position = startPoint
        ffNode.size = size
        ffNode.alpha = 1
        ffNode.name = "ffTutorial"
        self.addChild(ffNode)
        
        let action1 = SKAction.move(to: endPoint, duration: 0.8)
        let action2 = SKAction.move(to: startPoint, duration: 0.1)
        
        let label = SKLabelNode(fontNamed: fontName)
        label.fontColor = .white
        label.fontSize = 20
        label.text = "Fast forward"
        label.name = "ffLabel"
        label.position = CGPoint(x: view!.frame.midX, y: view!.frame.midY * 0.80)
        self.addChild(label)
        
        ffNode.run(SKAction.sequence([action1, action2, action1, action2, action1])) {
            self.removeChildren(in: [ffNode, label])
        }
    }
    
    // Shows the game over overlay
    private func showGameOverNode() {
        let gameOverNode = SKSpriteNode(color: .darkGray, size: scene!.size)
        gameOverNode.alpha = 0.9
        gameOverNode.zPosition = 105
        gameOverNode.position = CGPoint(x: 0, y: 0)
        gameOverNode.anchorPoint = CGPoint(x: 0, y: 0)
        self.addChild(gameOverNode)
        
        let fontSize = view!.frame.height * 0.2
        let label = SKLabelNode()
        label.zPosition = 106
        label.position = CGPoint(x: view!.frame.midX, y: view!.frame.midY + (fontSize / 2))
        label.fontSize = fontSize
        label.fontName = fontName
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.color = .white
        label.text = "Game"
        
        let label2 = SKLabelNode()
        label2.zPosition = 106
        label2.position = CGPoint(x: view!.frame.midX, y: view!.frame.midY - (fontSize / 2))
        label2.fontSize = fontSize
        label2.fontName = fontName
        label2.verticalAlignmentMode = .center
        label2.horizontalAlignmentMode = .center
        label2.color = .white
        label2.text = "Over"
        
        let label3 = SKLabelNode()
        label3.zPosition = 106
        label3.position = CGPoint(x: view!.frame.midX, y: view!.frame.midY - (fontSize * 1.5))
        label3.fontSize = fontSize * 0.2
        label3.fontName = fontName
        label3.verticalAlignmentMode = .center
        label3.horizontalAlignmentMode = .center
        label3.color = .white
        label3.text = "Touch to restart"
        
        self.addChild(label)
        self.addChild(label2)
        self.addChild(label3)
    }
}
