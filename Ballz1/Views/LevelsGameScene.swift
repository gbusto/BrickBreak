//
//  LevelsGameScene.swift
//  Ballz1
//
//  Created by hemingway on 1/13/19.
//  Copyright © 2019 Self. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit
import CoreGraphics

class LevelsGameScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: Private attributes
    
    private var colorScheme: GameSceneColorScheme?
    
    // The margin aka the ceiling height and ground height
    private var margin: CGFloat?
    
    // The ball radius
    private var ballRadius: CGFloat?
    // The generic item width (typically the view's (width / (number of items per row))
    private var rowHeight: CGFloat?
    // The block size
    private var blockSize: CGSize?
    
    // Views that are active on the screen and need to be removed
    private var activeViews: [UIView] = []
    
    // Nodes that will be shown in the view
    private var groundNode: SKSpriteNode?
    private var ceilingNode: SKShapeNode?
    private var leftWallNode: SKShapeNode?
    private var rightWallNode: SKShapeNode?
    
    // This is essentially the minimum X value for the game play area; if it is zero, it looks like it goes off the left side of the screen; when set to 1 it looks better
    private var leftWallWidth = CGFloat(1)
    private var rightWallWidth = CGFloat(0)
    
    // Attributes based on how the scene is displayed
    private var fontName: String = "HelveticaNeue"
    private var topColor: UIColor = .black
    private var bottomColor: UIColor = .white
    
    // Stuff for collisions
    private var categoryBitMask = UInt32(0b0001)
    private var contactTestBitMask = UInt32(0b0001)
    private var groundCategoryBitmask = UInt32(0b0101)
    
    private static var NUM_ROWS = CGFloat(12)
    private static var NUM_COLUMNS = CGFloat(8)

    // MARK: Override functions
    override func didMove(to view: SKView) {
        // Load the game scene
        margin = view.frame.height * 0.10
        
        /*
         if (blockHeight * 8 > view.width)
         use view.width / 8 as block size
         move ceiling/ground to allow for 12 rows stacked vertically
         else
         use (ceilingY - groundY) / 12 as block size
         move left/right walls to allow for 8 columns horizontally
         */
        
        // 1. Get ceiling starting y position
        let ceilingY = view.frame.height - view.safeAreaInsets.top - margin!
        // 2. Get floor ending y position
        let groundY = margin!
        let blockSize1 = (ceilingY - groundY) / LevelsGameScene.NUM_ROWS
        let blockSize2 = view.frame.width / LevelsGameScene.NUM_COLUMNS
        // Need to determine whether or not we use screen height or width to determine block size
        if (blockSize1 * LevelsGameScene.NUM_COLUMNS) > view.frame.width {
            // We use block width as block size and move ceiling/ground in towards the middle
            blockSize = CGSize(width: blockSize2 * 0.95, height: blockSize2 * 0.95)
            rowHeight = blockSize2
            // Update margin for ceiling/ground here
            // (margin * 2) because there's the ceiling margin and ground margin
            let heightDifference = (view.frame.height - (margin! * 2)) - (blockSize2 * LevelsGameScene.NUM_ROWS)
            margin! += (heightDifference / 2)
        }
        else {
            // We use block height as the block size and move left/right walls in towards the middle
            blockSize = CGSize(width: blockSize1 * 0.95, height: blockSize1 * 0.95)
            rowHeight = blockSize1
            // Update left/right wall width here
            let widthDifference = view.frame.width - (blockSize1 * 8)
            leftWallWidth  = widthDifference / 2
            rightWallWidth = widthDifference / 2
        }
        
        ballRadius = (blockSize!.height / 2) / 3.5
        
        colorScheme = GameSceneColorScheme(backgroundSize: view.frame.size, blockSize: blockSize!)
        fontName = colorScheme!.fontName
        
        // Initialize the walls for the game
        initWalls(view: view)
        
        // Set the background color based on the color scheme value
        self.backgroundColor = colorScheme!.backgroundColor
        
        // Allow ourselves to be the physics contact delegates
        physicsWorld.contactDelegate = self
    }
    
    // MARK: Private functions
    
    // Initialize the different walls and physics edges
    private func initWalls(view: SKView) {
        initGround(view: view, margin: margin!)
        initCeiling(view: view, margin: margin!)
        initSideWalls(view: view, margin: margin!)
    }
    
    private func initGround(view: SKView, margin: CGFloat) {
        let size = CGSize(width: view.frame.width, height: margin)
        groundNode = SKSpriteNode(color: colorScheme!.marginColor, size: size)
        groundNode?.anchorPoint = CGPoint(x: 0, y: 0)
        groundNode?.position = CGPoint(x: 0, y: 0)
        groundNode?.name = "ground"
        groundNode?.zPosition = 100
        
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
        let startPoint = CGPoint(x: leftWallWidth, y: 0)
        let endPoint = CGPoint(x: view.frame.width - rightWallWidth, y: 0)
        let physBody = createPhysicsEdge(startPoint: startPoint, endPoint: endPoint)
        
        let ceilingLine = CGMutablePath()
        ceilingLine.move(to: startPoint)
        ceilingLine.addLine(to: endPoint)
        ceilingNode = SKShapeNode()
        ceilingNode?.zPosition = 101
        ceilingNode!.path = ceilingLine
        ceilingNode!.name = "ceiling"
        ceilingNode!.strokeColor = colorScheme!.marginColor
        ceilingNode!.lineWidth = 1
        ceilingNode!.physicsBody = physBody
        ceilingNode!.position = CGPoint(x: 0, y: view.frame.height - view.safeAreaInsets.top - margin)
        
        self.addChild(ceilingNode!)
    }
    
    private func initSideWalls(view: SKView, margin: CGFloat) {
        let leftWallSize = CGSize(width: leftWallWidth, height: view.frame.height - (margin * 2))
        let lwStartPoint = CGPoint(x: leftWallWidth, y: 0)
        let lwEndPoint = CGPoint(x: leftWallWidth, y: leftWallSize.height)
        let leftWallEdge = createPhysicsEdge(startPoint: lwStartPoint, endPoint: lwEndPoint)
        
        let leftWallLine = CGMutablePath()
        leftWallLine.move(to: lwStartPoint)
        leftWallLine.addLine(to: lwEndPoint)
        leftWallNode = SKShapeNode()
        leftWallNode!.path = leftWallLine
        leftWallNode!.name = "wall"
        leftWallNode!.strokeColor = colorScheme!.marginColor
        leftWallNode!.lineWidth = 1
        leftWallNode!.physicsBody = leftWallEdge
        leftWallNode!.position = CGPoint(x: 0, y: margin)
        
        let leftBlock = SKSpriteNode(color: colorScheme!.backgroundColor, size: leftWallSize)
        leftBlock.zPosition = 101
        leftBlock.position = CGPoint(x: 0, y: 0)
        leftBlock.anchorPoint = CGPoint(x: 0, y: 0)
        leftWallNode!.addChild(leftBlock)
        
        let rightWallSize = CGSize(width: rightWallWidth, height: view.frame.height - (margin * 2))
        let rwStartPoint = CGPoint(x: 0, y: 0)
        let rwEndPoint = CGPoint(x: 0, y: rightWallSize.height)
        let rightWallEdge = createPhysicsEdge(startPoint: rwStartPoint, endPoint: rwEndPoint)
        
        let rightWallLine = CGMutablePath()
        rightWallLine.move(to: rwStartPoint)
        rightWallLine.addLine(to: rwEndPoint)
        rightWallNode = SKShapeNode()
        rightWallNode!.path = rightWallLine
        rightWallNode!.name = "wall"
        rightWallNode!.strokeColor = colorScheme!.marginColor
        rightWallNode!.lineWidth = 1
        rightWallNode!.physicsBody = rightWallEdge
        rightWallNode!.position = CGPoint(x: view.frame.width - rightWallWidth, y: margin)
        
        let rightBlock = SKSpriteNode(color: colorScheme!.backgroundColor, size: rightWallSize)
        rightBlock.zPosition = 101
        rightBlock.position = CGPoint(x: 0, y: 0)
        rightBlock.anchorPoint = CGPoint(x: 0, y: 0)
        rightWallNode!.addChild(rightBlock)
        
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
    
    public func showPauseScreen(pauseView: UIView) {
        let blur = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blur)
        blurView.frame = view!.frame
        view!.addSubview(blurView)
        
        pauseView.isHidden = false
        view!.addSubview(pauseView)
        
        activeViews = [blurView, pauseView]
    }
    
    public func resumeGame() {
        self.isPaused = false
        self.view!.isPaused = false
        
        let views = activeViews.filter {
            $0.removeFromSuperview()
            return false
        }
        
        activeViews = views
    }
}
