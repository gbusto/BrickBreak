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

class ContinousGameScene: GameScene {
    
    // MARK: Public properties
    // The game model
    public var gameModel: ContinuousGameModel?
    
    public var gameController: ContinuousGameController?

    // MARK: Private properties
    // Number of items per row
    private var numItemsPerRow = Int(8)
    
    private var lastUndoTurnScore = 0
    static private var MAX_TURNS_FORCE_UNDO = Int(5)
    
    private var ballProjection = BallProjection()
    
    // Ball count label
    private var prevBallCount = Int(0)
    
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
    
    // A boolean that says whether or not we're showing encouragement (emoji + text) on the screen
    private var showingEncouragement = false
        
    // This is to keep track of the number of broken hit blocks in a given turn
    private var brokenHitBlockCount: Int = 0
    // A boolean because we only want to show the "on fire" encouragement once per turn
    private var displayedOnFire: Bool = false
    // This is the number of blocks that need to be broken in a given turn to get the "on fire" encouragement
    private static var ON_FIRE_COUNT: Int = 8
    
    // XXX Maybe remove
    // Stuff for lighting
    private var lightingBitMask = UInt32(0b0001)
    
    private var startTime = TimeInterval(0)
    
    enum Tutorials {
        case noTutorial
        case gameplayTutorial
        case topBarTutorial
        case fastForwardTutorial
    }
    
    private var tutorialIsShowing = false
    private var tutorialNodes: [SKNode] = []
    private var tutorialType: Tutorials?
    private var tutorialsList: [Tutorials] = []
    
    private var mysteryBlocksToBreak: [(Item, Int, Int)] = []
    
    static var DEFAULT_NUM_BALLS = Int(10)
    
    private var prevBallState = DataManager.BallManagerState(numberOfBalls: 0, originPoint: CGPoint(x: 0, y: 0))
    private var newBallArray: [BallItem] = []
    
    // MARK: Override functions
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        initGameModel()
        
        if gameModel!.userWasSaved {
            gameController!.userWasSaved()
        }
        
        rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleRightSwipe(_:)))
        rightSwipeGesture!.direction = .right
        rightSwipeGesture!.numberOfTouchesRequired = 1
        
        downSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleDownSwipe(_:)))
        downSwipeGesture!.direction = .down
        downSwipeGesture!.numberOfTouchesRequired = 1
        
        // If we haven't showed the user the tutorials then show them
        if false == gameModel!.showedTutorials {
            tutorialsList = [.gameplayTutorial,
                             .topBarTutorial,
                             .fastForwardTutorial]
            showTutorial(tutorial: .gameplayTutorial)
        }
        
        physicsWorld.contactDelegate = self
    }
    
    // MVC: A view function; notifies the controller of contact between two bodies
    func didBegin(_ contact: SKPhysicsContact) {
        let nameA = contact.bodyA.node?.name!
        let nameB = contact.bodyB.node?.name!
        
        // Don't need to handle cases where a ball makes contact with a ceiling or a wall... just ignore it
        if ("wall" == nameA! || "wall" == nameB!) || ("ceiling" == nameA! || "ceiling" == nameB!) {
            return
        }
        
        // Handle the case where nameA is a ball and it hit the ground
        if nameA!.starts(with: "bm") && "ground" == nameB! {
            print("Ball \(nameA!) made contact with ground")
            // XXX TEST THIS OUT
            let _ = ballArray.filter {
                if $0.getNode().name! == nameA! {
                    self.stoppedBalls.append($0)
                    $0.stop()
                }
                return true
            }
            // Bail out because we don't need to continue
            return
        }
        
        // Same as the case above; handle the case where a ball hit the ground
        if nameB!.starts(with: "bm") && "ground" == nameA! {
            // XXX TEST THIS OUT
            let _ = ballArray.filter {
                if $0.getNode().name! == nameB! {
                    self.stoppedBalls.append($0)
                    $0.stop()
                }
                return true
            }
            // Bail out because we don't need to continue
            return
        }
        
        // Allow the game model to do whatever it needs with this collision; mainly to update the score
        gameModel!.handleContact(nameA: nameA!, nameB: nameB!)
    }
    
    // MVC: View detects the touch; the code in this function should notify the GameSceneController to handle this event
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let point = touch.location(in: self)
         
            if gameModel!.isReady() {
                // Show the arrow and update it
                if inGame(point) && (false == self.isPaused) {
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
                let firePoint = ballProjection.updateArrow(startPoint: originPoint,
                                                           touchPoint: point,
                                                           ceilingHeight: ceilingNode!.position.y,
                                                           groundHeight: groundNode!.size.height)
                shootBalls(point: firePoint)
                
                // Disable the undo button when the user is in the middle of a turn
                disableUndoButton()
                
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
    
    // MARK: After physics simulation step
    override func didSimulatePhysics() {
        // We want to check the balls after each simulation step to ensure it never reaches a completely horizontal or vertical angle
        for ball in ballArray {
            if false == ball.isResting {
                let dx = ball.getNode().physicsBody!.velocity.dx
                let dy = ball.getNode().physicsBody!.velocity.dy
                let negativeDelta = CGFloat(-2)
                let positiveDelta = CGFloat(2)
                if (dx < positiveDelta && dx > negativeDelta) {
                    // Correct the velocity's X delta to a minimum value
                    if dx < 0 {
                        ball.getNode().physicsBody!.applyImpulse(CGVector(dx: -0.5, dy: 0))
                    }
                    else {
                        ball.getNode().physicsBody!.applyImpulse(CGVector(dx: 0.5, dy: 0))
                    }
                }
                if (dy < positiveDelta && dy > negativeDelta) {
                    // Correct the velocity's Y delta to a minimum value
                    if dy < 0 {
                        ball.getNode().physicsBody!.applyImpulse(CGVector(dx: 0, dy: -0.5))
                    }
                    else {
                        ball.getNode().physicsBody!.applyImpulse(CGVector(dx: 0, dy: 0.5))
                    }
                }
                
                if isOutOfBounds(ballPosition: ball.getNode().position) {
                    ball.outOfBounds = true
                }
            }
        }
    }
    
    // MARK: Scene update
    override func update(_ currentTime: TimeInterval) {
        if gameModel!.isTurnOver() {
            endTurn = false
            
            numBallsFired = 0
            
            firedAllBalls = false
            
            ballsOnFire = false
            
            firstBallReturned = false
            
            // Return the fireDelay to the default
            fireDelay = GameScene.DEFAULT_FIRE_DELAY
            
            // Return physics simulation to normal speed
            physicsWorld.speed = 1.0
            
            // Reset the tick delay for firing balls
            ticksDelay = 6
            
            // Clear gesture recognizers in the view
            view!.gestureRecognizers = []
            addedGesture = false
            
            // Tell the game model to update now that the turn has ended
            gameModel!.handleTurnOver()
            clearNewBallArray()
            
            // Get the newly generated items and add them to the view
            let items = gameModel!.generateRow()
            addRowToView(rowNum: 1, items: items)
            
            // Break any mystery blocks at this point (at the end of the turn but before we animate any items)
            let _ = mysteryBlocksToBreak.filter {
                // Get the new items to display from the ItemGenerator
                let block = $0.0 as! MysteryBlockItem
                // Add the reward item to the view if we were successfully able to create it and insert into the row of items
                if let rewardItem = gameModel!.itemGenerator!.insertRewardItem(at: ($0.1, $0.2), rewardType: block.getReward()) {
                    addItemToView(item: rewardItem, at: block.getNode().position)
                }
                // Remove the mystery block from the game
                self.removeChildren(in: [block.getNode()])
                var centerPoint = block.getNode().position
                centerPoint.x += blockSize!.width / 2
                centerPoint.y += blockSize!.height / 2
                // Show to block break animation
                breakBlock(color1: block.bottomColor!, color2: block.topColor!, position: centerPoint)
                
                return false
            }
            mysteryBlocksToBreak = []
            
            // Move the items down in the view
            animateItems(numItems: gameModel!.itemGenerator!.getItemCount(), array: gameModel!.itemGenerator!.itemArray)
            gameModel!.itemGenerator!.pruneFirstRow()
            
            // Display the label showing how many balls the user has (this needs to be done after we have collected any new balls the user acquired)
            currentBallCount = ballArray.count
            // See if the user acquired any new balls
            let diff = currentBallCount - prevBallCount
            if diff > 0 {
                // Show a floating label saying how many balls the user acquired that turn
                showBallsAcquiredLabel(count: diff)
            }
            // Update the previous ball count to the current count so that next time around we can see if the user acquired more balls
            prevBallCount = currentBallCount
            addBallCountLabel(position: originPoint, ballCount: ballArray.count)
            
            // Check the model to update the score label
            updateScore(highScore: gameModel!.highScore, gameScore: gameModel!.gameScore)
            
            // Reset the number of hit blocks and the encouragements shown to the user
            brokenHitBlockCount = 0
            displayedOnFire = false
            
            // Reset start time to 0
            startTime = 0
            
            // XXX Remove these tutorial lines
            // If the user didn't fast forward and the tutorial is still showing, remove it and add it back to the list until the user actually performs the action
            if tutorialIsShowing && tutorialType == .fastForwardTutorial {
                removeTutorial()
                tutorialsList.append(.fastForwardTutorial)
            }
        }
        
        // After the turn over, wait for the game logic to decide whether or not the user is about to lose or has lost
        if gameModel!.isWaiting() {
            if doneAnimatingItems() {
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
                        self.endGame()
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
            // XXX Remove this tutorial tracking code
            if false == tutorialIsShowing && tutorialsList.count > 0 {
                showTutorial(tutorial: .topBarTutorial)
            }
            
            // Reset this list to empty
            stoppedBalls = []
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
            
            if false == addedGesture {
                // Ask the model if we showed the fast forward tutorial
                view!.gestureRecognizers = [rightSwipeGesture!, downSwipeGesture!]
                addedGesture = true
            }
            
            if swipedDown {
                // Handle ball return gesture
                returnAllBalls()
                swipedDown = false
                endTurn = true
            }
            
            // Allow the model to handle a turn
            let removedItems = gameModel!.handleTurn()
            for tup in removedItems {
                let item = tup.0
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
                else if item is MysteryBlockItem {
                    // Don't do anything for it here; wait until the round ends
                    mysteryBlocksToBreak.append(tup)
                }
                else if item is BombItem {
                    self.removeChildren(in: [item.getNode()])
                }
                else if item is BallItem {
                    // Ball items are not removed; they are just transferred over to the BallManager from the ItemGenerator
                    let vector = CGVector(dx: 0, dy: ballRadius! * 0.5)
                    let ball = item as! BallItem
                    let ballNode = item.getNode()
                    ballNode.physicsBody!.affectedByGravity = true
                    ballNode.run(SKAction.applyImpulse(vector, duration: 0.05))
                    ballHitAnimation(color: colorScheme!.hitBallColor, position: ballNode.position)
                    
                    // Ball is transferred from item generator to our ball array
                    newBallArray.append(ball)
                    ballNode.name! = "bm\(ballArray.count + newBallArray.count)"
                }
            }
            
            // If the user has broken greater than X blocks this turn, they get an "on fire" encouragement
            if brokenHitBlockCount > ContinousGameScene.ON_FIRE_COUNT && (false == displayedOnFire) {
                // Display the on fire encouragement
                displayEncouragement(emoji: "🔥", text: "On fire!")
                displayedOnFire = true
                gameModel!.addOnFireBonus()
                setBallsOnFire()
            }
            
            // Check on the balls that have hit the ground and marked as inactive and move them to the new origin point
            handleStoppedBalls()
            if firedAllBalls {
                // Wait for all balls to return
                if allBallsStopped(ballArray) {
                    // Increment game model state from MID_TURN to TURN_OVER
                    gameModel!.incrementState()
                }
            }
        }
    }
    
    // XXX NEEDS WORK
    public func saveState() {
        gameModel!.saveState(numberOfBalls: ballArray.count, originPoint: originPoint)
    }
    
    // XXX NEEDS WORK
    public func endGame() {
        gameModel!.saveState(numberOfBalls: ballArray.count, originPoint: originPoint)
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
        
        // Remove saved turn state after saving the user so they can't undo this
        gameModel!.prevTurnSaved = false
    }
    
    public func notifyCantUndo() {
        displayEncouragement(emoji: "😕", text: "Can't undo yet")
    }
    
    public func loadPreviousTurnState() {
        // Prevent the user from undoing a turn in the middle of a turn
        if false == gameModel!.isReady() {
            return
        }
        
        // Save the score of the last turn that the user chose to undo (we wait 5 turns before forcing it to re-enable it)
        lastUndoTurnScore = gameModel!.gameScore
        
        // Get the old item array so we can remove all of those items
        let oldItemArray = gameModel!.itemGenerator!.itemArray
        let oldBallArray = ballArray
        
        // Tell the item generator and game model to prepare the new item array
        let success = gameModel!.loadPreviousTurnState()
        
        if (false == success) || (false == loadPreviousBallState()) {
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
        animateItems(numItems: gameModel!.itemGenerator!.getItemCount(), array: gameModel!.itemGenerator!.itemArray)
        gameModel!.itemGenerator!.pruneFirstRow()
        
        // At this point the ball manager's state should be updated; update the view to reflect that
        currentBallCount = ballArray.count
        prevBallCount = ballArray.count
        for ball in ballArray {
            ball.loadItem(position: originPoint)
            ball.resetBall()
            self.addChild(ball.getNode())
        }
        removeBallCountLabel()
        addBallCountLabel(position: originPoint, ballCount: ballArray.count)
        
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
            if gameModel!.isMidTurn() {
                swipedDown = true
            }
        }
    }
    
    // Initialize the game model (this is where the code for loading a saved game model will go)
    private func initGameModel() {
        // The controller also needs a copy of this game model object
        gameModel = ContinuousGameModel(numberOfRows: Int(GameScene.NUM_ROWS))
        gameModel!.initItemGenerator(blockSize: blockSize!, ballRadius: ballRadius!)
        
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
            ballPosition = originPoint
            // Correct ball position's Y value (in case ground size changed for whatever reason) to prevent it from floating above the ground or being below the ground
            ballPosition.y = groundNode!.size.height + ballRadius!
            addBallCountLabel(position: originPoint, ballCount: ballArray.count)
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
        
        currentBallCount = ballArray.count
        prevBallCount = ballArray.count
        for ball in ballArray {
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
        
        // Initialized the ball array
        if let ballState = DataManager.shared.loadClassicBallState() {
            currentBallCount = ballState.numberOfBalls
            originPoint = ballState.originPoint!
            // Move the label to the loaded origin point
            addBallCountLabel(position: originPoint, ballCount: currentBallCount)
        }
        else {
            currentBallCount = ContinousGameScene.DEFAULT_NUM_BALLS
            originPoint = CGPoint(x: view!.frame.midX, y: groundNode!.size.height + ballRadius!)
        }
        ballArray = initBallArray(numberOfBalls: currentBallCount, point: originPoint)
        for ball in ballArray {
            self.addChild(ball.getNode())
        }
        
        // Move the items down in the view
        
        animateItems(numItems: gameModel!.itemGenerator!.getItemCount(), array: gameModel!.itemGenerator!.itemArray)
        gameModel!.itemGenerator!.pruneFirstRow()
        
        // Set the last turn undone as the current game score
        lastUndoTurnScore = gameModel!.gameScore
    
        // Force this to true so that we don't show it anymore
        gameModel!.showedTutorials = true
    }
    
    private func shootBalls(point: CGPoint) {
        // Save off the ball state before firing them
        prevBallState.numberOfBalls = ballArray.count
        prevBallState.originPoint = originPoint
        
        gameModel!.prepareTurn(point: point)
        startTimer(point)
    }
    
    private func updateScore(highScore: Int, gameScore: Int) {
        if let controller = gameController {
            controller.updateScore(gameScore: gameScore, highScore: highScore)
        }
        else {
            // GameController variable not set; can't update score
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
    // NOTE: Ceiling height on the iPhone 5s is < 60px (or 60 units) and so the text and pointer image need to be scaled down to accommodate for that (which is why I compare margin! to <60)
    private func showTopBarTutorial() {
        let pointerNode = SKSpriteNode(imageNamed: "hand_pointing")
        if getMargin() < 60 {
            pointerNode.size = CGSize(width: 30, height: 38)
        }
        else {
            pointerNode.size = CGSize(width: 40, height: 50)
        }
        pointerNode.zPosition = 105
        pointerNode.position = CGPoint(x: view!.frame.midX + 80, y: ceilingNode!.position.y + 10)
        
        let labelNode = SKLabelNode(fontNamed: colorScheme!.fontName)
        labelNode.zPosition = 105
        labelNode.fontColor = .white
        if getMargin() < 60 {
            labelNode.fontSize = 12
            labelNode.position = CGPoint(x: pointerNode.position.x, y: pointerNode.position.y - 30)
        }
        else {
            labelNode.fontSize = 20
            labelNode.position = CGPoint(x: pointerNode.position.x, y: pointerNode.position.y - 50)
        }
        labelNode.text = "Tap Here to Pause"
        labelNode.numberOfLines = 2
        labelNode.horizontalAlignmentMode = .center
        labelNode.verticalAlignmentMode = .center
        
        let highScoreHelper = SKLabelNode(fontNamed: colorScheme!.fontName)
        highScoreHelper.zPosition = 105
        highScoreHelper.text = "Best"
        highScoreHelper.fontColor = .white
        highScoreHelper.verticalAlignmentMode = .center
        highScoreHelper.horizontalAlignmentMode = .left
        if getMargin() < 60 {
            highScoreHelper.fontSize = 12
            highScoreHelper.position = CGPoint(x: getLeftWallWidth(), y: ceilingNode!.position.y + 4)
        }
        else {
            highScoreHelper.fontSize = 20
            highScoreHelper.position = CGPoint(x: getRightWallWidth(), y: ceilingNode!.position.y + 10)
        }
        highScoreHelper.numberOfLines = 1
        
        let gameScoreHelper = SKLabelNode(fontNamed: colorScheme!.fontName)
        gameScoreHelper.zPosition = 105
        gameScoreHelper.text = "Score"
        gameScoreHelper.fontColor = .white
        gameScoreHelper.verticalAlignmentMode = .center
        gameScoreHelper.horizontalAlignmentMode = .center
        if getMargin() < 60 {
            gameScoreHelper.fontSize = 12
            gameScoreHelper.position = CGPoint(x: view!.frame.midX, y: ceilingNode!.position.y + 4)
        }
        else {
            gameScoreHelper.fontSize = 20
            gameScoreHelper.position = CGPoint(x: view!.frame.midX, y: ceilingNode!.position.y + 10)
        }
        gameScoreHelper.numberOfLines = 1
        
        let undoHelper = SKLabelNode(fontNamed: colorScheme!.fontName)
        undoHelper.zPosition = 105
        undoHelper.text = "Undo"
        undoHelper.fontColor = .white
        undoHelper.verticalAlignmentMode = .center
        undoHelper.horizontalAlignmentMode = .right
        if getMargin() < 60 {
            undoHelper.fontSize = 12
            undoHelper.position = CGPoint(x: view!.frame.width - getRightWallWidth(), y: ceilingNode!.position.y + 4)
        }
        else {
            undoHelper.fontSize = 20
            undoHelper.position = CGPoint(x: view!.frame.width - getRightWallWidth(), y: ceilingNode!.position.y + 10)
        }
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
                return false
            }
            return true
        }
        tutorialsList = remainingTutorials
        
        // If we've shown all the tutorials, let the game model know so we don't show them again
        if tutorialsList.count == 0 {
            gameModel!.showedTutorials = true
        }
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
    
    private func showBallsAcquiredLabel(count: Int) {
        let fontSize = ballRadius! * 2
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
            // GameController variable not set; can't handle game over tap
        }
    }
    
    private func showContinueButton() {
        if let controller = gameController {
            controller.showContinueButton()
        }
        else {
            // GameController variable not set; can't show continue button
        }
    }
    
    private func enableUndoButton() {
        if let controller = gameController {
            if gameModel!.gameScore - lastUndoTurnScore >= ContinousGameScene.MAX_TURNS_FORCE_UNDO {
                // Force the controller to enable the undo button if 5 turns have passed
                controller.enableUndoButton(force: true)
            }
            else {
                // Enable the undo button if an ad is loaded
                controller.enableUndoButton()
            }
        }
        else {
            // GameController variable not set; can't enable undo button
        }
    }
    
    private func disableUndoButton() {
        if let controller = gameController {
            controller.disableUndoButton()
        }
        else {
            // GameController variable not set; can't disable undo button
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
    
    // Loads the previous state for balls
    private func loadPreviousBallState() -> Bool {
        if 0 == prevBallState.numberOfBalls {
            return false
        }
        
        let diff = ballArray.count - prevBallState.numberOfBalls
        if diff > 0 {
            for _ in 0...(diff - 1) {
                let _ = ballArray.popLast()
            }
        }
        
        // Ball array should now have the correct number of balls
        originPoint = prevBallState.originPoint!
        
        prevBallState.numberOfBalls = 0
        prevBallState.originPoint = CGPoint(x: 0, y: 0)
        
        return true
    }
    
    private func clearNewBallArray() {
        let array = newBallArray.filter {
            // Tell the ball to return to the origin point and reset its physics bitmasks
            $0.stop()
            $0.moveBallTo(originPoint)
            // Add the new ball to the ball manager's array
            self.ballArray.append($0)
            // This tells the filter to remove the ball from newBallArray
            return false
        }
        
        newBallArray = array
    }
}
