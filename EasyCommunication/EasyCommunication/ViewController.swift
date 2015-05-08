//
//  ViewController.swift
//  EasyCommunication
//
//  Created by CSSE Department on 2/4/15.
//  Copyright (c) 2015 CSSE Department. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation

class ViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, AVAudioPlayerDelegate {
    
    // CoreData
    lazy var managedObjectContext : NSManagedObjectContext? = {
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        if let managedObjectContext = appDelegate.managedObjectContext {
            return managedObjectContext
        }
        else {
            return nil
        }
    }()
    
    // Buttons
    @IBOutlet weak var btnDone: UIButton!
    @IBOutlet weak var btnDelete: UIButton!
    @IBOutlet weak var btnClear: UIButton!
    @IBOutlet weak var btnBack: UIButton!
    @IBOutlet weak var btnManage: UIButton!
    
    // Labels
    @IBOutlet weak var lblSentence: UILabel!
    
    // Collection View
    @IBOutlet weak var cvCatagories: UICollectionView!
    
    // Constants
    let CORNER_RADIUS = CGFloat(10.0)
    let EMPTY_SENTENCE = "  No Sentence Selected"
    let MAIN_CATEGORY = "Main"
    let MAIN_CAT_ID = "0"
    let CATEGORY_IMAGE = UIImage(named: "folder.png") as UIImage!
    
    // Global Variables
    private var sentenceWords = [String]()
    var needsRefreshing = false
    private var audioPlayers = [AVAudioPlayer]()
    private var wordSortKey = "word"
    private var wordAscending = true
    
    // Word Variables for Editing
    var isEditing = false
    var wordToEdit: Word?
    
    // Starting Data Collection
    private var categories = [Category]()
    private var words = [Word]()
    
    private var currentCategory = "Main"
    private var currentCatId = "0"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Round Button Corners
        btnDone.layer.cornerRadius = CORNER_RADIUS
        btnDelete.layer.cornerRadius = CORNER_RADIUS
        btnClear.layer.cornerRadius = CORNER_RADIUS
        btnBack.layer.cornerRadius = CORNER_RADIUS
        btnManage.layer.cornerRadius = CORNER_RADIUS
        
        // Setup Button Actions
        btnDelete.addTarget(self, action: "deleteClick", forControlEvents: UIControlEvents.TouchUpInside)
        btnClear.addTarget(self, action: "clearClick", forControlEvents: UIControlEvents.TouchUpInside)
        btnBack.addTarget(self, action: "backClick", forControlEvents: UIControlEvents.TouchUpInside)
        btnDone.addTarget(self, action: "doneClick", forControlEvents: UIControlEvents.TouchUpInside)
        
        // Setup Sentence Label
        lblSentence.layer.masksToBounds = true
        lblSentence.layer.cornerRadius = CORNER_RADIUS
        
        // Initially hide and disable the Back button
        btnBack.enabled = false
        btnBack.hidden = true
        
        
        // CoreData setup
        if(!hasPreviousData()){
            // Used only for test data
            // SetUp(managedObjectContext: managedObjectContext!).createCoreData()
            
            // Setup main category
            Category.createInManagedObjectContext(managedObjectContext!, title: "Main", isSpecific: NSNumber(bool: false), recording: NSData())
            save()
        }
        
        // Get User Defaults
        let defaults = NSUserDefaults.standardUserDefaults()
        if let sortKey = defaults.stringForKey("sortKey")
        {
            wordSortKey = sortKey
        }
        if (defaults.objectForKey("ascendingKey") != nil){
            wordAscending = defaults.boolForKey("ascendingKey")
        }
        println("Opening with the following settings")
        println(wordSortKey)
        println(wordAscending)
        
        // Get the categories and words
        fetchCategories()
        fetchWords(currentCatId)
        
        // Collection View Setup
        cvCatagories!.dataSource = self
        cvCatagories!.delegate = self
        
        
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // App Setup Methods
    // App CoreData Methods
    func hasPreviousData() -> Bool {
        let fetchRequest = NSFetchRequest(entityName: "Category")
        if let fetchResults = managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [Category] {
            if(fetchResults.count > 0){
                return true
            }
        }
        return false
    }
    
