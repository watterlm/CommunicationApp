//
//  SelectCategoriesSequeUnwind.swift
//  EasyCommunication
//
//  Created by CSSE Department on 3/21/15.
//  Copyright (c) 2015 CSSE Department. All rights reserved.
//

import UIKit

class SelectCategoriesSegueUnwind: UIStoryboardSegue {
    
    override func perform(){
        // Assign the sour and destination views to local variables
        var secondVCView = self.sourceViewController.view as UIView!
        var firstVCView = self.destinationViewController.view as UIView!
        
        let screenHeight = UIScreen.mainScreen().bounds.size.height
        
        let window = UIApplication.sharedApplication().keyWindow
        window?.insertSubview(firstVCView, aboveSubview:secondVCView)
        
        // Animate the transition
        UIView.animateWithDuration(0.4, animations: { () -> Void in
            firstVCView.frame = CGRectOffset(firstVCView.frame, 0.0, screenHeight)
            secondVCView.frame = CGRectOffset(secondVCView.frame, 0.0, screenHeight)
            
            }) { (Finished) -> Void in
                self.sourceViewController.dismissViewControllerAnimated(false, completion: nil)
        }
    }
}
