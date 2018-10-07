//
//  ContinousGameModel.swift
//  Ballz1
//
//  The model for continous game play
//
//  Created by Gabriel Busto on 10/6/18.
//  Copyright © 2018 Self. All rights reserved.
//

import SpriteKit

class ContinuousGameModel {
    
    // MARK: Public properties
    public var gameScore = Int(0)
    public var highScore = Int(0)
    
    // MARK: Private properties
    private var state = Int(0)
    private var READY = Int(0)
    private var MID_TURN = Int(1)
    private var TURN_OVER = Int(2)
    
    // MARK: Initialization functions
    required init() {
        // State should always be initialized to READY
        state = READY
    }
    
    // MARK: Public functions
    public func incrementState() {
        if TURN_OVER == state {
            state = READY
        }
        
        state += 1
    }
    
    public func isReady() -> Bool {
        // State when ball manager and item generator are ready
        return (READY == state)
    }
    
    public func isMidTurn() -> Bool {
        // This state is when ball manager is in SHOOTING || WAITING state
        return (MID_TURN == state)
    }
    
    public func isTurnOver() -> Bool {
        return (TURN_OVER == state)
    }
}
