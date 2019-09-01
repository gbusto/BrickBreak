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
import FirebaseAnalytics

class LevelsGameScene: GameScene {
    
    // MARK: Public attributes
    public var gameModel: LevelsGameModel?
    
    public var gameController: LevelsGameController?
    
    // Variables for handling swipe gestures
    private var rightSwipeGesture: UISwipeGestureRecognizer?
    private var downSwipeGesture: UISwipeGestureRecognizer?
    private var addedGesture = false
    private var swipedDown = false
    
    private var showedConfetti = false
    
    private var showingGameOverView = false
    
    // This is to keep track of the number of broken hit blocks in a given turn
    private var brokenHitBlockCount: Int = 0
    // A boolean because we only want to show the "on fire" encouragement once per turn
    private var displayedOnFire: Bool = false
    // This is the number of blocks that need to be broken in a given turn to get the "on fire" encouragement
    private static var ON_FIRE_COUNT: Int = 8

    // Specifies whether or not the game just started
    private var gameStart = true
    
    // The number of rows to display at the start of the game
    private var numRowsToStart = Int(5)
    
    private var ballProjection = BallProjection()
    
    private var numRowsGenerated = Int(0)


    // MARK: Override functions
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        // Initialize the game model
        initGameModel()
        
        if let controller = gameController {
            controller.setLevelNumber(level: gameModel!.levelCount)
        }
        
        rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleRightSwipe(_:)))
        rightSwipeGesture!.direction = .right
        rightSwipeGesture!.numberOfTouchesRequired = 1
        
        downSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleDownSwipe(_:)))
        downSwipeGesture!.direction = .down
        downSwipeGesture!.numberOfTouchesRequired = 1
        
        // Allow ourselves to be the physics contact delegates
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
                
                // Needed because balls can sometimes slip out of bounds. Not sure how this is possible... race condition bug in the collision engine?
                if isOutOfBounds(ballPosition: ball.getNode().position) {
                    ball.outOfBounds = true
                }
            }
        }
    }
    
    // MARK: Scene update
    override func update(_ currentTime: TimeInterval) {
        let gameScore = gameModel!.gameScore
        if let controller = gameController {
            controller.updateScore(score: gameScore)
        }
        
        // The view that is displayed when the user wins starts out with an alpha of 0 (completely transparent)
        // If this flag is set to true, the views have been added to the main view and need to fade in
        if showingGameOverView {
            // Get the blur view to fade it in
            for view in activeViews {
                if view.alpha <= 1 {
                    view.alpha += 0.02
                }
                else {
                    // Once it's been faded in, stop it from messing with the alpha
                    showingGameOverView = false
                }
            }
        }
        
        // XXX Create a generic resetGame function in GameScene to hold common reset code between LevelsGameScene and ContinuousGameScene
        if gameModel!.isTurnOver() {
            endTurn = false
            
            // Reset the number of balls that were fired to 0
            numBallsFired = 0
            
            // Reset this; let's us know when all balls have been fired
            firedAllBalls = false
            
            // Reset the boolean specifying whether or not balls are on fire
            ballsOnFire = false
            
            // Reset this boolean saying that the first ball has touched the ground
            firstBallReturned = false
            
            // Return physics simulation to normal speed
            physicsWorld.speed = 1.0
            
            // Return the fireDelay to the default
            fireDelay = GameScene.DEFAULT_FIRE_DELAY
            
            // Reset the tick delay for firing balls
            
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
            animateItems(numItems: gameModel!.itemGenerator!.getItemCount(), array: gameModel!.itemGenerator!.itemArray)
            gameModel!.itemGenerator!.pruneFirstRow()
            
            // Add back the ball count label
            addBallCountLabel(position: originPoint, ballCount: ballArray.count)
            
            // Check the model to update the score label
            // Update the current game score
            
            // Reset the number of hit blocks and the encouragements shown to the user
            brokenHitBlockCount = 0
            displayedOnFire = false
            
            let currentCount = gameModel!.rowNumber
            let maxCount = gameModel!.numRowsToGenerate
            if currentCount <= maxCount {
                gameController!.updateRowCountLabel(currentCount: currentCount, maxCount: maxCount)
            }
        }
        
        // After the turn over, wait for the game logic to decide whether or not the user is about to lose or has lost
        if gameModel!.isWaiting() {
            if doneAnimatingItems() {
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
            // Reset this list to empty
            stoppedBalls = []
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
                    let block = item as! MysteryBlockItem
                    var centerPoint = block.getNode().position
                    centerPoint.x += blockSize!.width / 2
                    centerPoint.y += blockSize!.height / 2

                    showSpecialAnimation(item: item, center: centerPoint)
                    
                    // We want to remove block items from the scene completely
                    self.removeChildren(in: [item.getNode()])
                    // Show block break animation
                    breakBlock(color1: block.bottomColor!, color2: block.topColor!, position: centerPoint)
                    brokenHitBlockCount += 1
                }
                else if item is BombItem {
                    var centerPoint = item.getNode().position
                    centerPoint.x += blockSize!.width / 2
                    centerPoint.y += blockSize!.height / 2
                    
                    showSpecialAnimation(item: item, center: centerPoint)
                    
                    self.removeChildren(in: [item.getNode()])
                }
            }
            
            // If the user has broken greater than X blocks this turn, they get an "on fire" encouragement
            if brokenHitBlockCount > LevelsGameScene.ON_FIRE_COUNT && (false == displayedOnFire) {
                // Display the on fire encouragement
                displayEncouragement(emoji: "🔥", text: "On fire!")
                displayedOnFire = true
                gameModel!.addOnFireBonus()
                setBallsOnFire()
            }
            
            if gameModel!.lastItemBroken && false == showedConfetti {
                // Check if the last item broke. If it did, show the confetti!
                displayEncouragement(emoji: "🎉🎉🎉", text: "")
                let confetti = Confetti()
                let emitter = confetti.getEmitter(frame: view!.bounds)
                emitter.name = "confetti"
                view!.layer.addSublayer(emitter)
                
                showedConfetti = true
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
    
    // MARK: Public functions
    // Handle a right swipe to fast forward
    @objc public func handleRightSwipe(_ sender: UISwipeGestureRecognizer) {
        let point = sender.location(in: view!)
        
        if inGame(point) {
            if gameModel!.isMidTurn() {
                // Speed up the physics simulation
                if physicsWorld.speed < 3.0 {
                    // Analytics log event; log when the user swipes right to fast forward in a level
                    Analytics.logEvent("levels_swipe_right", parameters: /* None */ [:])
                    
                    physicsWorld.speed = 3.0
                    
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
                // Analytics log event; log when the user swipes down to end their turn in a level
                Analytics.logEvent("levels_swipe_down", parameters: /* None */ [:])

                swipedDown = true
            }
        }
    }
    
    public func showPauseScreen(pauseView: UIView) {
        if activeViews.count == 0 {
            let blur = UIBlurEffect(style: .dark)
            let blurView = UIVisualEffectView(effect: blur)
            blurView.frame = view!.frame
            view!.addSubview(blurView)
        
            pauseView.isHidden = false
            view!.addSubview(pauseView)
        
            activeViews = [blurView, pauseView]
        }
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
    
    public func showGameOverView(win: Bool, gameOverView: UIView) {
        if view!.isPaused {
            // Unpause the view if it's paused so we can update it with the user win/loss view
            view!.isPaused = false
        }
        
        let blur = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blur)
        blurView.frame = view!.frame
        
        let imageView = UIImageView(image: UIImage(named: "score_background_yellow_fade"))
        // Set the center of the image to be the center of the main view
        imageView.center = view!.center
        imageView.contentMode = .scaleAspectFit
        
        let imageView2 = UIImageView(image: UIImage(named: "imageview_background"))
        imageView2.center = view!.center
        imageView2.contentMode = .scaleAspectFit
        
        // Set the alphas to 0 so we can fade it in
        blurView.alpha = 0
        gameOverView.alpha = 0
        imageView.alpha = 0
        imageView2.alpha = 0
        
        // Add the blur view to the screen first
        view!.addSubview(blurView)
        
        // Add the score background image on top of the blur view but behind the level cleared view
        view!.addSubview(imageView)
        
        // Add the background image for the labels
        view!.addSubview(imageView2)
        
        // Unhide the level cleared view
        gameOverView.isHidden = false
        
        // Add the level cleared view on top of the blur view and the level cleared view
        view!.addSubview(gameOverView)
        
        // Set a flag so that the update scene tick will fade the view in
        showingGameOverView = true
        
        activeViews = [blurView, gameOverView, imageView, imageView2]
        
        if win {
            if gameModel!.gameScore > gameModel!.highScore {
                let _ = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
                    self.addHighScoreStamp()
                }
            }
            else {
                let _ = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
                    self.addLevelPassedStamp()
                }
            }
        }
        else {
            let _ = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
                self.addLevelFailedStamp()
            }
        }
    }
    
    public func addLevelPassedStamp() {
        let levelPassedStampView = UIImageView(image: UIImage(named: "level_passed_narrow4"))
        levelPassedStampView.center = view!.center
        levelPassedStampView.center.y -= 70
        levelPassedStampView.contentMode = .scaleAspectFit
        
        view!.addSubview(levelPassedStampView)
        
        activeViews.append(levelPassedStampView)
    }
    
    public func addLevelFailedStamp() {
        let levelPassedStampView = UIImageView(image: UIImage(named: "level_failed_narrow4"))
        levelPassedStampView.center = view!.center
        levelPassedStampView.center.y -= 70
        levelPassedStampView.contentMode = .scaleAspectFit
        
        view!.addSubview(levelPassedStampView)
        
        activeViews.append(levelPassedStampView)
    }
    
    public func addHighScoreStamp() {
        let highScoreStamp = UIImageView(image: UIImage(named: "high_score_narrow4"))
        highScoreStamp.center = view!.center
        highScoreStamp.center.y -= 70
        highScoreStamp.contentMode = .scaleAspectFit
        
        view!.addSubview(highScoreStamp)
        
        activeViews.append(highScoreStamp)
    }
    
    public func removeGameOverView() {
        let views = activeViews.filter {
            $0.removeFromSuperview()
            return false
        }
        
        activeViews = views
    }
    
    public func showLevelLossScreen(gameOverView: UIView) {
        let blur = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blur)
        blurView.frame = view!.frame
        view!.addSubview(blurView)
        
        gameOverView.isHidden = false
        view!.addSubview(gameOverView)
        
        activeViews = [blurView, gameOverView]
    }
    
    public func gameOverLoss() {
        // Notify the controller that the user lost
        if let controller = gameController {
            controller.gameOverLoss()
        }
    }
    
    public func gameOverWin() {
        // Notify the controller that the user won
        gameModel!.saveState()
        
        if let controller = gameController {
            controller.gameOver(win: true)
        }
    }
    
    public func removeConfetti() {
        // Clear the sublayer with the confetti
        if let layers = view!.layer.sublayers {
            for layer in layers {
                if let name = layer.name {
                    if name == "confetti" {
                        layer.removeFromSuperlayer()
                    }
                }
            }
        }
    }
    
    // XXX Common function
    // Save the user from loss after they watched an ad
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
    
    // MARK: Private functions
    private func initGameModel() {
        gameModel = LevelsGameModel(view: view!, blockSize: blockSize!, ballRadius: ballRadius!, numberOfRows:
                                    Int(GameScene.NUM_ROWS),
                                    // PRODUCTION: Change back the TRUE before deploying
                                    production: true)
        
        // XXX This could be changed so fontName can remain private
        ballCountLabel = SKLabelNode(fontNamed: fontName)
        ballCountLabel!.name = "ballCountLabel"
        
        originPoint = CGPoint(x: view!.frame.midX, y: groundNode!.size.height + ballRadius!)
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
        
        currentBallCount = gameModel!.numberOfBalls
        ballArray = initBallArray(numberOfBalls: currentBallCount, point: originPoint)
        for ball in ballArray {
            self.addChild(ball.getNode())
        }
        
        // Add items to the scene
        for i in 1...numRowsToStart {
            let row = gameModel!.generateRow()
            for item in row {
                if item is StoneHitBlockItem {
                    if i % 2 == 0 {
                        let block = item as! StoneHitBlockItem
                        block.changeState(duration: 1)
                    }
                }
            }
            addRowToView(rowNum: (numRowsToStart + 1) - i, items: row)
        }
        
        // XXX May need to uncomment this line
        // Addressed in issue #431
        // actionsStarted or animteItems() should only be allowed to be called once and ignored while items are in motion
        // Move the items down in the view
        //animateItems()
    }
    
    // XXX Common function
    private func shootBalls(point: CGPoint) {
        gameModel!.prepareTurn()
        startTimer(point)
    }
}
