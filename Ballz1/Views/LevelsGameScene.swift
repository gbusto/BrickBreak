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
    
    // MARK: Public attributes
    public var gameModel: LevelsGameModel?
    
    public var gameController: LevelsGameController?
    
    // XXX This is a workaround while saving state doesn't work
    public var levelCount = Int(0)
    
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
    
    // Ball count label
    private var ballCountLabel: SKLabelNode?
    private var prevBallCount = Int(0)
    private var currentBallCount = Int(0)
    // This is to prevent the ball count label from being too far right or too far left
    private var ballCountLabelMargin = CGFloat(0.05)
    
    // A counter for each time update is called
    private var numTicks = Int(0)
    // The number of update ticks to wait before shooting another ball
    private var ticksDelay = Int(6)
    
    // Variables for handling swipe gestures
    private var rightSwipeGesture: UISwipeGestureRecognizer?
    private var downSwipeGesture: UISwipeGestureRecognizer?
    private var addedGesture = false
    private var swipedDown = false
    
    // Views that are active on the screen and need to be removed
    private var activeViews: [UIView] = []
    
    // Nodes that will be shown in the view
    private var groundNode: SKSpriteNode?
    private var ceilingNode: SKShapeNode?
    private var leftWallNode: SKShapeNode?
    private var rightWallNode: SKShapeNode?
    
    // Variable to know when actions are complete
    private var actionsStarted = Int(0)
    
    // This is to keep track of the number of broken hit blocks in a given turn
    private var brokenHitBlockCount: Int = 0
    // A boolean because we only want to show the "on fire" encouragement once per turn
    private var displayedOnFire: Bool = false
    // This is the number of blocks that need to be broken in a given turn to get the "on fire" encouragement
    private static var ON_FIRE_COUNT: Int = 8
    
    // A boolean that says whether or not we're showing encouragement (emoji + text) on the screen
    private var showingEncouragement = false
    
    // This is essentially the minimum X value for the game play area; if it is zero, it looks like it goes off the left side of the screen; when set to 1 it looks better
    private var leftWallWidth = CGFloat(1)
    private var rightWallWidth = CGFloat(0)
    
    // Specifies whether or not the game just started
    private var gameStart = true
    
    // The number of rows to display at the start of the game
    private var numRowsToStart = Int(5)
    
    private var ballProjection = BallProjection()
    
    // Attributes based on how the scene is displayed
    private var fontName: String = "HelveticaNeue"
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
    
    private var numRowsGenerated = Int(0)
    
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
        topColor = colorList[colorIndex]
        
        // Initialize the walls for the game
        initWalls(view: view)
        
        // Initialize the game model
        initGameModel()
        
        // This kind of breaks MVC a bit because the ball manager shouldn't know the ground height
        gameModel!.ballManager!.setGroundHeight(height: groundNode!.size.height + ballRadius!)
        
        rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleRightSwipe(_:)))
        rightSwipeGesture!.direction = .right
        rightSwipeGesture!.numberOfTouchesRequired = 1
        
        downSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleDownSwipe(_:)))
        downSwipeGesture!.direction = .down
        downSwipeGesture!.numberOfTouchesRequired = 1
        
        // Set the background color based on the color scheme value
        self.backgroundColor = colorScheme!.backgroundColor
        
        // Allow ourselves to be the physics contact delegates
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
                if inGame(point) && (false == self.isPaused) {
                    let originPoint = gameModel!.ballManager!.getOriginPoint()
                    ballProjection.showArrow(scene: self)
                    let _ = ballProjection.updateArrow(startPoint: originPoint,
                                                       touchPoint: point,
                                                       ceilingHeight: ceilingNode!.position.y,
                                                       groundHeight: groundNode!.size.height)
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
                ballProjection.hideArrow(scene: self)
            }
            else if gameModel!.isReady() && ballProjection.arrowShowing {
                // Update the arrow location
                let originPoint = gameModel!.ballManager!.getOriginPoint()
                let _ = ballProjection.updateArrow(startPoint: originPoint,
                                                   touchPoint: point,
                                                   ceilingHeight: ceilingNode!.position.y,
                                                   groundHeight: groundNode!.size.height)
            }
        }
    }
    
    // MVC: View detects the touch; the code in this function should notify the GameSceneController to handle this event
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let point = touch.location(in: self)
            
            if gameModel!.isReady() && ballProjection.arrowShowing {
                // Set the direction for the balls to shoot
                let originPoint = gameModel!.ballManager!.getOriginPoint()
                let firePoint = ballProjection.updateArrow(startPoint: originPoint,
                                                           touchPoint: point,
                                                           ceilingHeight: ceilingNode!.position.y,
                                                           groundHeight: groundNode!.size.height)
                gameModel!.prepareTurn(point: firePoint)
            }
        }
        
        // Hide the arrow
        ballProjection.hideArrow(scene: self)
    }
    
    // MVC: View detects the touch; the code in this function should notify the GameSceneController to handle this event
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    // MARK: Scene update
    override func update(_ currentTime: TimeInterval) {
        let gameScore = gameModel!.gameScore
        if let controller = gameController {
            controller.updateScore(score: gameScore)
        }
        
        if gameModel!.isTurnOver() {
            // Return physics simulation to normal speed
            physicsWorld.speed = 1.0
            
            // Reset the tick delay for firing balls
            ticksDelay = 6
            
            // Clear gesture recognizers in the view
            view!.gestureRecognizers = []
            addedGesture = false
            
            // Tell the game model to update now that the turn has ended
            gameModel!.handleTurnOver()
            
            // Addressed in issue #431
            // XXX This state (TURN_OVER) is screwing things up:
            /*
             1. It's adding an extra row to the start of the game that messes up logic when checking for loss risk and game over
             2. When the game is over, all that's left is rows of spacer items and the item generator cleans those out but this then adds an extra row that breaks the model checking for whether or not the user won the game
            */
            if gameStart {
                // If the game just started, don't execute the block of code below
                gameStart = false
            }
            else {
                let items = gameModel!.generateRow()
                if items.count > 0 {
                    // Get the newly generated items and add them to the view
                    addRowToView(rowNum: 1, items: items)
                }
            }
            
            // Move the items down in the view
            animateItems()
            
            // Display the label showing how many balls the user has (this needs to be done after we have collected any new balls the user acquired)
            currentBallCount = gameModel!.getBalls().count
            // See if the user acquired any new balls
            let diff = currentBallCount - prevBallCount
            if diff > 0 {
                // Show a floating label saying how many balls the user acquired that turn
                showBallsAcquiredLabel(count: diff)
            }
            // Update the previous ball count to the current count so that next time around we can see if the user acquired more balls
            prevBallCount = currentBallCount
            addBallCountLabel()
            
            // Check the model to update the score label
            // Update the current game score
            
            // Reset the number of hit blocks and the encouragements shown to the user
            brokenHitBlockCount = 0
            displayedOnFire = false
        }
        
        // After the turn over, wait for the game logic to decide whether or not the user is about to lose or has lost
        if gameModel!.isWaiting() {
            if 0 == actionsStarted {
                // Increment game model state from WAITING to READY
                gameModel!.incrementState()
                
                // XXX Gameover can be good or bad here; gameover loss is when a block hits the ground and gameover win is when the user destroys all blocks and collects all items
                // Check to see if the game ended after all animations are complete
                let gameOverType = gameModel!.gameOver()
                if gameOverType == LevelsGameModel.GAMEOVER_LOSS {
                    // If the game is over, the game model will change its state to GAME_OVER
                    view!.isPaused = true
                    // Otherwise show the gameover overlay
                    self.gameOverLoss()
                }
                else if gameOverType == LevelsGameModel.GAMEOVER_WIN {
                    // If the game is over, the game model will change its state to GAME_OVER
                    view!.isPaused = true
                    // Otherwise show the gameover overlay
                    self.gameOverWin()
                }
                else if gameOverType == LevelsGameModel.GAMEOVER_NONE {
                    // Check to see if we are at risk of losing the game
                    if gameModel!.lossRisk() {
                        // Flash notification to user
                        startFlashingRed()
                    }
                    else {
                        stopFlashingRed()
                    }
                }
            }
        }
        
        if gameModel!.isReady() {
            // Don't need to do anything here
        }
        
        // Actions to perform while in the middle of a turn
        if gameModel!.isMidTurn() {
            if false == addedGesture {
                // Ask the model if we showed the fast forward tutorial
                view!.gestureRecognizers = [rightSwipeGesture!, downSwipeGesture!]
                addedGesture = true
            }
            
            if swipedDown {
                // Handle ball return gesture
                gameModel!.endTurn()
                swipedDown = false
            }
            
            // Shoot a ball with a delay count of ticksDelay
            // This code is still pretty ugly and can probably be cleaned up
            if numTicks >= ticksDelay {
                if gameModel!.shootBall() {
                    currentBallCount -= 1
                    if 0 == currentBallCount {
                        removeBallCountLabel()
                    }
                    else {
                        updateBallCountLabel()
                    }
                }
                numTicks = 0
            }
            else {
                numTicks += 1
            }
            
            // Allow the model to handle a turn
            let removedItems = gameModel!.handleTurn()
            for item in removedItems {
                if item is HitBlockItem {
                    // We want to remove block items from the scene completely
                    self.removeChildren(in: [item.getNode()])
                    // Show block break animation
                    let block = item as! HitBlockItem
                    var centerPoint = block.getNode().position
                    centerPoint.x += blockSize!.width / 2
                    centerPoint.y += blockSize!.height / 2
                    breakBlock(color1: block.bottomColor!, color2: block.topColor!, position: centerPoint)
                    brokenHitBlockCount += 1
                }
                else if item is StoneHitBlockItem {
                    self.removeChildren(in: [item.getNode()])
                    let block = item as! StoneHitBlockItem
                    var centerPoint = block.getNode().position
                    centerPoint.x += blockSize!.width / 2
                    centerPoint.y += blockSize!.height / 2
                    breakBlock(color1: block.bottomColor!, color2: block.topColor!, position: centerPoint)
                    brokenHitBlockCount += 1
                }
                else if item is BombItem {
                    self.removeChildren(in: [item.getNode()])
                }
                else if item is BallItem {
                    // Ball items are not removed; they are just transferred over to the BallManager from the ItemGenerator
                    let vector = CGVector(dx: 0, dy: ballRadius! * 0.5)
                    let ball = item.getNode()
                    ball.physicsBody!.affectedByGravity = true
                    ball.run(SKAction.applyImpulse(vector, duration: 0.05))
                    ballHitAnimation(color: colorScheme!.hitBallColor, position: ball.position)
                }
            }
            
            // If the user has broken greater than X blocks this turn, they get an "on fire" encouragement
            if brokenHitBlockCount > LevelsGameScene.ON_FIRE_COUNT && (false == displayedOnFire) {
                // Display the on fire encouragement
                displayEncouragement(emoji: "🔥", text: "On fire!")
                displayedOnFire = true
                gameModel!.addOnFireBonus()
            }
        }
    }
    
    // MARK: Public functions
    // Handle a right swipe to fast forward
    @objc public func handleRightSwipe(_ sender: UISwipeGestureRecognizer) {
        let point = sender.location(in: view!)
        
        if inGame(point) {
            if gameModel!.isMidTurn() {
                // Speed up the physics simulation
                if physicsWorld.speed < 3.0 {
                    physicsWorld.speed = 3.0
                    ticksDelay = 1
                    
                    flashSpeedupImage()
                }
            }
        }
    }
    
    // Handle a down swipe to return balls
    @objc public func handleDownSwipe(_ sender: UISwipeGestureRecognizer) {
        let point = sender.location(in: view!)
        
        if inGame(point) {
            if gameModel!.isMidTurn() {
                swipedDown = true
            }
        }
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
    
    public func gameOverLoss() {
        // Notify the controller that the user lost
        if let controller = gameController {
            controller.gameOverLoss()
        }
    }
    
    public func gameOverWin() {
        // Notify the controller that the user won
        
        // XXX Need to save the level count here
        // Addressed in issue #431
        //gameModel!.saveState()
        
        if let controller = gameController {
            // XXX Workaround while saving state doesn't work
            let lc = gameModel!.levelCount
            controller.gameOverWin(levelCount: lc)
        }
    }
    
    // MARK: Private functions
    private func initGameModel() {
        gameModel = LevelsGameModel(view: view!, blockSize: blockSize!, ballRadius: ballRadius!, numberOfRows:
                                    // XXX Workaround while saving state doesn't work
                                    Int(LevelsGameScene.NUM_ROWS), levelNumber: levelCount)
        
        ballCountLabel = SKLabelNode(fontNamed: fontName)
        ballCountLabel!.name = "ballCountLabel"
        
        var ballPosition = CGPoint(x: view!.frame.midX, y: groundNode!.size.height + ballRadius!)
        if gameModel!.isTurnOver() {
            // We're starting a new game
            // The reason we start the game model in a TURN_OVER state for a new game is because in this state
            // the game scene code will add a new row to the scene and animate all items down a row
            displayEncouragement(emoji: "🎬", text: "Action!")
        }
        else {
            print("Game model loaded in an unusual state")
        }
        
        // Update the level count label
        
        let balls = gameModel!.getBalls()
        currentBallCount = balls.count
        prevBallCount = balls.count
        for ball in balls {
            ball.loadItem(position: ballPosition)
            ball.resetBall()
            self.addChild(ball.getNode())
        }
        
        //
        for i in 1...numRowsToStart {
            let row = gameModel!.generateRow()
            addRowToView(rowNum: (numRowsToStart + 1) - i, items: row)
        }
        
        // XXX May need to uncomment this line
        // Addressed in issue #431
        // actionsStarted or animteItems() should only be allowed to be called once and ignored while items are in motion
        // Move the items down in the view
        //animateItems()
    }
    
    // Checks whether or not a point is in the bounds of the game as opposed to the top or bottom margins
    private func inGame(_ point: CGPoint) -> Bool {
        return ((point.y < ceilingNode!.position.y) && (point.y > groundNode!.size.height))
    }
    
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
    
    // Flashes the fast forward image to give the user some feedback about what's happening
    private func flashSpeedupImage() {
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
    
    private func animateItems() {
        actionsStarted = gameModel!.itemGenerator!.getItemCount()
        
        let action = SKAction.moveBy(x: 0, y: -rowHeight!, duration: 1)
        let array = gameModel!.itemGenerator!.itemArray
        
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
        
        gameModel!.itemGenerator!.pruneFirstRow()
    }
    
    private func colorizeBlocks(itemRow: [Item]) {
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
        }
    }
    private func addRowToView(rowNum: Int, items: [Item]) {
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
    
    private func addBallCountLabel() {
        currentBallCount = gameModel!.getBalls().count
        let originPoint = gameModel!.ballManager!.getOriginPoint()
        var newPoint = CGPoint(x: originPoint.x, y: (originPoint.y + (ballRadius! * 1.5)))
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
    
    private func updateBallCountLabel() {
        ballCountLabel!.text = "x\(currentBallCount)"
    }
    
    private func removeBallCountLabel() {
        self.removeChildren(in: [ballCountLabel!])
    }
    
    private func showBallsAcquiredLabel(count: Int) {
        let fontSize = ballRadius! * 2
        let originPoint = gameModel!.ballManager!.getOriginPoint()
        let pos = CGPoint(x: originPoint.x, y: originPoint.y + fontSize)
        let label = SKLabelNode()
        label.text = "+\(count)"
        label.fontSize = fontSize
        label.fontName = fontName
        label.position = pos
        label.alpha = 0
        
        let vect = CGVector(dx: 0, dy: fontSize * 3)
        let action1 = SKAction.fadeIn(withDuration: 0.5)
        let action2 = SKAction.move(by: vect, duration: 1)
        let action3 = SKAction.fadeOut(withDuration: 0.5)
        self.addChild(label)
        label.run(action2)
        label.run(SKAction.sequence([action1, action3])) {
            self.scene!.removeChildren(in: [label])
        }
    }
    
    private func displayEncouragement(emoji: String, text: String) {
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
    
    private func startFlashingRed() {
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
    
    private func stopFlashingRed() {
        if let node = self.childNode(withName: "warningNode") {
            node.run(SKAction.fadeOut(withDuration: 1)) {
                self.removeChildren(in: [node])
                self.displayEncouragement(emoji: "😅", text: "Phew!")
            }
        }
    }
    
    private func breakBlock(color1: SKColor, color2: SKColor, position: CGPoint) {
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
    
    private func ballHitAnimation(color: SKColor, position: CGPoint) {
        let alphas: [CGFloat] = [0.3, 0.4, 0.5, 0.6, 0.7]
        let numDroplets = 8
        var balls: [SKShapeNode] = []
        for _ in 0...(numDroplets - 1) {
            let newPosition = CGPoint(x: position.x + CGFloat(Int.random(in: -10...10)),
                                      y: position.y + CGFloat(Int.random(in: -10...10)))
            let ball = SKShapeNode(circleOfRadius: ballRadius! / 2)
            ball.position = newPosition
            ball.alpha = alphas.randomElement()!
            ball.fillColor = color
            
            let physBody = SKPhysicsBody()
            physBody.affectedByGravity = true
            physBody.isDynamic = true
            ball.physicsBody = physBody
            
            balls.append(ball)
            self.addChild(ball)
        }
        
        for ball in balls {
            let vector = CGVector(dx: CGFloat(Int.random(in: -150...150)), dy: CGFloat(Int.random(in: 200...400)))
            let action1 = SKAction.applyImpulse(vector, duration: 0.1)
            let action2 = SKAction.fadeOut(withDuration: 1)
            ball.run(SKAction.sequence([action1, action2])) {
                self.removeChildren(in: [ball])
            }
        }
    }
}
