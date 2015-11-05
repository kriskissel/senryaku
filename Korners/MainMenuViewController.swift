//
//  MainMenuViewController.swift
//  Korners
//
//  Created by Kris Kissel on 10/28/15.
//  Copyright © 2015 Kris Kissel. All rights reserved.
//

import UIKit

class MainMenuViewController: UIViewController {
    
    
    @IBOutlet weak var levelSelectorSegmentedControl: UISegmentedControl!
    
    
    @IBAction func playNow(sender: UIButton) {
        print("Pressed Play Now")
        print("Current level: \(levelSelectorSegmentedControl.selectedSegmentIndex)")
        performSegueWithIdentifier("playGame", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        if (segue.identifier == "playGame"){
            let svc = segue.destinationViewController as! GameViewController
            svc.valueToPass = levelSelectorSegmentedControl.selectedSegmentIndex + 1
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("main menu viewDidLoad")

        // Do any additional setup after loading the view.
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        print("main menu viewWillLayoutSubviews: width = \(self.view.bounds.width), height = \(self.view.bounds.height)")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print("main menu viewDidLayoutSubviews: width = \(self.view.bounds.width), height = \(self.view.bounds.height)")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        print("view did appear, segueing to tutorial")
        performSegueWithIdentifier("showTutorial", sender: self)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
