//
//  TestCheckbox.swift
//  EasyCommunication
//
//  Created by CSSE Department on 3/21/15.
//  Copyright (c) 2015 CSSE Department. All rights reserved.
//

import UIKit

class Checkbox : UIButton {
    
    // bool property
    var isChecked: Bool = false {
        didSet{
            if self.isChecked{
                self.setImage(UIImage(named: "checked_checkbox"), forState: UIControlState.Normal);
            }else{
                self.setImage(UIImage(named: "unchecked_checkbox"), forState: UIControlState.Normal);
            }
        }
    }
    
    override func awakeFromNib() {
        self.addTarget(self, action: "buttonClicked:", forControlEvents: UIControlEvents.TouchUpInside)
        self.isChecked = false;
        
        let lLeftInset: CGFloat = 8.0;
        self.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Left;
        // #4
        self.imageEdgeInsets = UIEdgeInsetsMake(0.0 as CGFloat, lLeftInset, 0.0 as CGFloat, 0.0 as CGFloat);
        // #5
        self.titleEdgeInsets = UIEdgeInsetsMake(0.0 as CGFloat, (lLeftInset * 2), 0.0 as CGFloat, 0.0 as CGFloat);
        self.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal);
        
    }
    
    func buttonClicked(sender: UIButton){
        self.isChecked = !self.isChecked
    }
    
}
