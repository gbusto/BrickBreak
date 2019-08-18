//
//  GameScene.swift
//  Ballz1
//
//  Created by Gabriel Busto on 5/19/19.
//  Copyright © 2019 Self. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit
import GameplayKit
import CoreGraphics

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: Public attributes
    public var colorScheme: GameSceneColorScheme?

    
    // MARK: Private attributes
    // The margin aka the ceiling height and ground height
    private var margin: CGFloat?
    
    // The ball radius
    public var ballRadius: CGFloat?
    // The generic item width (typically the view's (width / (number of items per row))
    private var rowHeight: CGFloat?
    // The block size
    public var blockSize: CGSize?
    
    // Ball count label
    public var ballCountLabel: SKLabelNode?
    public var currentBallCount = Int(0)
    // This is to prevent the ball count label from being too far right or too far left
    private var ballCountLabelMargin = CGFloat(0.05)
    
    // Views that are active on the screen and need to be removed
    public var activeViews: [UIView] = []
    
    // Nodes that will be shown in the view
    public var groundNode: SKSpriteNode?
    public var ceilingNode: SKShapeNode?
    public var leftWallNode: SKShapeNode?
    public var rightWallNode: SKShapeNode?
    
    // Variable to know when actions are complete
    private var actionsStarted = Int(0)
    
    // A boolean that says whether or not we're showing encouragement (emoji + text) on the screen
    private var showingEncouragement = false
    
    // This is essentially the minimum X value for the game play area; if it is zero, it looks like it goes off the left side of the screen; when set to 1 it looks better
    private var leftWallWidth = CGFloat(1)
    private var rightWallWidth = CGFloat(0)
    
    // Attributes based on how the scene is displayed
    // XXX With some minor changes this could be left private
    public var fontName: String = "HelveticaNeue"
    private var topColor: UIColor = .black
    private var bottomColor: UIColor = .white
    
    // The index into the color list array
    private var colorIndex = Int(3)
    private var colorIndices: [Int] = [0, 0, 0, 0]
    private var colorList: [UIColor] = [
        UIColor(rgb: 0xffab91),
        UIColor(rgb: 0xffcc80),
        UIColor(rgb: 0xffe082),
        UIColor(rgb: 0xfff59d),
        UIColor(rgb: 0xe6ee9c),
        UIColor(rgb: 0xc5e1a5),
        UIColor(rgb: 0xa5d6a7),
        UIColor(rgb: 0x80cbc4),
        UIColor(rgb: 0x80deea),
        UIColor(rgb: 0x81d4fa),
        UIColor(rgb: 0x90caf9),
        UIColor(rgb: 0x9fa8da),
        UIColor(rgb: 0xb39ddb),
        UIColor(rgb: 0xce93d8),
        UIColor(rgb: 0xf48fb1),
        UIColor(rgb: 0xef9a9a),
    ]
    
    // Stuff for collisions
    private var categoryBitMask = UInt32(0b0001)
    private var contactTestBitMask = UInt32(0b0001)
    private var groundCategoryBitmask = UInt32(0b0101)
    
    public static var NUM_ROWS = CGFloat(12)
    public static var NUM_COLUMNS = CGFloat(8)
    
    /* Ball-related variables */
    public var originPoint = CGPoint(x: 0, y: 0)
    public var ballArray: [BallItem] = []
    public var fireDelay = GameScene.DEFAULT_FIRE_DELAY
    public static var DEFAULT_FIRE_DELAY = Double(0.1)
    public var stoppedBalls: [BallItem] = []
    public var firstBallReturned = false
    public var ballsOnFire = false
    public var firedAllBalls = false
    public var numBallsFired = 0
    public var endTurn = false
    
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
        
        // Clear out the view of all the subviews
        let views = activeViews.filter {
            $0.removeFromSuperview()
            return false
        }
        activeViews = views
        
        // 1. Get ceiling starting y position
        let ceilingY = view.frame.height - margin!
        // 2. Get floor ending y position
        let groundY = margin!
        let blockSize1 = (ceilingY - groundY) / GameScene.NUM_ROWS
        let blockSize2 = view.frame.width / GameScene.NUM_COLUMNS
        // Need to determine whether or not we use screen height or width to determine block size
        if (blockSize1 * GameScene.NUM_COLUMNS) > view.frame.width {
            // We use block width as block size and move ceiling/ground in towards the middle
            blockSize = CGSize(width: blockSize2 * 0.95, height: blockSize2 * 0.95)
            rowHeight = blockSize2
            // Update margin for ceiling/ground here
            // (margin * 2) because there's the ceiling margin and ground margin
            let heightDifference = (view.frame.height - (margin! * 2)) - (blockSize2 * GameScene.NUM_ROWS)
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
        topColor = colorList[colorIndex]
        
        // Initialize the walls for the game
        initWalls(view: view)
        
        // Set the background color based on the color scheme value
        self.backgroundColor = colorScheme!.backgroundColor
    }
    
    public func initBallArray(numberOfBalls: Int, point: CGPoint) -> [BallItem] {
        var ballArray: [BallItem] = []
        for i in 1...numberOfBalls {
            let ball = BallItem()
            let size = CGSize(width: ballRadius!, height: ballRadius!)
            ball.initItem(num: i, size: size)
            ball.getNode().name! = "bm\(i)"
            ballArray.append(ball)
            ball.loadItem(position: point)
            ball.resetBall()
        }
        
        return ballArray
    }
    
    public func getMargin() -> CGFloat {
        return margin!
    }
    
    public func getLeftWallWidth() -> CGFloat {
        return leftWallWidth
    }
    
    public func getRightWallWidth() -> CGFloat {
        return rightWallWidth
    }
    
    // MARK: Public function
    // Flashes the fast forward image to give the user some feedback about what's happening
    public func flashSpeedupImage() {
        let pos = CGPoint(x: self.view!.frame.midX, y: self.view!.frame.midY)
        let size = CGSize(width: self.view!.frame.width * 0.8, height: self.view!.frame.width * 0.8)
        let imageNode = SKSpriteNode(imageNamed: "fast_forward_icon")
        imageNode.alpha = 0
        imageNode.zPosition = 101
        imageNode.position = pos
        imageNode.size = size
        
        self.addChild(imageNode)
        
        let action1 = SKAction.fadeAlpha(to: 0.3, duration: 0.2)
        let action2 = SKAction.fadeAlpha(to: 0, duration: 0.2)
        
        imageNode.run(SKAction.sequence([action1, action2, action1, action2, action1, action2])) {
            self.removeChildren(in: [imageNode])
        }
    }
    
    public func doneAnimatingItems() -> Bool {
        return 0 == actionsStarted
    }
    
    public func animateItems(numItems: Int, array: [[Item]]) {
        actionsStarted = numItems
        
        let action = SKAction.moveBy(x: 0, y: -rowHeight!, duration: 1)
        
        if 0 == array.count {
            // No items to animate
            return
        }
        
        for i in 0...(array.count - 1) {
            let row = array[i]
            for item in row {
                if item is SpacerItem {
                    // SpacerItems aren't included in the actionsStarted count so skip their animation here
                    continue
                }
                
                if item is StoneHitBlockItem {
                    let block = item as! StoneHitBlockItem
                    block.changeState(duration: 1)
                }
                
                // If the item is invisible, have it fade in
                if 0 == item.getNode().alpha {
                    // If this is the newest row
                    let fadeIn = SKAction.fadeIn(withDuration: 1)
                    item.getNode().run(SKAction.group([fadeIn, action])) {
                        self.actionsStarted -= 1
                    }
                }
                else if (i == 0) && (array.count == Int(LevelsGameScene.NUM_ROWS - 1)) {
                    // Move these items down on the screen
                    if (item is BallItem) || (item is BombItem) {
                        // If this is a ball item or bomb item, these items should just fade out and be removed from the scene and the item generator
                        let fadeOut = SKAction.fadeOut(withDuration: 1)
                        item.getNode().run(SKAction.group([action, fadeOut])) {
                            self.removeChildren(in: [item.getNode()])
                            self.actionsStarted -= 1
                        }
                    }
                    else {
                        // Otherwise if this item is just a block then move it down; it will be removed later if the user decides to save themselves
                        item.getNode().run(action) {
                            self.actionsStarted -= 1
                        }
                    }
                    
                    // Reset the physics body on this node so it doesn't push the ball through the ground
                    item.getNode().physicsBody = nil
                    
                    // Don't remove the row from the itemArray; the model will handle that
                }
                else {
                    item.getNode().run(action) {
                        self.actionsStarted -= 1
                    }
                }
            }
        }
    }
    
    public func colorizeBlocks(itemRow: [Item]) {
        bottomColor = topColor
        colorIndex += 1
        if colorIndex == colorList.count {
            colorIndex = 0
        }
        topColor = colorList[colorIndex]
        
        for item in itemRow {
            if item is HitBlockItem {
                let block = item as! HitBlockItem
                block.setAttributes(bottomColor: bottomColor,
                                    topColor: topColor,
                                    textColor: colorScheme!.blockTextColor,
                                    fontName: colorScheme!.fontName)
            }
            if item is StoneHitBlockItem {
                let block = item as! StoneHitBlockItem
                block.setAttributes(bottomColor: bottomColor,
                                    topColor: topColor,
                                    textColor: colorScheme!.blockTextColor,
                                    fontName: colorScheme!.fontName)
            }
            if item is MysteryBlockItem {
                let block = item as! MysteryBlockItem
                block.setAttributes(bottomColor: bottomColor,
                                    topColor: topColor,
                                    textColor: colorScheme!.blockTextColor,
                                    fontName: colorScheme!.fontName)
            }
        }
    }
    
    public func addRowToView(rowNum: Int, items: [Item]) {
        colorizeBlocks(itemRow: items)
        
        if items.count > 0 {
            for i in 0...(items.count - 1) {
                let item = items[i]
                if item is SpacerItem {
                    continue
                }
                
                var pos = CGPoint(x: 0, y: 0)
                if item is HitBlockItem {
                    let posX = (CGFloat(i) * rowHeight!) + (rowHeight! * 0.025) + leftWallWidth
                    let posY = CGFloat(ceilingNode!.position.y - (rowHeight! * CGFloat(rowNum)))
                    pos = CGPoint(x: posX, y: posY)
                }
                else if item is StoneHitBlockItem {
                    let posX = (CGFloat(i) * rowHeight!) + (rowHeight! * 0.025) + leftWallWidth
                    let posY = CGFloat(ceilingNode!.position.y - (rowHeight! * CGFloat(rowNum)))
                    pos = CGPoint(x: posX, y: posY)
                }
                else if item is MysteryBlockItem {
                    let posX = (CGFloat(i) * rowHeight!) + (rowHeight! * 0.025) + leftWallWidth
                    let posY = CGFloat(ceilingNode!.position.y - (rowHeight! * CGFloat(rowNum)))
                    pos = CGPoint(x: posX, y: posY)
                }
                else if item is BombItem {
                    let posX = (CGFloat(i) * rowHeight!) + leftWallWidth
                    let posY = CGFloat(ceilingNode!.position.y - (rowHeight! * CGFloat(rowNum)))
                    pos = CGPoint(x: posX, y: posY)
                }
                else if item is BallItem {
                    let posX = (CGFloat(i) * rowHeight!) + (rowHeight! / 2) + leftWallWidth
                    let posY = CGFloat(ceilingNode!.position.y - (rowHeight! * CGFloat(rowNum))) + (rowHeight! / 2)
                    pos = CGPoint(x: posX, y: posY)
                    let ball = item as! BallItem
                    ball.setColor(color: colorScheme!.hitBallColor)
                }
                
                // The item will fade in
                item.getNode().alpha = 0
                item.loadItem(position: pos)
                self.addChild(item.getNode())
            }
        }
    }
    
    public func addBallCountLabel(position: CGPoint, ballCount: Int) {
        currentBallCount = ballCount
        var newPoint = CGPoint(x: position.x, y: (position.y + (ballRadius! * 1.5)))
        let viewWidth = view!.frame.width - (leftWallWidth * 2)
        // This is to prevent the ball count label from going off the screen
        if newPoint.x < (leftWallWidth + (viewWidth * ballCountLabelMargin)) {
            // If we're close to the far left side, add a small amount to the x value
            newPoint.x += viewWidth * 0.03
        }
        else if newPoint.x > ((view!.frame.width - rightWallWidth) - (viewWidth * ballCountLabelMargin)) {
            // Opposite of the above comment
            newPoint.x -= viewWidth * 0.03
        }
        
        ballCountLabel!.position = newPoint
        ballCountLabel!.fontSize = ballRadius! * 2.5
        ballCountLabel!.color = .white
        
        updateBallCountLabel()
        if let _ = self.childNode(withName: "ballCountLabel") {
            // If this label is already displayed, don't display it again
        }
        else {
            self.addChild(ballCountLabel!)
        }
    }
    
    public func updateBallCountLabel() {
        ballCountLabel!.text = "x\(currentBallCount)"
    }
    
    public func removeBallCountLabel() {
        self.removeChildren(in: [ballCountLabel!])
    }
    
    public func allBallsStopped(_ ballArray: [BallItem]) -> Bool {
        var allBallsStopped = true
        let _ = ballArray.filter {
            if false == $0.isResting {
                allBallsStopped = false
                if $0.outOfBounds {
                    // If the ball is out of bounds, stop it and move it back to the origin point
                    self.stoppedBalls.append($0)
                    $0.stop()
                }
            }
            return true
        }
        return allBallsStopped
    }
    
    public func displayEncouragement(emoji: String, text: String) {
        if showingEncouragement {
            // If we're showing encouragement on the screen, don't display something else
            return
        }
        
        let label = SKLabelNode()
        label.text = emoji
        label.fontSize = view!.frame.width * 0.3
        label.alpha = 0
        label.position = CGPoint(x: view!.frame.midX, y: view!.frame.midY)
        label.zPosition = 105
        
        let text = SKLabelNode(text: text)
        text.fontSize = label.fontSize / 2.5
        text.fontName = fontName
        text.alpha = 0
        text.position = CGPoint(x: view!.frame.midX, y: label.position.y - (text.fontSize * 1.5))
        text.zPosition = 105
        text.fontColor = .white
        
        showingEncouragement = true
        
        let action1 = SKAction.fadeIn(withDuration: 1)
        let action2 = SKAction.wait(forDuration: 1)
        let action3 = SKAction.fadeOut(withDuration: 1)
        label.run(SKAction.sequence([action1, action2, action3])) {
            self.removeChildren(in: [label])
        }
        text.run(SKAction.sequence([action1, action2, action3])) {
            self.removeChildren(in: [text])
            self.showingEncouragement = false
        }
        
        self.addChild(label)
        self.addChild(text)
    }
    
    public func startFlashingRed() {
        // If the screen is already flashing red then don't do anything
        if let node = self.childNode(withName: "warningNode") {
            return
        }
        
        // Display this warning to the user
        displayEncouragement(emoji: "😬", text: "Careful!")
        
        let darkRed = UIColor(red: 153/255, green: 0, blue: 0, alpha: 1)
        let action1 = SKAction.fadeAlpha(by: 0.5, duration: 1)
        let action2 = SKAction.fadeOut(withDuration: 1)
        
        let frontNode = SKSpriteNode(color: darkRed, size: view!.frame.size)
        frontNode.anchorPoint = CGPoint(x: 0, y: 0)
        frontNode.position = CGPoint(x: 0, y: 0)
        frontNode.zPosition = 101
        frontNode.alpha = 0
        frontNode.name = "warningNode"
        
        let sequence = SKAction.sequence([action1, action2])
        
        frontNode.run(SKAction.repeatForever(sequence))
        
        self.addChild(frontNode)
    }
    
    public func stopFlashingRed() {
        if let node = self.childNode(withName: "warningNode") {
            node.run(SKAction.fadeOut(withDuration: 1)) {
                self.removeChildren(in: [node])
                self.displayEncouragement(emoji: "😅", text: "Phew!")
            }
        }
    }
    
    public func breakBlock(color1: SKColor, color2: SKColor, position: CGPoint) {
        let colors: [UIColor] = [color1, color2]
        let alphas: [CGFloat] = [0.1, 0.2, 0.3, 0.4, 0.5]
        let numBlocks = 16 // Arbitrary; just a number for now
        let newSize = CGSize(width: blockSize!.width / 4, height: blockSize!.height / 4)
        var blocks: [SKSpriteNode] = []
        for _ in 0...(numBlocks - 1) {
            let newPosition = CGPoint(x: position.x + CGFloat(Int.random(in: -20...20)),
                                      y: position.y + CGFloat(Int.random(in: -20...20)))
            let block = SKSpriteNode(color: colors.randomElement()!, size: newSize)
            block.position = newPosition
            block.alpha = alphas.randomElement()!
            
            let physBody = SKPhysicsBody()
            physBody.affectedByGravity = true
            physBody.isDynamic = true
            block.physicsBody = physBody
            
            blocks.append(block)
            self.addChild(block)
        }
        
        for block in blocks {
            let vector = CGVector(dx: CGFloat(Int.random(in: -150...150)), dy: CGFloat(Int.random(in: 200...400)))
            let action1 = SKAction.applyImpulse(vector, duration: 0.1)
            let action2 = SKAction.fadeOut(withDuration: 1)
            block.run(SKAction.sequence([action1, action2])) {
                self.removeChildren(in: [block])
            }
        }
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
        ceilingNode!.position = CGPoint(x: 0, y: view.frame.height - margin)
        
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
    
    /*************************************************/
    
    public func returnAllBalls() {
        if false == firstBallReturned {
            firstBallReturned = true
        }
        
        for ball in ballArray {
            ball.getNode().physicsBody!.collisionBitMask = 0
            ball.getNode().physicsBody!.categoryBitMask = 0
            ball.getNode().physicsBody!.contactTestBitMask = 0
            ball.stop()
            ball.moveBallTo(originPoint)
        }
        
        // shootBalls() will increment the ball manager's state if it's shooting
    }
    
    public func setBallsOnFire() {
        ballsOnFire = true
        for ball in ballArray {
            if false == ball.isResting {
                ball.setOnFire()
            }
        }
    }
    
    public func startTimer(_ point: CGPoint) {
        let _ = Timer.scheduledTimer(withTimeInterval: fireDelay, repeats: true) { timer in
            if self.endTurn {
                // Let the game know that we've shot all the balls
                self.firedAllBalls = true
                // If the user swiped down, invalidate the timer and stop
                timer.invalidate()
                return
            }
            
            if self.physicsWorld.speed > 1.0 && (self.fireDelay == LevelsGameScene.DEFAULT_FIRE_DELAY) {
                timer.invalidate()
                self.fireDelay = self.fireDelay / 2
                self.startTimer(point)
                return
            }
            
            // Set this boolean so we know whether or not this is the last ball and need to remove the label
            let lastBall = (self.numBallsFired == (self.ballArray.count - 1))
            
            let ball = self.ballArray[self.numBallsFired]
            ball.fire(point: point)
            self.numBallsFired += 1
            if self.ballsOnFire {
                ball.setOnFire()
            }
            self.currentBallCount -= 1
            // If we're on the last ball. after firing it remove the ball count label
            if lastBall {
                self.removeBallCountLabel()
                self.firedAllBalls = true
                timer.invalidate()
            }
            else {
                self.updateBallCountLabel()
            }
        }
    }
    
    // Actions to perform when a ball stops (reaches the ground)
    public func handleStoppedBalls() {
        if stoppedBalls.count > 0 {
            // Pop this ball off the front of the list
            let ball = stoppedBalls.removeFirst()
            if false == firstBallReturned {
                firstBallReturned = true
                var ballPosition = ball.getNode().position
                if ballPosition.y > groundNode!.size.height {
                    ballPosition.y = groundNode!.size.height
                }
                originPoint = ball.getNode().position
            }
            // This should work and prevent balls from landing in the middle of the screen...
            ball.moveBallTo(originPoint)
        }
    }
    
    // Checks whether or not a point is in the bounds of the game as opposed to the top or bottom margins
    public func inGame(_ point: CGPoint) -> Bool {
        return ((point.y < ceilingNode!.position.y) && (point.y > groundNode!.size.height))
    }
    
    // Checks if a ball is out of bounds
    public func isOutOfBounds(ballPosition: CGPoint) -> Bool {
        return ((ballPosition.y > 1000) || (ballPosition.x < -1000) || (ballPosition.x > 1000))
    }
}
