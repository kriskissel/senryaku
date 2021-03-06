//
//  TutotrialViewController.swift
//  Korners
//
//  Created by Kris Kissel on 11/4/15.
//  Copyright © 2015 Kris Kissel. All rights reserved.
//

import UIKit
import SpriteKit

class TutotrialViewController: GameViewController {

    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if let scene = gameScene {
            scene.layoutChanged = true
        }
    }
    
    // The following method is used to send information to Google Analytics showing how often
    // the user sees the tutorial.
    override func viewWillAppear(animated: Bool) {
        var tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: "Tutorial")
        
        var builder = GAIDictionaryBuilder.createScreenView()
        tracker.send(builder.build() as [NSObject : AnyObject])
    }
    
    // need to modify this, cancel call to super?
    override func viewDidLoad() {
        //super.viewDidLoad()
        
        if let scene = TutorialScene.unarchiveFromFile("TutorialScene") as? TutorialScene {
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
            //scene.aiPly = valueToPass.0
            // NO, this caused a crash!
            // Something about the way TutorialScene inherits from GameScene and the order in which
            // this initialize made an option unwrap as nil.
            // But it's not necessary, anyway, because GameScene.aiPly has a default value that 
            // works fine for the tutorial.
            
            skView.presentScene(scene)
            
        }

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


}
