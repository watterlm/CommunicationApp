//
//  SelectCategoryViewController.swift
//  EasyCommunication
//
//  Created by CSSE Department on 3/21/15.
//  Copyright (c) 2015 CSSE Department. All rights reserved.
//

import UIKit
import CoreData

class SelectCategoryViewController: UIViewController{
    
    // Buttons
    @IBOutlet weak var btnDone: UIButton!
    
    // Scrollview
    @IBOutlet weak var svCategories: UIScrollView!
    
    // Constants
    let CORNER_RADIUS = CGFloat(10.0)
    
    // Variable Arrays
    var categories = [Category]()
    var categoriesToAdd = [Category]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.createCheckboxes()
        btnDone.layer.cornerRadius = CORNER_RADIUS
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Add checkboxes
    func createCheckboxes() {
        let lCheckboxHeight: CGFloat = 44.0;
        // #2
        var lFrame = CGRectMake(0, 20, self.view.frame.size.width, lCheckboxHeight);
        var height = 0.0;
        for (var counter = 0; counter < categories.count; counter++) {
            // #3
            var isSelected = false
            for (var i = 0; i < categoriesToAdd.count; i++){
                if categoriesToAdd[i].title == categories[counter].title{
                    isSelected = true
                    break
                }
            }
            var lCheckbox = Checkbox();
            lCheckbox.tag = counter
            lCheckbox.frame = lFrame
            lCheckbox.awakeFromNib()
            lCheckbox.setTitle(categories[counter].title, forState: UIControlState.Normal)
            lCheckbox.isChecked = isSelected
            lCheckbox.addTarget(self, action: "checkboxChecked:", forControlEvents: UIControlEvents.TouchUpInside)
            lCheckbox.removeTarget(lCheckbox, action: "buttonClicked:", forControlEvents: UIControlEvents.TouchUpInside)
            svCategories.addSubview(lCheckbox)
            height += Double(lCheckboxHeight)
            // #4
            lFrame.origin.y += lFrame.size.height*2
            
        }
        
        var width = svCategories.bounds.size.width
        svCategories.contentSize = CGSizeMake(width, svCategories.bounds.size.height + CGFloat(height))
    }
    
    func checkboxChecked(sender: Checkbox){
        sender.isChecked = !sender.isChecked
        if sender.isChecked{
            self.categoriesToAdd.append(self.categories[sender.tag])
        }else{
            for (var i = 0; i < categoriesToAdd.count; i++){
                if categoriesToAdd[i].title == categories[sender.tag].title{
                    categoriesToAdd.removeAtIndex(i)
                }
            }
        }
    }
    
    @IBAction func doneSelecting(sender: AnyObject) {
        btnDone.enabled = false
        self.performSegueWithIdentifier("idSelectCategoriesUnwindSegue", sender: self)
    }

    // Segues
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?){
        if segue.identifier == "idSelectCategoriesUnwindSegue"{
            let manageViewController = segue.destinationViewController as ManageViewController
            manageViewController.categoriesToAddTo = categoriesToAdd
        }
    }

}

