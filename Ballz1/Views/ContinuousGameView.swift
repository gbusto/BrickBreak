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

class ContinousGameView: SKScene {
    
    // MARK: Private properties
    private var margin : CGFloat?
    private var radius : CGFloat?
    
    private var groundNode : SKSpriteNode?
    private var ceilingNode : SKSpriteNode?
    private var leftWallNode : SKNode?
    private var rightWallNode : SKNode?
    private var arrowNode : SKShapeNode?
    
    private var gameModel: ContinuousGameModel?
    
    private var fontName = "KohinoorBangla-Regular"

    private var scoreLabel : SKLabelNode?
    private var bestScoreLabel : SKLabelNode?
    
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
    }
    
    // MVC: View detects the touch; the code in this function should notify the GameSceneController to handle this event
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let point = touch.location(in: self)
         
            if gameModel!.isMidTurn() {
                // Show the arrow and update it
            }
        }
    }
    
    // MVC: View detects the touch; the code in this function should notify the GameSceneController to handle this event
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let point = touch.location(in: self)
            
            if !inGame(point: point) {
                // Hide the arrow
            }
            else if gameModel!.isReady() && arrowIsShowing {
                // Update the arrow location
            }
        }
    }
    
    // MVC: View detects the touch; the code in this function should notify the GameSceneController to handle this event
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    // MVC: View detects the touch; the code in this function should notify the GameSceneController to handle this event
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let point = touch.location(in: self)
         
            if gameModel!.isReady() && arrowIsShowing {
                // Set the direction for the balls to shoot
                // Tell the controller to shoot the balls
            }
            // Check for game over and display the game over label
        }
        
        // Hide the arrow
    }
    
    // MARK: Scene update
    override func update(_ currentTime: TimeInterval) {
        if gameModel!.isTurnOver() {
            // Return physics simulation to normal speed
            
            // Clear gesture recognizers in the view
            view!.gestureRecognizers = []
            addedGesture = false
            
            // Tell the controller to generate a row of items
            
            // Tell the controller to check for new balls
            
            // Tell the controller update increment the model's state
            
            // Check the model to update the score label
        }
        
        // Ask the controller if the game is over
        
        if gameModel!.isMidTurn() {
            if false == addedGesture {
                // Ask the model if we showed the fast forward tutorial
                view!.gestureRecognizers = [rightSwipeGesture!]
            }
            
            // Tell the controller to have the model check for inactive balls to return
        }
    }
    
    // MARK: Public functions
    // Handle a right swipe to fast forward
    // MVC: This function is called in the view
    @objc public func handleSwipeRight(_ sender: UISwipeGestureRecognizer) {
        //let point = sender.location(in: view!)
    }
    
    // MARK: Private functions
    private func initGameModel() {
        // The controller also needs a copy of this game model object
        gameModel = ContinuousGameModel()
    }
    
    // MVC: Clearly a view function
    private func inGame(point: CGPoint) -> Bool {
        return ((point.y < ceilingNode!.position.y) && (point.y > groundNode!.size.height))
    }
    
    // MVC: A view function
    private func initWalls(view: SKView) {
        margin = view.frame.height * 0.10
        
        initGround(view: view, margin: margin!)
        initCeiling(view: view, margin: margin!)
        initSideWalls(view: view, margin: margin!)
    }
    
    // MVC: A view function
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
    
    // MVC: A view function
    private func initCeiling(view: SKView, margin: CGFloat) {
        let size = CGSize(width: view.frame.width, height: view.safeAreaInsets.top + margin)
        ceilingNode = SKSpriteNode(color: marginColor, size: size)
        ceilingNode?.anchorPoint = CGPoint(x: 0, y: 0)
        ceilingNode?.position = CGPoint(x: 0, y: view.frame.height - view.safeAreaInsets.top - margin)
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
    
    // MVC: A view function
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
    
    // MVC: A view function (but the score is initialized in the model)
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
    
    // MVC: A view function (but the high score is initialized in the model)
    // XXX Should rename anything with bestScore to highScore
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
    
    // MVC: A view function; anything with the arrow node is a view function for now (until we allow the user to upgrade the arrow pointer style)
    private func initArrowNode() {
        arrowNode = SKShapeNode()
    }
    
    // MVC: A view function
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
    
    // MVC: A view function
    private func showArrow() {
        if (false == arrowIsShowing) {
            self.addChild(arrowNode!)
            arrowIsShowing = true
        }
    }
    
    // MVC: A view function
    private func hideArrow() {
        if arrowIsShowing {
            self.removeChildren(in: [arrowNode!])
            arrowIsShowing = false
        }
    }
    
    // MVC: A view function (should be put in a separate file)
    private func calcSlope(originPoint: CGPoint, touchPoint: CGPoint) -> CGFloat {
        let rise = touchPoint.y - originPoint.y
        let run  = touchPoint.x - originPoint.x
        
        return CGFloat(rise / run)
    }
    
    // MVC: A view function (should be put in a separate file)
    private func calcYIntercept(point: CGPoint, slope: CGFloat) -> CGFloat {
        // y = mx + b <- We want to find 'b'
        // (point.y - (point.x * slope)) = b
        let intercept = point.y - (point.x * slope)
        
        return intercept
    }
}
