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
    
    
    /************************************************************************************************************************************/
    /*                                                  Core Data Object Setup                                                          */
    /************************************************************************************************************************************/
    lazy var managedObjectContext : NSManagedObjectContext? = {
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        if let managedObjectContext = appDelegate.managedObjectContext {
            return managedObjectContext
        }
        else {
            return nil
        }
    }()
    
    
    /************************************************************************************************************************************/
    /*                                                          Buttons                                                                 */
    /************************************************************************************************************************************/
    @IBOutlet weak var btnDone: UIButton!
    @IBOutlet weak var btnDelete: UIButton!
    @IBOutlet weak var btnClear: UIButton!
    @IBOutlet weak var btnBack: UIButton!
    @IBOutlet weak var btnManage: UIButton!
    
    
    /************************************************************************************************************************************/
    /*                                                         Labels                                                                   */
    /************************************************************************************************************************************/
    @IBOutlet weak var lblSentence: UILabel!
    
    
    /************************************************************************************************************************************/
    /*                                                      Collection View                                                             */
    /************************************************************************************************************************************/
    @IBOutlet weak var cvCatagories: UICollectionView!
    
    
    /************************************************************************************************************************************/
    /*                                                         Constants                                                                */
    /************************************************************************************************************************************/
    // Used to round corners of Buttons and TextFields
    let CORNER_RADIUS = CGFloat(10.0)
    
    // Default text for sentence
    let EMPTY_SENTENCE = "  No Sentence Selected"
    
    // Main category details
    let MAIN_CATEGORY = "Main"
    let MAIN_CAT_ID = "0"
    
    // Image for categories
    let CATEGORY_IMAGE = UIImage(named: "folder.png") as UIImage!
    
    
    /************************************************************************************************************************************/
    /*                                                     Global Variables                                                             */
    /************************************************************************************************************************************/
    // Used to keep track of the words in the sentence, allows for deletion
    private var sentenceWords = [String]()
    
    // Used to determine if the page needs refreshing
    var needsRefreshing = false
    
    // Audio player. Must be defined as global otherwise it will never play
    private var audioPlayers = [AVAudioPlayer]()
    
    // Variables for detecting sort type. These are default alphabetic and will be overwritten on startup
    private var wordSortKey = "word"
    private var wordAscending = true
    
    // Word Variables for Editing
    var isEditing = false
    var wordToEdit: Word?
    
    // Data collection variables
    private var categories = [Category]()
    private var words = [Word]()
    
    // Current Category variables
    private var currentCategory = "Main"
    private var currentCatId = "0"
    
    
    /************************************************************************************************************************************/
    /*                                                      General Methods                                                             */
    /************************************************************************************************************************************/
    /* The startup function. Called when the page is first loaded */
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
        
        
        // CoreData setup. Not run if there is previous data
        if(!hasPreviousData()){
            // Used only for test data
            // SetUp(managedObjectContext: managedObjectContext!).createCoreData()
            
            // Setup main category
            Category.createInManagedObjectContext(managedObjectContext!, title: "Main", isSpecific: NSNumber(bool: false), recording: NSData())
            save()
        }
        
        // Get User Defaults
        let defaults = NSUserDefaults.standardUserDefaults()
        
        // Check defaults for a stored ordering
        if let sortKey = defaults.stringForKey("sortKey")
        {
            wordSortKey = sortKey
        }
        if (defaults.objectForKey("ascendingKey") != nil){
            wordAscending = defaults.boolForKey("ascendingKey")
        }
        
        // Get the categories and words for main
        fetchCategories()
        fetchWords(currentCatId)
        
        // Collection View Setup
        cvCatagories!.dataSource = self
        cvCatagories!.delegate = self
        
    }
    
    /* Method for Core Data (Default implementation) */
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /************************************************************************************************************************************/
    /*                                                   App Core Data Methods                                                          */
    /************************************************************************************************************************************/
    
    /* Check for previous data such as categories since there will always be one category except on the very first startup. */
    func hasPreviousData() -> Bool {
        let fetchRequest = NSFetchRequest(entityName: "Category")
        if let fetchResults = managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [Category] {
            if(fetchResults.count > 0){
                return true
            }
        }
        return false
    }
    
    /* Fetch all categories for Main */
    func fetchCategories() {
        let fetchRequest = NSFetchRequest(entityName: "Category")
        
        // Create a sort descriptor object that sorts on the "title"
        // property of the Core Data object
        let sortDescriptor = NSSortDescriptor(key: "title", ascending: true)
    
        
        // Set the list of sort descriptors in the fetch request,
        // so it includes the sort descriptor
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Create a new predicate that filters out the Main Category
        let predicate = NSPredicate(format: "title != %@", "Main")
        
        // Set the predicate on the fetch request
        fetchRequest.predicate = predicate
        
        if let fetchResults = managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [Category] {
            // Set the categories so they can be populated on the page
            categories = fetchResults
        }
    }
    
    /* Fetch a category id from its title */
    func fetchCategoryId(title: String) -> NSNumber {
        let fetchRequest = NSFetchRequest(entityName: "Category")
        
        // Create a sort descriptor object that sorts on the "id"
        // property of the Core Data object
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: true)
        
        // Set the list of sort descriptors in the fetch request,
        // so it includes the sort descriptor
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Create a new predicate that filters out any object that
        // doesn't have the current title
        let predicate = NSPredicate(format: "title == %@", title)
        
        // Set the predicate on the fetch request
        fetchRequest.predicate = predicate
        
        if let fetchResults = managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [Category] {
            // Assume that there is only one category by each name so return the first result's id
            if (fetchResults.count > 0){
                return fetchResults[0].id
            }
        }
        return 0
    }
    
    /* Fetch all the words in a category from a category id */
    func fetchWords(categoryId: String) {
        let fetchRequest = NSFetchRequest(entityName: "Word")
        
        // Create a sort descriptor object that sorts on the specified
        // property of the Core Data object in the specified order. 
        // This is what allows word ordering to occur
        let sortDescriptor = NSSortDescriptor(key: wordSortKey, ascending: wordAscending)
        
        // Set the list of sort descriptors in the fetch request,
        // so it includes the sort descriptor
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Create a new predicate that filters out any word that
        // doesn't have the category id listed
        // Word's categoryIds column is deliminated by a " ".
        // The extra space in front ensures that the id exactly matches
        // so that when you're trying to get the words for category 2, 
        // you don't get category 12 words too.
        let predicate = NSPredicate(format: "categoryIds contains %@", " " + categoryId + " ")
        
        // Set the predicate on the fetch request
        fetchRequest.predicate = predicate
        
        if let fetchResults = managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [Word] {
            // Set the words for population
            words = fetchResults
        }
    }
    
    /* Fetch a word from it's text */
    func fetchWord(word: String) -> Word{
        let fetchRequest = NSFetchRequest(entityName: "Word")
        
        // Create a sort descriptor object that sorts on the "word"
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
            // Assume that the first result is the only result and return it
            return fetchResults[0]
        }
        // If no results return an empty word
        return Word()
    }
    
    /* Add a category to core data */
    func addCategory(title: String){
        // Create a category object
        Category.createInManagedObjectContext(managedObjectContext!, title: title, isSpecific: NSNumber(bool: false), recording: NSData())
        
        // Reset main
        resetMain()
        
        // Save the changes to core data
        save()
    }
    
    /* Delete a category from core data */
    func deleteCategory(c: Category){
        // delete the passed in category object from core data
        managedObjectContext?.deleteObject(c)
        
        // Reset main
        resetMain()
        
        // Save the changes to core data
        save()
    }
    
    /* Update a category in core data */
    func updateCategory(c: Category, title: String){
        // Update the title for the category object
        c.setValue(title, forKey: "title")
        
        // reset main
        resetMain()
        
        // Save the change to core data
        save()
    }
    
    /* Delete a word from core data */
    func deleteWord(w: Word){
        // Delete the word object from core data
        managedObjectContext?.deleteObject(w)
        
        // Reset main
        resetMain()
        
        // Save the cahnges to core data
        save()
    }
    
    /* Save helper for Core Data */
    func save(){
        var error: NSError?
        // Attempt to save the current context of core data
        if !(managedObjectContext!.save(&error)) {
            // Couldn't save so print the error
            println("Could not save \(error), \(error?.userInfo)")
        }else{
            // Else it was saved
            println("Saved context");
        }
    }
    
    
    /************************************************************************************************************************************/
    /*                                                  Collection View Methods                                                         */
    /************************************************************************************************************************************/
    
    /* Required Method for Collection Views. Always returns 1 to ensure only one section */
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    /* Required Method for Collection View. Returns the number of items in the collection view */
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return words.count + categories.count
    }
    
    /* Require for dynamics sizing for Collection View. Returns the size for the current button being added */
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize{
        // Create a testing button
        let button = UIButton()
        
        // Use the index path to get the current index
        var index = indexPath.row
        
        // if the current index is less than the count of the words, a word is being added
        if (index < words.count){
            // Get the word for that current index
            let word = wordForIndexPath(index)
            
            // Set the button title to that word
            button.setTitle(word.word, forState: UIControlState.Normal)
        }else{
            // Else it is a category so get the category at that index
            let category = categoryForIndexPath(index - words.count)
            
            // Set the button title to the category's title
            button.setTitle(category.title, forState: UIControlState.Normal)
        }
        
        // Tell the button to fit its text (this allows long words/phrase to be entered
        // and prevents them from being truncated)
        button.sizeToFit()
        
        // Set the font size for the button
        button.titleLabel?.font = UIFont(name: "System", size: 20)
        
        // Get the collection view's width
        let collectionViewWidth = self.cvCatagories.bounds.size.width
        
        // Set the get the current button width plus padding
        var buttonWidth = button.intrinsicContentSize().width + 10
        
        // Get the current button height plus padding
        var buttonHeight = button.intrinsicContentSize().height + 10
        
        // If the button width is less than 180 set it to the default 180
        if(buttonWidth < 180){
            buttonWidth = CGFloat(180)
        }else if (buttonWidth > collectionViewWidth/2){
            // Else if the button width is greatere than half of the collection view's width
            // Set it to half the collection view width minus the padding
            buttonWidth = CGFloat(collectionViewWidth/2 - 20)
        }
        
        // If the button height is less than 180 set it to the defaul 180
        if(buttonHeight < 180){
            buttonHeight = CGFloat(180)
        }
        
        // Return the size of that button
        return CGSizeMake(buttonWidth, buttonHeight)
    }
    
    /* Collection view item population */
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell{
        // Create a cell to display using the custom cell
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("CollectionViewCell", forIndexPath:indexPath) as CategoryCellCollectionViewCell
        
        // Round the corners of the cell
        cell.layer.cornerRadius = CORNER_RADIUS
        
        // Remove any actions that might have been placed on the cell's button
        cell.btnCat.removeTarget(nil, action: "wordClicked", forControlEvents:UIControlEvents.AllEvents)
        cell.btnCat.removeTarget(nil, action: "categoryClicked", forControlEvents:UIControlEvents.AllEvents)
        
        // Get the collection view index
        var index = indexPath.row
        
        // If the index is less than the word count then we are adding words
        if (index < words.count){
            // Get the word for that index
            let word = wordForIndexPath(index)
            
            // Set the cell's button text to the word
            cell.btnCat.setTitle(word.word, forState: UIControlState.Normal)
            
            // Add the word pressed action to the button
            cell.btnCat.addTarget(self, action: "wordClicked:", forControlEvents: UIControlEvents.TouchUpInside)
            
            // If the word has an image set the cell's button to have the image
            if (word.image.length > 0){
                // Fix the image orientaion
                var tempImage = fixOrientation(UIImage(data:word.image)!, orientation: word.imageOrientation)
                // Set the image
                cell.btnCat.setImage(tempImage, forState: .Normal)
                
            }else{
                // Otherwise set the button's image to nil
                cell.btnCat.setImage(nil, forState: .Normal)
            }
            
            // Remove the button's background image (in case this cell was a category last time)
            cell.btnCat.setBackgroundImage( nil, forState: .Normal)
        }else{
            // Else we are adding a Categroy so get the Category
            let category = categoryForIndexPath(index - words.count)
            
            // Set the cell's button text to the category title
            cell.btnCat.setTitle(category.title, forState: UIControlState.Normal)
            
            // Add the category pressed action to the button
            cell.btnCat.addTarget(self, action: "categoryClicked:", forControlEvents: UIControlEvents.TouchUpInside)
            
            // Remove any images the button may have
            cell.btnCat.setImage(nil, forState: .Normal)
            
            // Set the background image to the Category image
            cell.btnCat.setBackgroundImage(CATEGORY_IMAGE, forState: .Normal)
        }
        
        // Set the cell's color to white
        cell.backgroundColor = UIColor.whiteColor()
        
        return cell
    }
    
    /* Get the category for the given index */
    func categoryForIndexPath(index: Int) -> Category{
        return categories[index]
    }
    
    /* Get the word for the given index */
    func wordForIndexPath(index: Int) -> Word {
        return words[index]
    }
    
    
    /************************************************************************************************************************************/
    /*                                                       Button Actions                                                             */
    /************************************************************************************************************************************/
    
    /* Action for the clear button */
    func clearClick(){
        // Reset the sentence to it's default value
        resetSentence()
        
        // IF the current category isn't main reset it so it is and hide and disable the back button
        if (currentCategory != "Main"){
            btnBack.hidden = true;
            btnBack.enabled = false;
            resetMain()
        }
    }
    
    /* Action for the delete button */
    func deleteClick(){
        // delete the last word from the sentence
        deleteLastWord()
    }
    
    // Action for the back button */
    func backClick(){
        // hide and disable the back button since we will be at the top level
        btnBack.hidden = true;
        btnBack.enabled = false;
        
        // Reset main
        resetMain()
    }
    
    /* Action for the done button */
    func doneClick(){
        // Loop thorugh each word in the sentence
        for (var i = 0; i < sentenceWords.count; i++){
            var error: NSError?
            // Get the word object for the current word in the sentence
            var w = fetchWord(sentenceWords[i].stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()))
            
            // Increment the word's number of times used (this is for most used ordering)
            var used = Int(w.timesUsed) + 1
            
            // Update the word in core data to reflect the times used change
            w.setValue(used, forKey: "timesUsed")
            save()
            
            // Create a temporary audio player with the sound data from the word
            var audioPlayer = AVAudioPlayer(data: w.recording, error: &error)
            
            // Check for an error
            if let err = error{
                println("Error")
            }else{
                // Else prepare the audio player for playing (this cuts down playback time so it is important)
                audioPlayer.delegate = self
                audioPlayer.prepareToPlay()
                
                // add the prepared audio player to the list of players
                audioPlayers.append(audioPlayer)
            }
        }
        
        // Cycle through all the audio players and playback their recordings
        for av in audioPlayers {
            av.play()
            
            // Wait until the player has stopped playing to play the next recording
            while(av.playing){}
        }
        
        // Remove all the audio players once done
        audioPlayers.removeAll(keepCapacity: false)
        
        // If the current word sorting is times used refresh main to reflect ordering changes
        if (wordSortKey == "timesUsed"){
            resetMain()
        }
        
        // Clear all previous data
        clearClick()        
    }
    
    /* Action for a category click */
    func categoryClicked(_sender: UIButton?) {
        // Check for text
        if let text = _sender?.titleLabel?.text {
            // If sucessful get the category id
            var catID = fetchCategoryId(text)
            
            // set the current category to the category text
            currentCategory = text
            
            // set the current category id to the category id
            currentCatId = catID.stringValue
            
            // Show and enable the back button so we can return to main
            btnBack.hidden = false
            btnBack.enabled = true
            
            // Empty the words and category arrays
            words = []
            categories = []
            
            // Fetch the words for the current category
            fetchWords(currentCatId)
            
            // Tell the collection view to reload
            cvCatagories.reloadData()
        }
    }
    
    /* Action for a word click */
    func wordClicked(_sender: UIButton?) {
        // If the word has text add it to the sentence
        if let text = _sender?.titleLabel?.text {
            addToSentence(text)
        }
    }
    
    
    /************************************************************************************************************************************/
    /*                                                    Button Click Helpers                                                          */
    /************************************************************************************************************************************/
    
    /* Adds a word to the sentence */
    func addToSentence(text: String){
        // Get the current sentence text
        var textSentence = lblSentence.text
        
        // Create a temporary text
        var newText = ""
        
        // Check if the sentence text equals the default
        if textSentence == EMPTY_SENTENCE{
            // If it does adding the padding spaces and then the word to the temp
            newText = "  " + text
            
            // Set the sentence text to the new text
            textSentence = newText
            
            // Append the word to the list of words added to the sentence
            sentenceWords.append(newText)
        }else{
            // Else it already has contents and only needs a single space
            newText = " " + text
            
            // Add the new text to the old text
            textSentence = textSentence! + newText
            
            // Append the word to the list of words added to the sentence
            sentenceWords.append(newText)
        }
        // Set the sentence label text
        lblSentence.text = textSentence
    }
    
    /* Resets the sentence to default */
    func resetSentence(){
        // Reset the sentence text to default
        lblSentence.text = EMPTY_SENTENCE
        
        // Remove all words from the sentence word list
        sentenceWords = [String]()
    }
    
    /* Deletes the last word from a sentence */
    func deleteLastWord(){
        // If there are words in the sentence
        if(sentenceWords.count > 0){
            // Remove the last word from the word list
            sentenceWords.removeLast()
            
            // Make a temporay text variable
            var newSentence = "  "
            
            // Check to see if the sentence still has words
            if sentenceWords.count > 0{
                // If it does go through each and append them to the temp variable
                for word in sentenceWords{
                    newSentence = newSentence + word
                }
            }else{
                // Else the sentence is empty and needs to be set to the default text
                newSentence = EMPTY_SENTENCE
            }
            
            // Set the label text
            lblSentence.text = newSentence
        }
    }
    
    /* resets the Main screen */
    func resetMain(){
        // Hide and disable the back button
        btnBack.hidden = true
        btnBack.enabled = false
        
        // Clear all words and categories
        words = []
        categories = []
        
        // Reset current category information to Main
        currentCategory = MAIN_CATEGORY
        currentCatId = MAIN_CAT_ID
        
        // Fetch all the categories
        fetchCategories()
        
        // Fetch all the words for main
        fetchWords(currentCatId)
        
        // Reload the collection view
        cvCatagories.reloadData()
    }
    
    /* Refresh the current category */
    func refreshCategory(){
        // Clear all words and categories
        words = []
        categories = []
        
        // If the current category is main
        if (currentCatId == MAIN_CAT_ID){
            // Fetch all categories
            fetchCategories()
            
            // Hide and disable the back button
            btnBack.hidden = true
            btnBack.enabled = false
        }
        
        // Fetch all words for the category
        fetchWords(currentCatId)
        
        // Refresh the collection view
        cvCatagories.reloadData()
        
        // Reset the needsRefreshing boolean
        needsRefreshing = false
    }
    
    
    /************************************************************************************************************************************/
    /*                                                       Management Alerts                                                          */
    /************************************************************************************************************************************/
    
    /* Handle the longpress gesture. Makes the main management alert. This is the first one that pops up after the long press in the bottom corner */
    @IBAction func handleGesture(sender: AnyObject) {
        if sender.state == UIGestureRecognizerState.Began
        {
            // Create alert with a title and message
            let alertController = UIAlertController(title: "Manage App", message:"Select the option you want to manage.", preferredStyle: UIAlertControllerStyle.Alert)
            
            // Add a button for Adding words
            alertController.addAction(UIAlertAction(title: "Add Words", style: UIAlertActionStyle.Default,handler: { (action) -> Void in
                // Shows the add word page (ManageViewController.swift)
                self.performSegueWithIdentifier("idManageSegue", sender: self)
            }))
            
            // Add a button for editing/deleting words
            alertController.addAction(UIAlertAction(title:"Edit/Delete Word", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                // Close the main management alert
                alertController.dismissViewControllerAnimated(true, completion: nil)
                
                // Launch another alert for editing words
                self.showEditingWordAlert()
            }))
            
            // If the current category is Main
            if (currentCategory == MAIN_CATEGORY){
                // Add a button for Adding categories
                alertController.addAction(UIAlertAction(title:"Add Categories", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                    // Close the main management alert
                    alertController.dismissViewControllerAnimated(true, completion: nil)
                    
                    // Launch another alert for adding categories
                    self.showCategoryAlert()
                }))
                
                // Add a button for editing/deleteing categories
                alertController.addAction(UIAlertAction(title:"Edit/Delete Category", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                    // Close the main management alert
                    alertController.dismissViewControllerAnimated(true, completion: nil)
                    
                    // Launch another alert for editing categories
                    self.showEditingCategoryAlert()
                }))
            }
            
            // Add a button for Ordering
            alertController.addAction(UIAlertAction(title:"Ordering", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                // Close the main management alert
                alertController.dismissViewControllerAnimated(true, completion: nil)
                
                // Launch another alert for chosing ordering of words
                self.showOrderingAlert()
            }))
            
            // Add a cancel button
            alertController.addAction(UIAlertAction(title:"Cancel", style: UIAlertActionStyle.Default, handler: nil))
            
            // Launch the alert
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    /* Makes Alert for Changing Order of words in a category */
    func showOrderingAlert() {
        // Create an alert with a title and message
        var alert = UIAlertController(title: "Word Ordering", message: "Select the order in which you want the words to appear. Categories will always appear alphabetically.", preferredStyle: UIAlertControllerStyle.Alert)
        
        // Add button for Alphabetic
        alert.addAction(UIAlertAction(title: "Alphabetic", style: UIAlertActionStyle.Default, handler: {(action) -> Void in
            // Set sorting values
            self.wordSortKey = "word"
            self.wordAscending = true
            
            // Update the user defaults
            self.updateUserDefaults()
            
            // reset main
            self.resetMain()
        }))
        
        // Add button for Reverse Alphabetic
        alert.addAction(UIAlertAction(title: "Reverse Alphabetic", style: UIAlertActionStyle.Default, handler: {(action) -> Void in
            // Set sorting values
            self.wordSortKey = "word"
            self.wordAscending = false
            
            // Update the user defaults
            self.updateUserDefaults()
            
            // reset main
            self.resetMain()
        }))
        
        // Add button for Most Used
        alert.addAction(UIAlertAction(title: "Most Used", style: UIAlertActionStyle.Default, handler: {(action) -> Void in
            // Set sorting values
            self.wordSortKey = "timesUsed"
            self.wordAscending = false
            
            // Update the user defaults
            self.updateUserDefaults()
            
            // reset main
            self.resetMain()
        }))
        
        // Add a cancel button
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))

        // Launch the alert
        self.presentViewController(alert, animated: true, completion: nil)
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
    
    
    /************************************************************************************************************************************/
    /*                                                      Gerneral Helpers                                                            */
    /************************************************************************************************************************************/
    
    /* fixes the orientation of images when made from NSData */
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
    
    /* Updates the user defaults for the app. Adds in the ordering so when the app is reopened the ordering is maintained */
    func updateUserDefaults(){
        // get user defaults
        let defaults = NSUserDefaults.standardUserDefaults()
        
        // Set the wordSortKey and wordAscending variables in the defaults
        defaults.setObject(wordSortKey, forKey: "sortKey")
        defaults.setObject(wordAscending, forKey: "ascendingKey")
    }
    
    /************************************************************************************************************************************/
    /*                                                Segues to Other Controllers                                                       */
    /************************************************************************************************************************************/
    
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

