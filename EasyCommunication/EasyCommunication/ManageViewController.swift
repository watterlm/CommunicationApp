//
//  ManageViewController.swift
//  EasyCommunication
//
//  Created by CSSE Department on 2/23/15.
//  Copyright (c) 2015 CSSE Department. All rights reserved.
//

import UIKit
import AVFoundation
import CoreData

class ManageViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    
    // CoreData
    var managedObjectContext : NSManagedObjectContext? = {
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        if let managedObjectContext = appDelegate.managedObjectContext {
            return managedObjectContext
        }
        else {
            return nil
        }
    }()

    // Buttons
    @IBOutlet weak var btnUpload: UIButton!
    @IBOutlet weak var btnClear: UIButton!
    @IBOutlet weak var btnCancel: UIButton!
    @IBOutlet weak var btnAttachImage: UIButton!
    @IBOutlet weak var btnRecordPhrase: UIButton!
    @IBOutlet weak var btnStopRecording: UIButton!
    @IBOutlet weak var btnSelectCategories: UIButton!
    @IBOutlet weak var btnPlayBack: UIButton!
    @IBOutlet weak var chkCurrentCategory: Checkbox!
    
    // Labels
    @IBOutlet weak var lblCurrentCategory: UILabel!
    @IBOutlet weak var lblListCategories: UILabel!
    @IBOutlet weak var lblRecording: UILabel!
    
    // Image View
    @IBOutlet weak var imgAttachedImage: UIImageView!
    
    // Text Box
    @IBOutlet weak var txtWord: UITextField!
    
    
    // Constants
    let CORNER_RADIUS = CGFloat(10.0)
    let CURRENT_CATEGORY_LABEL = "  Current Category: "
    
    // Global Variables
    var currentCategory: NSString!
    var currentCatId: NSString!
    private var uploadSuccessful = false
    private var hasRecordedSound = false
    private var categories = [Category]()
    var categoriesToAddTo = [Category]()
    private var needsRefreshing = false
    private var image = UIImage()
    private var picker = UIImagePickerController()
    private var audioPlayer = AVAudioPlayer()
    private var audioRecorder: AVAudioRecorder?
    private var soundPath: NSURL?
    private var soundFilePath = ""
    
    // Editing variables
    var isEditing = false
    var wordToEdit: Word?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Round Button Corners
        btnUpload.layer.cornerRadius = CORNER_RADIUS
        btnClear.layer.cornerRadius = CORNER_RADIUS
        btnCancel.layer.cornerRadius = CORNER_RADIUS
        btnAttachImage.layer.cornerRadius = CORNER_RADIUS
        btnRecordPhrase.layer.cornerRadius = CORNER_RADIUS
        btnStopRecording.layer.cornerRadius = CORNER_RADIUS
        btnSelectCategories.layer.cornerRadius = CORNER_RADIUS
        
        // Round Label
        lblCurrentCategory.layer.cornerRadius = CORNER_RADIUS
        
        // Update Current Category and Filenames
        lblCurrentCategory.text = CURRENT_CATEGORY_LABEL + currentCategory
        
        // Set up image picker
        picker.delegate = self
        
        // Set up Audio 
        btnStopRecording.enabled = false
        btnPlayBack.enabled = false
        
        // Set up checkboxes
        chkCurrentCategory.isChecked = true;
        
        // Set up Audio Directory and recording settings
        lblRecording.hidden = true
        let dirPaths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let docsDir = dirPaths[0] as String
        soundFilePath = docsDir.stringByAppendingPathComponent("sound.caf")
        
        // Check for preexisting sound file and remove it if necessary
        removeAudioPath(soundFilePath)
        
        setUpAudioRecorder()
        
        // Setup selectCategories
        if hasPreviousCategoriesData() {
            fetchCategories()
            if categories.count > 0 {
                btnSelectCategories.enabled = true;
            }else{
                btnSelectCategories.enabled = false;
            }
        }else{
            btnSelectCategories.enabled = false;
        }
        
        // If this is editing upload old data
        if (isEditing){
            txtWord.text = wordToEdit!.word
            if(wordToEdit!.image.length > 0){
                image = UIImage(data: wordToEdit!.image)!
            
                imgAttachedImage.image = image
            }
            fetchCategoriesFromWord(wordToEdit!.categoryIds)
            
            for (var i = 0; i < categoriesToAddTo.count; i++){
                if i == 0 {
                    lblListCategories.text = categoriesToAddTo[i].title
                }else {
                    lblListCategories.text = lblListCategories.text! + ", " + categoriesToAddTo[i].title
                }
            }
            
            var sound: NSData = wordToEdit!.recording
            sound.writeToURL(soundPath!, atomically: false)
            hasRecordedSound = true
            btnPlayBack.enabled = true
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Core Data Functions
    func hasPreviousCategoriesData() -> Bool {
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
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: true)
        
        // Set the list of sort descriptors in the fetch request,
        // so it includes the sort descriptor
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Create a new predicate that filters out any object that
        // doesn't have a categoryId of 1
        let predicate = NSPredicate(format: "title != %@", currentCategory)
        
        // Set the predicate on the fetch request
        fetchRequest.predicate = predicate
        
        if let fetchResults = managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [Category] {
            categories = fetchResults
        }
    }
    
    func fetchCategoriesFromWord(ids: String){
        let fetchRequest = NSFetchRequest(entityName: "Category")
        
        // Create a sort descriptor object that sorts on the "title"
        // property of the Core Data object
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: true)
        
        // Set the list of sort descriptors in the fetch request,
        // so it includes the sort descriptor
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Create a new predicate that filters out any object that
        // doesn't have a categoryId of 1
        let predicate: NSPredicate = NSPredicate(format: "title != %@", currentCategory)!
        // Set the predicate on the fetch request
        fetchRequest.predicate = predicate
        
        if let fetchResults = managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [Category] {
            var cats = fetchResults
            var idArray: [String] = split(ids) {$0 == " "}
            println(ids)
            for category in cats {
                println(category.id.stringValue)
                println(contains(idArray, category.id.stringValue))
                if (contains(idArray, (category.id).stringValue)){
                    categoriesToAddTo.append(category)
                }
            }
        }

    }
    
    // Button Clicks
    @IBAction func cancelManage(sender: UIButton){
        self.performSegueWithIdentifier("idManageUnwindSegue", sender: self)
    }
    
    @IBAction func uploadWord(sender: UIButton){
        createWord()
        if uploadSuccessful {
            if(chkCurrentCategory.isChecked || isEditing){
                needsRefreshing = true
            }
            self.performSegueWithIdentifier("idManageUnwindSegue", sender: self)
        }
    }
    
    @IBAction func clearManage(sender: UIButton){
        image = UIImage()
        imgAttachedImage.image = nil
        audioPlayer = AVAudioPlayer()
        categoriesToAddTo.removeAll(keepCapacity: false)
        hasRecordedSound = false
        needsRefreshing = false
        chkCurrentCategory.isChecked = true
        txtWord.text = ""
        lblListCategories.text = ""
        
        // Check for preexisting sound file and remove it if necessary
        removeAudioPath(soundFilePath)
        setUpAudioRecorder()
        btnPlayBack.enabled = false
        btnStopRecording.enabled = false
        
    }

    @IBAction func selectCategories(sender:UIButton) {
        self.performSegueWithIdentifier("idSelectCategoriesSegue", sender: self)
    }
    
    @IBAction func uploadImage(sender: UIButton){
        // Create the Alert
        let actionSheetController: UIAlertController = UIAlertController(title: "Image Upload", message: "", preferredStyle: .ActionSheet)
        actionSheetController.addAction(UIAlertAction(title:"Cancel", style: .Cancel, handler: nil))
        actionSheetController.addAction(UIAlertAction(title:"Take Picture", style: .Default, handler: { (action) -> Void in
            // Open Camera
            if(UIImagePickerController.availableCaptureModesForCameraDevice(.Rear) != nil) {
                self.picker.allowsEditing = false
                self.picker.sourceType = .Camera
                self.picker.modalPresentationStyle = UIModalPresentationStyle.FullScreen
                self.picker.cameraCaptureMode = .Photo
                self.presentViewController(self.picker, animated: true, completion: nil)
                self.picker.popoverPresentationController?.sourceView = self.view
            } else {
                self.noCamera()
            }
        }))
        actionSheetController.addAction(UIAlertAction(title:"Choose From Camera Roll", style: .Default, handler: { (action) -> Void in
            // Open Camera Roll
            self.picker.allowsEditing = false
            self.picker.sourceType = .PhotoLibrary
            self.picker.modalPresentationStyle = .Popover
            self.presentViewController(self.picker, animated: true, completion: nil)
            self.picker.popoverPresentationController?.sourceView = sender
        }))
        actionSheetController.popoverPresentationController?.sourceView = sender as UIView;
        self.presentViewController(actionSheetController, animated: true, completion: nil)
        
    }
    
    // Segues
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?){
        if segue.identifier == "idManageUnwindSegue" {
            let viewController = segue.destinationViewController as ViewController
            viewController.needsRefreshing = needsRefreshing
            viewController.isEditing = false
            viewController.wordToEdit = nil
            isEditing = false
            wordToEdit = nil
        }
        if segue.identifier == "idSelectCategoriesSegue" {
            let selectCategoriesViewController = segue.destinationViewController as SelectCategoryViewController
            selectCategoriesViewController.categories = categories
            selectCategoriesViewController.categoriesToAdd = categoriesToAddTo
        }
    }
    
    @IBAction func returnFromSegueActions(sender: UIStoryboardSegue){
        if sender.identifier == "idSelectCategoriesUnwindSegue" {
            if categoriesToAddTo.count < 1{
                lblListCategories.text = " "
            }else {
                for (var i = 0; i < categoriesToAddTo.count; i++){
                    if i == 0 {
                        lblListCategories.text = categoriesToAddTo[i].title
                    }else {
                        lblListCategories.text = lblListCategories.text! + ", " + categoriesToAddTo[i].title
                    }
                }
            }
        }
    }
    
    override func segueForUnwindingToViewController(toViewController: UIViewController, fromViewController: UIViewController, identifier: String?) -> UIStoryboardSegue {
        if let id = identifier {
            if id == "idSelectCategoriesUnwindSegue" {
                let unwindSegue = SelectCategoriesSegueUnwind(identifier: id, source: fromViewController, destination: toViewController, performHandler: {() -> Void in
                })
                return unwindSegue
            }
        }
        return super.segueForUnwindingToViewController(toViewController, fromViewController: fromViewController, identifier: identifier)
    }
    
    // Image Delegates
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]){
        image = info[UIImagePickerControllerOriginalImage] as UIImage
        imgAttachedImage.contentMode = .ScaleAspectFit
        imgAttachedImage.image = image
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController){
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func noCamera(){
        let alertVC = UIAlertController(title: "No Camera", message: "Sorry, this device has no camera", preferredStyle: .Alert)
        alertVC.addAction(UIAlertAction(title: "OK", style:.Default, handler: nil))
        presentViewController(alertVC, animated: true, completion: nil)
    }
    
    // Recording Actions
    @IBAction func recordAudio(sender: AnyObject) {
        if audioRecorder?.recording == false {
            // Disable all buttons and text
            btnAttachImage.enabled = false
            btnCancel.enabled = false
            btnClear.enabled = false
            btnUpload.enabled = false
            txtWord.enabled = false
            btnSelectCategories.enabled = false
            chkCurrentCategory.enabled = false
            
            // Disable and enable correct recording buttons
            lblRecording.hidden = false
            btnRecordPhrase.enabled = false
            btnStopRecording.enabled = true
            audioRecorder?.record()
        }
    }
    
    @IBAction func stopAudio(sender: AnyObject) {
        // Enable all buttons and text
        btnAttachImage.enabled = true
        btnCancel.enabled = true
        btnClear.enabled = true
        btnUpload.enabled = true
        txtWord.enabled = true
        btnSelectCategories.enabled = true
        chkCurrentCategory.enabled = true
        
        // Enable and disable correct recording buttons
        lblRecording.hidden = true
        btnStopRecording.enabled = false
        btnPlayBack.enabled = true
        btnRecordPhrase.enabled = true
        
        if audioRecorder?.recording == true {
            audioRecorder?.stop()
        } else {
            audioPlayer.stop()
        }
    }
    
    @IBAction func playAudio(sender: AnyObject) {
        if audioRecorder?.recording == false {
            // Disable all buttons and text
            btnAttachImage.enabled = false
            btnCancel.enabled = false
            btnClear.enabled = false
            btnUpload.enabled = false
            txtWord.enabled = false
            btnSelectCategories.enabled = false
            chkCurrentCategory.enabled = false
            
            // Enable and disable correct recording buttons
            lblRecording.hidden = false
            btnStopRecording.enabled = true
            btnRecordPhrase.enabled = false
            
            var error: NSError?
            
            audioPlayer = AVAudioPlayer(contentsOfURL: audioRecorder?.url,
                error: &error)
            
            audioPlayer.delegate = self
            
            if let err = error {
                println("audioPlayer error: \(err.localizedDescription)")
            } else {
                audioPlayer.play()
                while(audioPlayer.playing){}
                stopAudio(sender)
            }
        }
    }
    
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder!, successfully flag: Bool) {
        if(flag) {
            println("Recorded Sound")
            hasRecordedSound = true
        } else {
            hasRecordedSound = false
        }

    }
    
    func removeAudioPath(soundPath: String){
        // Check for preexisting sound file and remove it if necessary
        let filemgr = NSFileManager.defaultManager()
        if filemgr.fileExistsAtPath(soundPath) {
            println("File exists")
            
            var error: NSError?
            if filemgr.removeItemAtPath(soundPath, error: &error) {
                println("Remove successful")
            } else {
                println("Remove failed: \(error!.localizedDescription)")
            }
        } else {
            println("File not found")
        }
    }
    
    func setUpAudioRecorder(){
        let soundFileURL = NSURL(fileURLWithPath: soundFilePath)
        soundPath = soundFileURL!
        let recordSettings = [AVEncoderAudioQualityKey: AVAudioQuality.Min.rawValue, AVEncoderBitRateKey: 16, AVNumberOfChannelsKey: 2, AVSampleRateKey: 44100.0]
        
        var error: NSError?
        
        // start session
        let audioSession = AVAudioSession.sharedInstance()
        audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, error: &error)
        
        if let err = error {
            println("audioSession error: \(err.localizedDescription)")
        }
        
        audioRecorder = AVAudioRecorder(URL: soundFileURL, settings: recordSettings, error: &error)
        audioRecorder?.delegate = self
        
        if let err = error {
            println("audioSession error: \(err.localizedDescription)")
        } else {
            audioRecorder?.prepareToRecord()
        }
    }
    
    // Core Data Word Creation
    func createWord(){
        if (!txtWord.text.isEmpty && hasRecordedSound && (chkCurrentCategory.isChecked || categoriesToAddTo.count > 0)){
            var catIds: NSString! = " "
            var tempImageStorage: NSData
            var imageOrientation: NSNumber
            
            if categoriesToAddTo.count < 1{
                catIds = " "
            }else {
                for (var i = 0; i < categoriesToAddTo.count; i++){
                    catIds = catIds + categoriesToAddTo[i].id.stringValue + " "
                }
            }
            
            if chkCurrentCategory.isChecked {
                catIds = catIds + currentCatId + " "
            }
            
            if(image.size.width > 0 && image.size.height > 0){
                tempImageStorage = UIImagePNGRepresentation(image) as NSData
                imageOrientation = image.imageOrientation.rawValue
            }else {
                tempImageStorage = NSData()
                imageOrientation = UIImageOrientation.Up.rawValue
            }
            
            var soundData:NSData = NSData(contentsOfURL: soundPath!)!
            
            if(!isEditing){
                Word.createInManagedObjectContext(managedObjectContext!, word: txtWord.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()), recording: soundData, image: tempImageStorage, categoryIds: catIds, imageOrientation: imageOrientation)
            }else {
                wordToEdit?.word = txtWord.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
                wordToEdit?.recording = soundData
                wordToEdit?.image = tempImageStorage
                wordToEdit?.categoryIds = catIds
                wordToEdit?.imageOrientation = imageOrientation
            }
            save()
            
            uploadSuccessful = true
        } else {
            uploadSuccessful = false
            let alertVC = UIAlertController(title: "Missing Fields", message: "Sorry, the following fields are required: Word, Recording, and either Add to Current Category or Select Categories.", preferredStyle: .Alert)
            alertVC.addAction(UIAlertAction(title: "OK", style:.Default, handler: nil))
            presentViewController(alertVC, animated: true, completion: nil)
        }
    }

    func save(){
        var error: NSError?
        if !(managedObjectContext!.save(&error)) {
            println("Could not save \(error), \(error?.userInfo)")
        }
    }
}
