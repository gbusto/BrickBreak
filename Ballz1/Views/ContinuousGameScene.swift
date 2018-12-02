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
    
    // MARK: Public properties
    // The game model
    public var gameModel: ContinuousGameModel?
    
    public var gameController: ContinuousGameController?
    
    // MARK: Private properties
    private var colorScheme: GameSceneColorScheme?
    
    // The margin aka the ceiling height and ground height
    private var margin: CGFloat?
    
    // Number of items per row
    private var numItemsPerRow = Int(8)
    
    // The ball radius
    private var ballRadius: CGFloat?
    // The generic item width (typically the view's (width / (number of items per row))
    private var rowHeight: CGFloat?
    // The block size
    private var blockSize: CGSize?
    
    private var ballCountLabelMargin = CGFloat(0.05)
    
    // Nodes that will be shown in the view
    private var groundNode: SKSpriteNode?
    private var ceilingNode: SKShapeNode?
    private var leftWallNode: SKShapeNode?
    private var rightWallNode: SKShapeNode?
    
    // This is essentially the minimum X value for the game play area; if it is zero, it looks like it goes off the left side of the screen; when set to 1 it looks better
    private var leftWallWidth = CGFloat(1)
    private var rightWallWidth = CGFloat(0)
    
    private var ballProjection = BallProjection()
    
    private var fontName: String = "HelveticaNeue"
    private var topColor: UIColor = .black
    private var bottomColor: UIColor = .white
    // true if we changed colors recently
    private var changedColor: Bool = false
    // The column index because to keep track of which blocks are in transition
    private var itemColumn = Int(0)
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
    
    // Ball count label
    private var ballCountLabel: SKLabelNode?
    private var prevBallCount = Int(0)
    private var currentBallCount = Int(0)
    
    // A counter for each time update is called
    private var numTicks = Int(0)
    // The number of update ticks to wait before shooting another ball
    private var ticksDelay = Int(6)
    
    // Variables for handling swipe gestures
    private var rightSwipeGesture: UISwipeGestureRecognizer?
    private var downSwipeGesture: UISwipeGestureRecognizer?
    private var addedGesture = false
    private var swipedDown = false
    
    private var arrowIsShowing = false
    
    private var actionsStarted = Int(0)
    
    // Colors for the scene
    private var sceneColor = UIColor.init(red: 20/255, green: 20/255, blue: 20/255, alpha: 1)
    private var marginColor = UIColor.init(red: 50/255, green: 50/255, blue: 50/255, alpha: 1)
    
    private var blockColor = Color()
    
    // This is to keep track of the number of broken hit blocks in a given turn
    private var brokenHitBlockCount: Int = 0
    // A boolean because we only want to show the "on fire" encouragement once per turn
    private var displayedOnFire: Bool = false
    // This is the number of blocks that need to be broken in a given turn to get the "on fire" encouragement
    private static var ON_FIRE_COUNT: Int = 8
    
    // Stuff for collisions
    private var categoryBitMask = UInt32(0b0001)
    private var contactTestBitMask = UInt32(0b0001)
    private var groundCategoryBitmask = UInt32(0b0101)
    
    // Stuff for lighting
    private var lightingBitMask = UInt32(0b0001)
    
    private static var NUM_ROWS = CGFloat(12)
    private static var NUM_COLUMNS = CGFloat(8)
    
    private var startTime = TimeInterval(0)
    
    private var activeViews: [UIView] = []
    
    enum Tutorials {
        case noTutorial
        case gameplayTutorial
        case topBarTutorial
        case fastForwardTutorial
        case ballReturnTutorial
    }
    
    private var tutorialIsShowing = false
    private var tutorialNodes: [SKNode] = []
    private var tutorialType: Tutorials?
    private var tutorialsList: [Tutorials] = [.gameplayTutorial,
                                              .topBarTutorial,
                                              .fastForwardTutorial,
                                              .ballReturnTutorial]
    
    
    // MARK: Override functions
    override func didMove(to view: SKView) {
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
        let blockSize1 = (ceilingY - groundY) / ContinousGameScene.NUM_ROWS
        let blockSize2 = view.frame.width / ContinousGameScene.NUM_COLUMNS
        // Need to determine whether or not we use screen height or width to determine block size
        if (blockSize1 * ContinousGameScene.NUM_COLUMNS) > view.frame.width {
            // We use block width as block size and move ceiling/ground in towards the middle
            blockSize = CGSize(width: blockSize2 * 0.95, height: blockSize2 * 0.95)
            rowHeight = blockSize2
            // Update margin for ceiling/ground here
            // (margin * 2) because there's the ceiling margin and ground margin
            let heightDifference = (view.frame.height - (margin! * 2)) - (blockSize2 * ContinousGameScene.NUM_ROWS)
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
        
        initWalls(view: view)
        initGameModel()
        
        rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleRightSwipe(_:)))
        rightSwipeGesture!.direction = .right
        rightSwipeGesture!.numberOfTouchesRequired = 1
        
        downSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleDownSwipe(_:)))
        downSwipeGesture!.direction = .down
        downSwipeGesture!.numberOfTouchesRequired = 1
        
        showTutorial(tutorial: .gameplayTutorial)
        
        self.backgroundColor = colorScheme!.backgroundColor
        
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
            
            if gameModel!.isGameOver() {
                gameModel!.saveState()
                handleGameOver()
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
                
                if tutorialIsShowing && tutorialType == .gameplayTutorial {
                    removeTutorial()
                }
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
            
            // Get the newly generated items and add them to the view
            let items = gameModel!.generateRow()
            addRowToView(rowNum: 1, items: items)
            
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
            updateScore(highScore: gameModel!.highScore, gameScore: gameModel!.gameScore)
            
            // Reset the number of hit blocks and the encouragements shown to the user
            brokenHitBlockCount = 0
            displayedOnFire = false
            
            // Reset start time to 0
            startTime = 0
            
            // If the user didn't fast forward and the tutorial is still showing, remove it and add it back to the list until the user actually performs the action
            if tutorialIsShowing && tutorialType == .fastForwardTutorial {
                removeTutorial()
                tutorialsList.append(.fastForwardTutorial)
            }
                // Same applies for the ball return tutorial
            else if tutorialIsShowing && tutorialType == .ballReturnTutorial {
                removeTutorial()
                tutorialsList.append(.ballReturnTutorial)
            }
        }
        
        // After the turn over, wait for the game logic to decide whether or not the user is about to lose or has lost
        if gameModel!.isWaiting() {
            if 0 == actionsStarted {
                // Increment game model state from WAITING to READY
                gameModel!.incrementState()
                
                // Check to see if the game ended after all animations are complete
                if gameModel!.gameOver() {
                    // If the game is over, the game model will change its state to GAME_OVER
                    
                    // If the user hasn't been saved yet, allow them to be saved
                    if false == gameModel!.userWasSaved {
                        // Display Continue? graphic
                        showContinueButton()
                        // Show an ad
                    }
                    else {
                        view!.isPaused = true
                        // Otherwise show the gameover overlay
                        showGameOverNode()
                    }
                }
                // Check to see if we are at risk of losing the game
                else if gameModel!.lossRisk() {
                    // Flash notification to user
                    startFlashingRed()
                }
                else {
                    stopFlashingRed()
                }
            }
            
            // Depending on whether or not a new turn has been saved, enable the undo button
            // We check for this in the WAITING state because this is the state we come back to after undoing a turn
            if gameModel!.prevTurnSaved {
                enableUndoButton()
            }
            else {
                disableUndoButton()
            }
        }
        
        if gameModel!.isReady() {
            if false == tutorialIsShowing && tutorialsList.count > 0 {
                showTutorial(tutorial: .topBarTutorial)
            }
        }
        
        // Actions to perform while in the middle of a turn
        if gameModel!.isMidTurn() {
            if startTime == 0 {
                startTime = currentTime
            }
            
            // If the user's turn has gone on longer than 10 seconds and there are still tutorials to show, we want to show them how to fast forward
            if (Int(currentTime) - Int(startTime)) > 10 && tutorialsList.count > 0 {
                // Only show it if the user hasn't fast forwarded yet
                if false == tutorialIsShowing && physicsWorld.speed == 1.0 {
                    showTutorial(tutorial: .fastForwardTutorial)
                }
            }
            
            // If the user is beyond turn 5 and there are tutorials to show, show them the ball return tutorial
            if gameModel!.gameScore > 5 && tutorialsList.count > 0 && false == tutorialIsShowing {
                showTutorial(tutorial: .ballReturnTutorial)
            }
            
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
                    //let newPoint = CGPoint(x: item.getNode().position.x, y: groundNode!.size.height + ballRadius!)
                    let vector = CGVector(dx: 0, dy: ballRadius! * 0.5)
                    let ball = item.getNode()
                    ball.physicsBody!.affectedByGravity = true
                    ball.run(SKAction.applyImpulse(vector, duration: 0.05))
                    ballHitAnimation(color: colorScheme!.hitBallColor, position: ball.position)
                }
            }
            
            // If the user has broken greater than X blocks this turn, they get an "on fire" encouragement
            if brokenHitBlockCount > ContinousGameScene.ON_FIRE_COUNT && (false == displayedOnFire) {
                // Display the on fire encouragement
                displayEncouragement(emoji: "🔥", text: "On fire!")
                displayedOnFire = true
            }
        }
    }
    
    public func saveState() {
        print("Saving game state")
        gameModel!.saveState()
    }
    
    public func endGame() {
        gameModel!.saveState()
        handleGameOver()
    }
    
    // Save the user from losing a game by clearing out the row that's about to end the game
    public func saveUser() {
        let fadeOut = SKAction.fadeOut(withDuration: 1)
        let items = gameModel!.saveUser()
        for item in items {
            if item is SpacerItem {
                continue
            }
            
            item.getNode().run(fadeOut) {
                self.removeChildren(in: [item.getNode()])
            }
        }
        
        displayEncouragement(emoji: "🤞", text: "Last chance!")
        
        // If the user isn't at risk of losing right now then stop flashing red
        if false == gameModel!.lossRisk() {
            stopFlashingRed()
        }
    }
    
    public func loadPreviousTurnState() {
        // Prevent the user from undoing a turn in the middle of a turn
        if false == gameModel!.isReady() {
            return
        }
        
        // Get the old item array so we can remove all of those items
        let oldItemArray = gameModel!.itemGenerator!.itemArray
        // Get the old ball array so we can remove all of them
        let oldBallArray = gameModel!.ballManager!.ballArray
        
        // Tell the item generator and game model to prepare the new item array
        let success = gameModel!.loadPreviousTurnState()
        
        if false == success {
            print("Can't load previous turn")
            return
        }
        
        // Remove all the current item generator nodes from the screen
        for row in oldItemArray {
            for item in row {
                if item is SpacerItem {
                    continue
                }
                let node = item.getNode()
                self.removeChildren(in: [node])
            }
        }
        
        for ball in oldBallArray {
            self.removeChildren(in: [ball.getNode()])
        }
        
        // Load the new ones on the screen (at this point the itemArray should have the previous state of items)
        let itemArray = gameModel!.itemGenerator!.itemArray
        var count = itemArray.count
        for row in itemArray {
            // Add the rows to the view
            addRowToView(rowNum: count, items: row)
            count -= 1
        }
        
        // Move the items down in the view
        animateItems()
        
        // At this point the ball manager's state should be updated; update the view to reflect that
        let balls = gameModel!.getBalls()
        let ballPosition = gameModel!.ballManager!.getOriginPoint()
        currentBallCount = balls.count
        prevBallCount = balls.count
        for ball in balls {
            ball.loadItem(position: ballPosition)
            ball.resetBall()
            self.addChild(ball.getNode())
        }
        removeBallCountLabel()
        addBallCountLabel()
        
        // Update the score labels
        updateScore(highScore: gameModel!.highScore, gameScore: gameModel!.gameScore)
        
        // Game model resets its state to WAITING so that the game checks loss risk or game over
    }
    
    public func showPauseScreen() {
        // Remove the top bar tutorial if it is showing
        if tutorialType == .topBarTutorial {
            removeTutorial()
        }
        
        let blur = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blur)
        blurView.frame = view!.frame
        view!.addSubview(blurView)
        
        let pauseView = gameController!.getPauseMenu()
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
    
    // MARK: Public functions
    // Handle a right swipe to fast forward
    @objc public func handleRightSwipe(_ sender: UISwipeGestureRecognizer) {
        let point = sender.location(in: view!)
        
        if inGame(point) {
            if gameModel!.isMidTurn() {
                // Check if the fast forward tutorial is showing; if it is then remove it
                if tutorialIsShowing && tutorialType == .fastForwardTutorial {
                    removeTutorial()
                }
                
                // Otherwise if the user swiped right to fast forward, they know how to do it so we don't need to show them the tutorial; remove it from the list
                else if tutorialsList.count > 0 {
                    let remainingTutorials = tutorialsList.filter {
                        if $0 == .fastForwardTutorial {
                            return false
                        }
                        return true
                    }
                    tutorialsList = remainingTutorials
                }
                
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
            // CHeck if the ball return tutorial is showing
            if tutorialIsShowing && tutorialType == .ballReturnTutorial {
                removeTutorial()
            }
            
            // Otherwise, if the user swiped down then they probably know how to do it so we don't need to show them the tutorial; remove it from the list
            else if tutorialsList.count > 0 {
                let remainingTutorials = tutorialsList.filter {
                    if $0 == .ballReturnTutorial {
                        return false
                    }
                    return true
                }
                tutorialsList = remainingTutorials
            }
            
            if gameModel!.isMidTurn() {
                swipedDown = true
            }
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
                else if (i == 0) && (array.count == Int(ContinousGameScene.NUM_ROWS - 1)) {
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
        //let color = blockColor.changeColor()
        
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
    
    // Initialize the game model (this is where the code for loading a saved game model will go)
    private func initGameModel() {
        // The controller also needs a copy of this game model object
        gameModel = ContinuousGameModel(view: view!, blockSize: blockSize!, ballRadius: ballRadius!, numberOfRows: Int(ContinousGameScene.NUM_ROWS))
        
        // Initialize the ball count label
        ballCountLabel = SKLabelNode(fontNamed: fontName)
        ballCountLabel!.name = "ballCountLabel"
        
        // Add the balls to the scene
        var ballPosition = CGPoint(x: view!.frame.midX, y: groundNode!.size.height + ballRadius!)
        if gameModel!.isWaiting() {
            // This means we loaded a saved game state so get the origin point
            // The reason we load the game model in a WAITING state after loading a game is because during the WAITING state we:
            // 1. Check if we're about to lose
            // 2. Check if the game is over
            // And we want to re-warn the user that they're about to lose if they are one row away from a game over
            ballPosition = gameModel!.ballManager!.getOriginPoint()
            addBallCountLabel()
        }
        else if gameModel!.isTurnOver() {
            // We're starting a new game
            // The reason we start the game model in a TURN_OVER state for a new game is because in this state
            // the game scene code will add a new row to the scene and animate all items down a row
            displayEncouragement(emoji: "🎬", text: "Action!")
        }
        else {
            print("Game model loaded in an unusual state")
        }
        
        updateScore(highScore: gameModel!.highScore, gameScore: gameModel!.gameScore)
        
        let balls = gameModel!.getBalls()
        currentBallCount = balls.count
        prevBallCount = balls.count
        for ball in balls {
            ball.loadItem(position: ballPosition)
            ball.resetBall()
            self.addChild(ball.getNode())
        }
        
        let itemArray = gameModel!.itemGenerator!.itemArray
        var count = itemArray.count
        for row in itemArray {
            addRowToView(rowNum: count, items: row)
            count -= 1
        }
        
        // Move the items down in the view
        animateItems()
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
        leftWallNode!.zPosition = 101
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
        rightWallNode!.zPosition = 101
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
    
    private func updateScore(highScore: Int, gameScore: Int) {
        if let controller = gameController {
            controller.updateScore(gameScore: gameScore, highScore: highScore)
        }
        else {
            print("gameController variable not set; can't update score")
            return
        }
        
        /*
         'Cheers! 🍻' - 1000
         'Magical 🎩' - 900
         'Rock star! 🎸' - 800
         'Cruisin 🛳' - 700
         'Sick 🤒' - 600
         'You're a star 🤩' - 500
         'Killin it! 😵' - 400
         'Awesome 👍' - 300
         'Pretty slick 😏' - 200
         'Cool dude 😎' - 100
         'Piece of cake 🎂' - 50
         'New high score! 🍾' - for a new high score
         'Action! 🎬' - Starting a new game
         'Phew! Close one 😅' - After saving yourself from a loss (aka more than one row away from losing after almost losing)
         'Careful! 😬' - Before you lose
        */
        if 50 == gameScore {
            displayEncouragement(emoji: "🎂", text: "Piece of cake")
        }
        else if 100 == gameScore {
            displayEncouragement(emoji: "😎", text: "Cool, dude")
        }
        else if 200 == gameScore {
            displayEncouragement(emoji: "😏", text: "Pretty slick")
        }
        else if 300 == gameScore {
            displayEncouragement(emoji: "👍", text: "Awesome!")
        }
        else if 400 == gameScore {
            displayEncouragement(emoji: "😵", text: "Killin it!")
        }
        else if 500 == gameScore {
            displayEncouragement(emoji: "🤩", text: "You're a star")
        }
        else if 600 == gameScore {
            displayEncouragement(emoji: "🤒", text: "Sick!")
        }
        else if 700 == gameScore {
            displayEncouragement(emoji: "🛳", text: "Cruisin")
        }
        else if 800 == gameScore {
            displayEncouragement(emoji: "🎸", text: "Rock star")
        }
        else if 900 == gameScore {
            displayEncouragement(emoji: "🎩", text: "Magical!")
        }
        else if 1000 == gameScore {
            displayEncouragement(emoji: "🍻", text: "Cheers!")
        }
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
    
    // Shows the user how to play the game
    private func showGameplayTutorial() {
        let offsetFromCenter = view!.frame.width * 0.2
        let centerPoint = CGPoint(x: view!.frame.midX, y: view!.frame.midY)
        let startPoint = CGPoint(x: view!.frame.midX - offsetFromCenter, y: view!.frame.midY)
        let endPoint = CGPoint(x: view!.frame.midX + offsetFromCenter, y: view!.frame.midY)
        
        let pointerNode = SKSpriteNode(imageNamed: "hand_pointing")
        pointerNode.size = CGSize(width: 40, height: 50)
        pointerNode.position = startPoint
        pointerNode.zPosition = 105

        let labelNode = SKLabelNode(fontNamed: colorScheme!.fontName)
        labelNode.fontColor = .white
        labelNode.fontSize = 20
        labelNode.position = CGPoint(x: centerPoint.x, y: centerPoint.y - 50)
        labelNode.text = "Press, Aim, Release"
        labelNode.numberOfLines = 2
        labelNode.horizontalAlignmentMode = .center
        labelNode.verticalAlignmentMode = .center
        labelNode.zPosition = 105
        
        let action1 = SKAction.move(to: endPoint, duration: 1)
        let action2 = SKAction.move(to: startPoint, duration: 1)
        let moveAction = SKAction.repeatForever(SKAction.sequence([action1, action2]))
        pointerNode.run(moveAction)

        self.addChild(pointerNode)
        self.addChild(labelNode)
        
        tutorialNodes.append(pointerNode)
        tutorialNodes.append(labelNode)
        
        tutorialIsShowing = true
        
        tutorialType = .gameplayTutorial
    }
    
    // Show the user the top bar tutorial
    private func showTopBarTutorial() {
        let pointerNode = SKSpriteNode(imageNamed: "hand_pointing")
        pointerNode.size = CGSize(width: 40, height: 50)
        pointerNode.zPosition = 105
        pointerNode.position = CGPoint(x: view!.frame.midX + 80, y: ceilingNode!.position.y + 10)
        
        let labelNode = SKLabelNode(fontNamed: colorScheme!.fontName)
        labelNode.zPosition = 105
        labelNode.fontColor = .white
        labelNode.fontSize = 20
        labelNode.position = CGPoint(x: pointerNode.position.x, y: pointerNode.position.y - 50)
        labelNode.text = "Tap Here to Pause"
        labelNode.numberOfLines = 2
        labelNode.horizontalAlignmentMode = .center
        labelNode.verticalAlignmentMode = .center
        
        //let rect1 = CGRect(x: leftWallWidth, y: margin! / 2, width: 100, height: 50)
        let highScoreHelper = SKLabelNode(fontNamed: colorScheme!.fontName)
        highScoreHelper.zPosition = 105
        highScoreHelper.text = "Best"
        highScoreHelper.position = CGPoint(x: leftWallWidth, y: ceilingNode!.position.y + 10)
        highScoreHelper.fontColor = .white
        highScoreHelper.verticalAlignmentMode = .center
        highScoreHelper.horizontalAlignmentMode = .left
        highScoreHelper.fontSize = 20
        highScoreHelper.numberOfLines = 1
        
        //let rect2 = CGRect(x: view!.frame.midX - 50, y: margin! / 2, width: 100, height: 50)
        let gameScoreHelper = SKLabelNode(fontNamed: colorScheme!.fontName)
        gameScoreHelper.zPosition = 105
        gameScoreHelper.text = "Score"
        gameScoreHelper.position = CGPoint(x: view!.frame.midX, y: ceilingNode!.position.y + 10)
        gameScoreHelper.fontColor = .white
        gameScoreHelper.verticalAlignmentMode = .center
        gameScoreHelper.horizontalAlignmentMode = .center
        gameScoreHelper.fontSize = 20
        gameScoreHelper.numberOfLines = 1
        
        //let rect3 = CGRect(x: view!.frame.width - rightWallWidth - 100, y: margin! / 2, width: 100, height: 50)
        let undoHelper = SKLabelNode(fontNamed: colorScheme!.fontName)
        undoHelper.zPosition = 105
        undoHelper.text = "Undo"
        undoHelper.position = CGPoint(x: view!.frame.width - rightWallWidth, y: ceilingNode!.position.y + 10)
        undoHelper.fontColor = .white
        undoHelper.verticalAlignmentMode = .center
        undoHelper.horizontalAlignmentMode = .right
        undoHelper.fontSize = 20
        undoHelper.numberOfLines = 1
        
        let nodes = [pointerNode, labelNode, highScoreHelper, gameScoreHelper, undoHelper]
        
        let action1 = SKAction.fadeOut(withDuration: 1)
        let action2 = SKAction.fadeIn(withDuration: 1)
        let blinkAction = SKAction.repeatForever(SKAction.sequence([action1, action2]))
        
        for node in nodes {
            node.run(blinkAction)
            tutorialNodes.append(node)
            self.addChild(node)
        }
        
        tutorialIsShowing = true
        
        tutorialType = .topBarTutorial
    }
    
    private func showFastForwardTutorial() {
        let offsetFromCenter = view!.frame.width * 0.2
        let centerPoint = CGPoint(x: view!.frame.midX, y: view!.frame.midY)
        let startPoint = CGPoint(x: view!.frame.midX - offsetFromCenter, y: view!.frame.midY)
        let endPoint = CGPoint(x: view!.frame.midX + offsetFromCenter, y: view!.frame.midY)
        
        let pointerNode = SKSpriteNode(imageNamed: "hand_pointing")
        pointerNode.size = CGSize(width: 40, height: 50)
        pointerNode.position = startPoint
        pointerNode.zPosition = 105
        
        let labelNode = SKLabelNode(fontNamed: colorScheme!.fontName)
        labelNode.fontColor = .white
        labelNode.fontSize = 20
        labelNode.position = CGPoint(x: centerPoint.x, y: centerPoint.y - 50)
        labelNode.text = "Swipe Right to Fast Forward"
        labelNode.numberOfLines = 2
        labelNode.horizontalAlignmentMode = .center
        labelNode.verticalAlignmentMode = .center
        labelNode.zPosition = 105
        
        let action1 = SKAction.move(to: endPoint, duration: 1)
        let action2 = SKAction.fadeOut(withDuration: 0.1)
        let action3 = SKAction.move(to: startPoint, duration: 0.1)
        let action4 = SKAction.fadeIn(withDuration: 0.05)
        let moveAction = SKAction.repeatForever(SKAction.sequence([action1, action2, action3, action4]))
        pointerNode.run(moveAction)
        
        self.addChild(pointerNode)
        self.addChild(labelNode)
        
        tutorialNodes.append(pointerNode)
        tutorialNodes.append(labelNode)
        
        tutorialIsShowing = true
        
        tutorialType = .fastForwardTutorial
    }
    
    private func showBallReturnTutorial() {
        let offsetFromCenter = view!.frame.height * 0.2
        let centerPoint = CGPoint(x: view!.frame.midX, y: view!.frame.midY)
        let startPoint = CGPoint(x: view!.frame.midX, y: view!.frame.midY + offsetFromCenter)
        let endPoint = CGPoint(x: view!.frame.midX, y: view!.frame.midY)
        
        let pointerNode = SKSpriteNode(imageNamed: "hand_pointing")
        pointerNode.size = CGSize(width: 40, height: 50)
        pointerNode.position = startPoint
        pointerNode.zPosition = 105
        
        let labelNode = SKLabelNode(fontNamed: colorScheme!.fontName)
        labelNode.fontColor = .white
        labelNode.fontSize = 20
        labelNode.position = CGPoint(x: centerPoint.x, y: centerPoint.y - 50)
        labelNode.text = "Swipe Down to Force Ball Return"
        labelNode.numberOfLines = 2
        labelNode.horizontalAlignmentMode = .center
        labelNode.verticalAlignmentMode = .center
        labelNode.zPosition = 105
        
        let action1 = SKAction.move(to: endPoint, duration: 1)
        let action2 = SKAction.fadeOut(withDuration: 0.1)
        let action3 = SKAction.move(to: startPoint, duration: 0.1)
        let action4 = SKAction.fadeIn(withDuration: 0.05)
        let moveAction = SKAction.repeatForever(SKAction.sequence([action1, action2, action3, action4]))
        pointerNode.run(moveAction)
        
        self.addChild(pointerNode)
        self.addChild(labelNode)
        
        tutorialNodes.append(pointerNode)
        tutorialNodes.append(labelNode)
        
        tutorialIsShowing = true
        
        tutorialType = .ballReturnTutorial
    }
    
    private func showTutorial(tutorial: Tutorials) {
        let remainingTutorials = tutorialsList.filter {
            // If the current item matches the tutorial type, handle it
            if $0 == tutorial {
                if tutorial == .gameplayTutorial {
                    showGameplayTutorial()
                    return false
                }
                else if tutorial == .topBarTutorial {
                    showTopBarTutorial()
                    return false
                }
                else if tutorial == .fastForwardTutorial {
                    showFastForwardTutorial()
                    return false
                }
                else if tutorial == .ballReturnTutorial {
                    showBallReturnTutorial()
                    return false
                }
                return false
            }
            return true
        }
        tutorialsList = remainingTutorials
    }
    
    private func removeTutorial() {
        if tutorialIsShowing {
            tutorialIsShowing = false
            let nodeList = tutorialNodes.filter {
                $0.removeFromParent()
                return false
            }
            tutorialNodes = nodeList
        }
        tutorialType = .noTutorial
    }
    
    public func isGameOverShowing() -> Bool {
        // If a child node with name "gameOver" is showing, return true
        if let _ = self.childNode(withName: "gameOver") {
            return true
        }
        
        // Otherwise return false
        return false
    }
    
    // Shows the game over overlay
    public func showGameOverNode() {
        let gameOverNode = SKSpriteNode(color: .darkGray, size: scene!.size)
        gameOverNode.name = "gameOver"
        gameOverNode.alpha = 0.9
        gameOverNode.zPosition = 105
        gameOverNode.position = CGPoint(x: 0, y: 0)
        gameOverNode.anchorPoint = CGPoint(x: 0, y: 0)
        self.addChild(gameOverNode)
        
        let fontSize = view!.frame.width * 0.3
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
    
    private func addBallCountLabel() {
        currentBallCount = gameModel!.getBalls().count
        let originPoint = gameModel!.ballManager!.getOriginPoint()
        var newPoint = CGPoint(x: originPoint.x, y: (originPoint.y + (ballRadius! * 1.5)))
        // This is to prevent the ball count label from going off the screen
        if newPoint.x < view!.frame.width * ballCountLabelMargin {
            // If we're close to the far left side, add a small amount to the x value
            newPoint.x += view!.frame.width * 0.03
        }
        else if newPoint.x > view!.frame.width * (1.0 - ballCountLabelMargin) {
            // Opposite of the above comment
            newPoint.x -= view!.frame.width * 0.03
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
    
    private func handleGameOver() {
        if let controller = gameController {
            controller.handleGameOver()
        }
        else {
            print("gameController variable not set; can't handle game over tap")
        }
    }
    
    private func showContinueButton() {
        if let controller = gameController {
            controller.showContinueButton()
        }
        else {
            print("gameController variable not set; can't show continue button")
        }
    }
    
    private func enableUndoButton() {
        if let controller = gameController {
            controller.enableUndoButton()
        }
        else {
            print("gameController variable not set; can't enable undo button")
        }
    }
    
    private func disableUndoButton() {
        if let controller = gameController {
            controller.disableUndoButton()
        }
        else {
            print("gameController variable not set; can't disable undo button")
        }
    }
    
    private func displayEncouragement(emoji: String, text: String) {
        let label = SKLabelNode()
        label.text = emoji
        label.fontSize = view!.frame.width * 0.3
        label.alpha = 0
        label.position = CGPoint(x: view!.frame.midX, y: view!.frame.midY)
        label.zPosition = 105
        
        let text = SKLabelNode(text: text)
        text.fontSize = label.fontSize / 2
        text.fontName = fontName
        text.alpha = 0
        text.position = CGPoint(x: view!.frame.midX, y: label.position.y - (text.fontSize * 1.5))
        text.zPosition = 105
        text.fontColor = .white
        
        let action1 = SKAction.fadeIn(withDuration: 1)
        let action2 = SKAction.wait(forDuration: 1)
        let action3 = SKAction.fadeOut(withDuration: 1)
        label.run(SKAction.sequence([action1, action2, action3])) {
            self.removeChildren(in: [label])
        }
        text.run(SKAction.sequence([action1, action2, action3])) {
            self.removeChildren(in: [text])
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
