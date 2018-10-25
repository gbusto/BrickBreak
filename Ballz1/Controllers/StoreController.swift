//
//  StoreController.swift
//  Ballz1
//
//  Created by hemingway on 10/19/18.
//  Copyright © 2018 Self. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class StoreController: UIViewController {
    
    // MARK: Public properties for controller
    public var scene: SKScene?
    
    // MARK: Public properties for button states
    public var currencyAmount: Int = 0
    public var canPurchaseUndo: Bool = false
    
    @IBOutlet weak var currencyLabel: UILabel!
    
    // Stuff for the undo button
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var undoCurrencyAmount: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
            let scene = StoreScene(size: view.bounds.size)
            scene.scaleMode = .aspectFill
            self.scene = scene
            
            view.presentScene(scene)
            
            view.ignoresSiblingOrder = true
            
            // This should be set by the calling view controller
            currencyLabel.text = "\(currencyAmount)"
            
            // Perform any actions on the button and label to set it up
            setupUndoButton()
        }
    }
    
    @IBAction func purchaseUndo(_ sender: Any) {
        // Handling the user clicking the Undo purchase
        // Loading the name and cost should come from a data structure of some kind
        
        let cost: Int = 50
        
        print("User tried to purchase Undo")
        
        let notification = Notification(name: .init("undoTurn"))
        NotificationCenter.default.post(notification)
        
        // Disable the button after purchasing an Undo
        undoButton.isEnabled = false
        
        deductCurrencyAmount(amount: cost)
    }
    
    // Subtract currency from the current amount
    private func deductCurrencyAmount(amount: Int) {
        currencyAmount -= amount
        
        currencyLabel.text = "\(currencyAmount)"
        
        let myScene = self.scene as! StoreScene
        myScene.madePurchase(amount: amount, textSize: currencyLabel.font.pointSize)
        
        let deductCurrencyNotification = Notification(name: .init("deductCurrency"))
        NotificationCenter.default.post(name: deductCurrencyNotification.name, object: nil, userInfo: ["amount": amount])
    }
    
    private func setupUndoButton() {
        let uca = Int(undoCurrencyAmount.text!)!
        // If the user doesn't have enough currency to purchase this item then disable the button and set the label color to red
        if currencyAmount < uca {
            undoButton.isEnabled = false
            undoCurrencyAmount.textColor = .red
        }
        else if false == canPurchaseUndo {
            undoButton.isEnabled = false
        }
        else {
            undoButton.isEnabled = true
        }
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .portrait
        } else {
            return .portrait
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