    func fetchCategories() {
        let fetchRequest = NSFetchRequest(entityName: "Category")
        
        // Create a sort descriptor object that sorts on the "title"
        // property of the Core Data object
        let sortDescriptor = NSSortDescriptor(key: "title", ascending: true)
    
        
        // Set the list of sort descriptors in the fetch request,
        // so it includes the sort descriptor
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Create a new predicate that filters out any object that
        // doesn't have a categoryId of 1
        let predicate = NSPredicate(format: "title != %@", "Main")
        
        // Set the predicate on the fetch request
        fetchRequest.predicate = predicate
        
        if let fetchResults = managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [Category] {
            categories = fetchResults
        }
    }
    
    func fetchCategoryId(title: String) -> NSNumber {
        let fetchRequest = NSFetchRequest(entityName: "Category")
        
        // Create a sort descriptor object that sorts on the "title"
        // property of the Core Data object
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: true)
        
        // Set the list of sort descriptors in the fetch request,
        // so it includes the sort descriptor
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Create a new predicate that filters out any object that
        // doesn't have a categoryId of 1
        let predicate = NSPredicate(format: "title == %@", title)
        
        // Set the predicate on the fetch request
        fetchRequest.predicate = predicate
        
        if let fetchResults = managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [Category] {
            if (fetchResults.count > 0){
                return fetchResults[0].id
            }
        }
        return 0
    }
    
    func fetchWords(categoryId: String) {
        let fetchRequest = NSFetchRequest(entityName: "Word")
        
        // Create a sort descriptor object that sorts on the "title"
        // property of the Core Data object
        let sortDescriptor = NSSortDescriptor(key: wordSortKey, ascending: wordAscending)
        
        // Set the list of sort descriptors in the fetch request,
        // so it includes the sort descriptor
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Create a new predicate that filters out any object that
        // doesn't have a categoryId of 1
        let predicate = NSPredicate(format: "categoryIds contains %@", categoryId + " ")
        
        // Set the predicate on the fetch request
        fetchRequest.predicate = predicate
        
        if let fetchResults = managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [Word] {
            words = fetchResults
        }
    }
    
    func fetchWord(word: String) -> Word{
        let fetchRequest = NSFetchRequest(entityName: "Word")
        
        // Create a sort descriptor object that sorts on the "title"
        // property of the Core Data object
        let sortDescriptor = NSSortDescriptor(key: "word", ascending: true)
        
        // Set the list of sort descriptors in the fetch request,
        // so it includes the sort descriptor
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Create a new predicate that filters out any object that
        // doesn't have a categoryId of 1
        let predicate = NSPredicate(format: "word == %@", word)
        
        // Set the predicate on the fetch request
        fetchRequest.predicate = predicate
        
        if let fetchResults = managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [Word] {
            return fetchResults[0]
        }
        return Word()
    }
    
    // Collection View Methods
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return words.count + categories.count
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize{
        let button = UIButton()
        var index = indexPath.row
        if (index < words.count){
            let word = wordForIndexPath(index)
            button.setTitle(word.word, forState: UIControlState.Normal)
        }else{
            let category = categoryForIndexPath(index - words.count)
            button.setTitle(category.title, forState: UIControlState.Normal)
        }
        button.sizeToFit()
        button.titleLabel?.font = UIFont(name: "System", size: 20)
        let collectionViewWidth = self.cvCatagories.bounds.size.width
        var buttonWidth = button.intrinsicContentSize().width + 10
        var buttonHeight = button.intrinsicContentSize().height + 10
        
        if(buttonWidth < 180){
            buttonWidth = CGFloat(180)
        }else if (buttonWidth > collectionViewWidth/2){
            buttonWidth = CGFloat(collectionViewWidth/2 - 20)
        }
        
        if(buttonHeight < 180){
            buttonHeight = CGFloat(180)
        }
        
        return CGSizeMake(buttonWidth, buttonHeight)
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("CollectionViewCell", forIndexPath:indexPath) as CategoryCellCollectionViewCell
        cell.layer.cornerRadius = CORNER_RADIUS
        cell.btnCat.removeTarget(nil, action: "wordClicked", forControlEvents:UIControlEvents.AllEvents)
        cell.btnCat.removeTarget(nil, action: "categoryClicked", forControlEvents:UIControlEvents.AllEvents)
        
        var index = indexPath.row
        if (index < words.count){
            let word = wordForIndexPath(index)
            cell.btnCat.setTitle(word.word, forState: UIControlState.Normal)
            cell.btnCat.addTarget(self, action: "wordClicked:", forControlEvents: UIControlEvents.TouchUpInside)
            if (word.image.length > 0){
                var tempImage = fixOrientation(UIImage(data:word.image)!, orientation: word.imageOrientation)
                cell.btnCat.setImage(tempImage, forState: .Normal)
                
            }else{
                cell.btnCat.setImage(nil, forState: .Normal)
            }
            cell.btnCat.setBackgroundImage( nil, forState: .Normal)
        }else{
            let category = categoryForIndexPath(index - words.count)
            cell.btnCat.setTitle(category.title, forState: UIControlState.Normal)
            cell.btnCat.addTarget(self, action: "categoryClicked:", forControlEvents: UIControlEvents.TouchUpInside)
            cell.btnCat.setImage(nil, forState: .Normal)
            cell.btnCat.setBackgroundImage(CATEGORY_IMAGE, forState: .Normal)
        }
        cell.backgroundColor = UIColor.whiteColor()
        
        return cell
    }
    
    func categoryForIndexPath(index: Int) -> Category{
        return categories[index]
    }
    
    func wordForIndexPath(index: Int) -> Word {
        return words[index]
    }
    
    // Button Clicks
    func clearClick(){
        resetSentence()
        
        if (currentCategory != "Main"){
            resetMain()
        }
    }
    
    func deleteClick(){
        deleteLastWord()
        // TODO: Redirect if necessary
    }
    
    func backClick(){
        btnBack.hidden = true;
        btnBack.enabled = false;
        resetMain()
    }
    
    func doneClick(){
        
        var soundData = [AVPlayerItem]();
        for (var i = 0; i < sentenceWords.count; i++){
            var error: NSError?
            var w = fetchWord(sentenceWords[i].stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()))
            println("Times Used")
            println(w.timesUsed)
            var used = Int(w.timesUsed) + 1
            w.setValue(used, forKey: "timesUsed")
            save()
            var audioPlayer = AVAudioPlayer(data: w.recording, error: &error)
            
            if let err = error{
                println("Error")
            }else{
                audioPlayer.delegate = self
                audioPlayer.prepareToPlay()
                audioPlayers.append(audioPlayer)
            }
        }
        
        for av in audioPlayers {
            av.play()
            while(av.playing){}
        }
        
        audioPlayers.removeAll(keepCapacity: false)
        
        if (wordSortKey == "timesUsed"){
            resetMain()
        }
        
        clearClick()        
    }
    
    func categoryClicked(_sender: UIButton?) {
        if let text = _sender?.titleLabel?.text {
            var catID = fetchCategoryId(text)
            currentCategory = text
            currentCatId = catID.stringValue
            btnBack.hidden = false
            btnBack.enabled = true
            words = []
            categories = []
            fetchWords(currentCatId)
            cvCatagories.reloadData()
        }
    }
    
    func wordClicked(_sender: UIButton?) {
        if let text = _sender?.titleLabel?.text {
            addToSentence(text)
        }
    }
    
    // Helpers for button Clicks
    func addToSentence(text: String){
        var textSentence = lblSentence.text
        var newText = ""
        if textSentence == EMPTY_SENTENCE{
            newText = "  " + text
            textSentence = newText
            sentenceWords.append(newText)
        }else{
            newText = " " + text
            textSentence = textSentence! + newText
            sentenceWords.append(newText)
        }
        lblSentence.text = textSentence
    }
    
    func resetSentence(){
        lblSentence.text = EMPTY_SENTENCE
        sentenceWords = [String]()
    }
    
    func deleteLastWord(){
        if(sentenceWords.count > 0){
            sentenceWords.removeLast()
            var newSentence = ""
            if sentenceWords.count > 0{
                for word in sentenceWords{
                    newSentence = newSentence + word
                }
            }else{
                newSentence = EMPTY_SENTENCE
            }
            lblSentence.text = newSentence
        }
    }
    
    func resetMain(){
        words = []
        categories = []
        currentCategory = MAIN_CATEGORY
        currentCatId = MAIN_CAT_ID
        fetchCategories()
        fetchWords(currentCatId)
        cvCatagories.reloadData()
    }
    
    func refreshCategory(){
        words = []
        categories = []
        if (currentCatId == MAIN_CAT_ID){
            fetchCategories()
            btnBack.hidden = true
            btnBack.enabled = false
        }
        fetchWords(currentCatId)
        cvCatagories.reloadData()
        needsRefreshing = false
    }
    
    // Main manage Alert
    @IBAction func handleGesture(sender: AnyObject) {
        if sender.state == UIGestureRecognizerState.Began
        {
            let alertController = UIAlertController(title: "Manage App", message:"Select the option you want to manage.", preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "Add Words", style: UIAlertActionStyle.Default,handler: { (action) -> Void in
                // Show Manage Page
                self.performSegueWithIdentifier("idManageSegue", sender: self)
            }))
            alertController.addAction(UIAlertAction(title:"Edit/Delete Word", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                alertController.dismissViewControllerAnimated(true, completion: nil)
                self.showEditingWordAlert()
            }))
            if (currentCategory == MAIN_CATEGORY){
                alertController.addAction(UIAlertAction(title:"Add Categories", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                    alertController.dismissViewControllerAnimated(true, completion: nil)
                    self.showCategoryAlert()
                }))
                alertController.addAction(UIAlertAction(title:"Edit/Delete Category", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                    alertController.dismissViewControllerAnimated(true, completion: nil)
                    self.showEditingCategoryAlert()
                }))
            }
            alertController.addAction(UIAlertAction(title:"Ordering", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                alertController.dismissViewControllerAnimated(true, completion: nil)
                self.showOrderingAlert()
            }))

            alertController.addAction(UIAlertAction(title:"Cancel", style: UIAlertActionStyle.Default, handler: nil))
            
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    // Ordering Alert and Update to user defaults
    func showOrderingAlert() {
        var alert = UIAlertController(title: "Word Ordering", message: "Select the order in which you want the words to appear. Categories will always appear alphabetically.", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Alphabetic", style: UIAlertActionStyle.Default, handler: {(action) -> Void in
            self.wordSortKey = "word"
            self.wordAscending = true
            self.updateUserDefaults()
            self.resetMain()
        }))
        alert.addAction(UIAlertAction(title: "Reverse Alphabetic", style: UIAlertActionStyle.Default, handler: {(action) -> Void in
            self.wordSortKey = "word"
            self.wordAscending = false
            self.updateUserDefaults()
            self.resetMain()
        }))
        alert.addAction(UIAlertAction(title: "Most Used", style: UIAlertActionStyle.Default, handler: {(action) -> Void in
            self.wordSortKey = "timesUsed"
            self.wordAscending = false
            self.updateUserDefaults()
            self.resetMain()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))

        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func updateUserDefaults(){
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(wordSortKey, forKey: "sortKey")
        defaults.setObject(wordAscending, forKey: "ascendingKey")
    }
    
    // Edit Word Alerts
    func showEditingWordAlert() {
        var alert = UIAlertController(title: "Edit/Delete Words", message: "Select the word that you want to edit or delete from this category.", preferredStyle: UIAlertControllerStyle.Alert)
        for word in words{
            alert.addAction(UIAlertAction(title: word.word, style: UIAlertActionStyle.Default, handler: {(action) -> Void in
                self.showEditWordOptionAlert(word)
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func showEditWordOptionAlert(w: Word) {
        
        var alert = UIAlertController(title: "Edit/Delete Word: " + w.word, message: "Do you want to edit or delete this word? Deleting will remove it from all categories.", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Edit", style: UIAlertActionStyle.Default, handler: {(action) -> Void in
            self.isEditing = true
            self.wordToEdit = w
            
            // Show Manage Page
            self.performSegueWithIdentifier("idManageSegue", sender: self)
            
        }))

        alert.addAction(UIAlertAction(title: "Delete", style: UIAlertActionStyle.Default, handler: {(action) -> Void in
            self.deleteWord(w)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    // Add Category Alert
    func showCategoryAlert() {
        var alert = UIAlertController(title: "Add Category", message: "Enter the following fields to create a category. All fields are required", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Add", style: UIAlertActionStyle.Default, handler: {(action) -> Void in
            let textField: UITextField = alert.textFields?.first as UITextField
            if (textField.text == nil || textField.text == "" || textField.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) == ""){
                let alertVC = UIAlertController(title: "Missing Fields", message: "Sorry, you must enter a title.", preferredStyle: .Alert)
                alertVC.addAction(UIAlertAction(title: "OK", style:.Default, handler: {(action) -> Void in
                    self.presentViewController(alert, animated: true, completion: nil)
                }))
                self.presentViewController(alertVC, animated: true, completion: nil)
            } else {
                self.addCategory(textField.text)
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        alert.addTextFieldWithConfigurationHandler { textField in
            textField.placeholder = "Title"
        }
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    // Edit Category Alerts
    func showEditingCategoryAlert() {
        var alert = UIAlertController(title: "Edit/Delete Categories", message: "Select the category that you want to edit or delete.", preferredStyle: UIAlertControllerStyle.Alert)
        for category in categories{
            alert.addAction(UIAlertAction(title: category.title, style: UIAlertActionStyle.Default, handler: {(action) -> Void in
                self.showEditCategoryOptionAlert(category)
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func showEditCategoryOptionAlert(c: Category) {
        
        var alert = UIAlertController(title: "Edit/Delete Category: " + c.title, message: "Do you want to edit or delete this category?", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Edit", style: UIAlertActionStyle.Default, handler: {(action) -> Void in
            self.showEditCategoryAlert(c)
        }))
        alert.addAction(UIAlertAction(title: "Delete", style: UIAlertActionStyle.Default, handler: {(action) -> Void in
            self.deleteCategory(c)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func showEditCategoryAlert(c: Category) {
        var alert = UIAlertController(title: "Edit Category", message: "Enter the following fields to edit a category. All fields are required", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Update", style: UIAlertActionStyle.Default, handler: {(action) -> Void in
            let textField: UITextField = alert.textFields?.first as UITextField
            if (textField.text == nil || textField.text == "" || textField.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) == ""){
                let alertVC = UIAlertController(title: "Missing Fields", message: "Sorry, you must enter a title.", preferredStyle: .Alert)
                alertVC.addAction(UIAlertAction(title: "OK", style:.Default, handler: {(action) -> Void in
                    self.presentViewController(alert, animated: true, completion: nil)
                }))
                self.presentViewController(alertVC, animated: true, completion: nil)
            } else {
                self.updateCategory(c, title: textField.text)
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        alert.addTextFieldWithConfigurationHandler { textField in
            textField.placeholder = "Title"
            textField.text = c.title
        }
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    // Core Data Category methods
    func addCategory(title: String){
        Category.createInManagedObjectContext(managedObjectContext!, title: title, isSpecific: NSNumber(bool: false), recording: NSData())
        resetMain()
        save()
    }
    
    func deleteCategory(c: Category){
        managedObjectContext?.deleteObject(c)
        resetMain()
        save()
    }
    
    func updateCategory(c: Category, title: String){
        c.setValue(title, forKey: "title")
        resetMain()
        save()
    }
    
    // Core Data Word methods
    func deleteWord(w: Word){
        managedObjectContext?.deleteObject(w)
        resetMain()
        save()
    }
    
    // Core Data Save
    func save(){
        var error: NSError?
        if !(managedObjectContext!.save(&error)) {
            println("Could not save \(error), \(error?.userInfo)")
        }else{
            println("Saved context");
        }
    }
    
    // Image Processing
    func fixOrientation(img:UIImage, orientation: NSNumber) -> UIImage {
        
        
        // No-op if the orientation is already correct
        if (orientation == UIImageOrientation.Up.rawValue) {
            return img;
        }
        // We need to calculate the proper transformation to make the image upright.
        // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
        var transform:CGAffineTransform = CGAffineTransformIdentity
        
        if (orientation == UIImageOrientation.Down.rawValue
            || orientation == UIImageOrientation.DownMirrored.rawValue) {
                
                transform = CGAffineTransformTranslate(transform, img.size.width, img.size.height)
                transform = CGAffineTransformRotate(transform, CGFloat(M_PI))
        }
        
        if (orientation == UIImageOrientation.Left.rawValue
            || orientation == UIImageOrientation.LeftMirrored.rawValue) {
                
                transform = CGAffineTransformTranslate(transform, img.size.width, 0)
                transform = CGAffineTransformRotate(transform, CGFloat(M_PI_2))
        }
        
        if (orientation == UIImageOrientation.Right.rawValue
            || orientation == UIImageOrientation.RightMirrored.rawValue) {
                
                transform = CGAffineTransformTranslate(transform, 0, img.size.height);
                transform = CGAffineTransformRotate(transform,  CGFloat(-M_PI_2));
        }
        
        if (orientation == UIImageOrientation.UpMirrored.rawValue
            || orientation == UIImageOrientation.DownMirrored.rawValue) {
                
                transform = CGAffineTransformTranslate(transform, img.size.width, 0)
                transform = CGAffineTransformScale(transform, -1, 1)
        }
        
        if (orientation == UIImageOrientation.LeftMirrored.rawValue
            || orientation == UIImageOrientation.RightMirrored.rawValue) {
                
                transform = CGAffineTransformTranslate(transform, img.size.height, 0);
                transform = CGAffineTransformScale(transform, -1, 1);
        }
        
        
        // Now we draw the underlying CGImage into a new context, applying the transform
        // calculated above.
        var ctx:CGContextRef = CGBitmapContextCreate(nil, UInt(img.size.width), UInt(img.size.height),
            CGImageGetBitsPerComponent(img.CGImage), 0,
            CGImageGetColorSpace(img.CGImage),
            CGImageGetBitmapInfo(img.CGImage));
        CGContextConcatCTM(ctx, transform)
        
        
        if (orientation == UIImageOrientation.Left.rawValue
            || orientation == UIImageOrientation.LeftMirrored.rawValue
            || orientation == UIImageOrientation.Right.rawValue
            || orientation == UIImageOrientation.RightMirrored.rawValue
            ) {
                
                CGContextDrawImage(ctx, CGRectMake(0,0,img.size.height,img.size.width), img.CGImage)
        } else {
            CGContextDrawImage(ctx, CGRectMake(0,0,img.size.width,img.size.height), img.CGImage)
        }
        
        
        // And now we just create a new UIImage from the drawing context
        var cgimg:CGImageRef = CGBitmapContextCreateImage(ctx)
        var imgEnd:UIImage = UIImage(CGImage: cgimg)!
        
        return imgEnd
    }
    
    // Segues
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "idManageSegue" {
            let manageViewController = segue.destinationViewController as ManageViewController
            manageViewController.currentCategory = currentCategory
            manageViewController.currentCatId = currentCatId
            
            if (isEditing){
                manageViewController.isEditing = isEditing
                manageViewController.wordToEdit = wordToEdit!
            }
        }
    }
    
    @IBAction func returnFromSegueActions(sender: UIStoryboardSegue){
        if (needsRefreshing){
            refreshCategory()
        }
    }
    
    override func segueForUnwindingToViewController(toViewController: UIViewController, fromViewController: UIViewController, identifier: String?) -> UIStoryboardSegue {
        if let id = identifier {
            if id == "idManageUnwindSegue" {
                let unwindSegue = ManageSegueUnwind(identifier: id, source: fromViewController, destination: toViewController, performHandler: {() -> Void in
                })
                return unwindSegue
            }
                
        }
        return super.segueForUnwindingToViewController(toViewController, fromViewController: fromViewController, identifier: identifier)
    }
}

