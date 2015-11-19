//
//  GameViewController.swift
//  SKPractice
//
//  Created by Kris Kissel on 9/6/15.
//  Copyright (c) 2015 Kris Kissel. All rights reserved.
//

import UIKit
import SpriteKit



extension SKNode {
    class func unarchiveFromFile(file : String) -> SKNode? {
        if let path = NSBundle.mainBundle().pathForResource(file, ofType: "sks") {
            let sceneData = try! NSData(contentsOfFile: path, options: .DataReadingMappedIfSafe)
            let archiver = NSKeyedUnarchiver(forReadingWithData: sceneData)
            
            archiver.setClass(self.classForKeyedUnarchiver(), forClassName: "SKScene")
            let scene = archiver.decodeObjectForKey(NSKeyedArchiveRootObjectKey) as! GameScene
            archiver.finishDecoding()
            return scene
        } else {
            return nil
        }
    }
}

class GameViewController: UIViewController {
    
    var valueToPass: (Int, Int)!
    
    weak var gameScene: GameScene?
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        print("GameViewController viewWillLayoutSubviews: width = \(self.view.bounds.width), height = \(self.view.bounds.height)")
        if let scene = gameScene {
            scene.layoutChanged = true
        }
    }
    
    // The following method is used to send information to Google Analytics showing how often
    // the user sees the game screen.
    override func viewWillAppear(animated: Bool) {
        var tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: "Game Level \(valueToPass!.0) as Player \(valueToPass!.1 + 1)")
        
        var builder = GAIDictionaryBuilder.createScreenView()
        tracker.send(builder.build() as [NSObject : AnyObject])
    }
    
    // Used for sending messages to Google Analytics
    func sendAnalyticsGameEvent(actionString: String, labelString: String) {
        var tracker = GAI.sharedInstance().defaultTracker
        var builder = GAIDictionaryBuilder.createEventWithCategory("Game", action: actionString, label: labelString, value: 1)
        tracker.send(builder.build() as [NSObject : AnyObject])
    }
    
    // Used for sending messages to Google Analytics about timed events
    func sendAnalyticsTimingEvent(interval: NSNumber, nameString: String, labelString: String) {
        var tracker = GAI.sharedInstance().defaultTracker
        var builder = GAIDictionaryBuilder.createTimingWithCategory("Game Timing", interval: interval, name: nameString, label: labelString)
        
        print("elapsed time: \(interval)")
        tracker.send(builder.build() as [NSObject : AnyObject])
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // for testing
        print("Value passed to GameViewController: \(valueToPass)")

        if let scene = GameScene.unarchiveFromFile("GameScene") as? GameScene {
            // Configure the view.
            
            gameScene = scene
            
            let skView = self.view as! SKView
            skView.showsFPS = false // only need true for testing
            skView.showsNodeCount = false // only need true for testing
            
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            skView.ignoresSiblingOrder = true
            
            /* Set the scale mode to scale to fit the window */
            scene.scaleMode = .AspectFill
            
            
            // The next line attaches self to the GameScene class so that methods from this controller can be called from there.    THIS IS MAINLY SO THAT I CAN UNWIND SEGUES
            scene.viewController = self
            
            // The next line passes the difficulty level to the GameScene
            scene.gameLevel = valueToPass.0
            scene.humanPlayer = valueToPass.1 + 1
            
            skView.presentScene(scene)
            
            }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    
}
