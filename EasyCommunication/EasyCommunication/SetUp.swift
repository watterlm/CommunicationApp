//
//  SetUp.swift
//  EasyCommunication
//
//  Created by CSSE Department on 2/4/15.
//  Copyright (c) 2015 CSSE Department. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class SetUp {
    // CoreData
    var managedObjectContext : NSManagedObjectContext
    
    init(managedObjectContext: NSManagedObjectContext){
        self.managedObjectContext = managedObjectContext
    }
    
    func save(){
        var error: NSError?
        if !managedObjectContext.save(&error) {
            println("Could not save \(error), \(error?.userInfo)")
        }
    }
    
    func createCoreData(){
        setUpCategories()
        setUpCategoryWords()
    }
    
    func setUpCategories(){
        Category.createInManagedObjectContext(managedObjectContext, title: "Main", isSpecific: NSNumber(bool: false), recording: NSData())
        Category.createInManagedObjectContext(managedObjectContext, title: "Pronouns", isSpecific: NSNumber(bool: false), recording: NSData())
        Category.createInManagedObjectContext(managedObjectContext, title: "Verbs", isSpecific: NSNumber(bool: false), recording: NSData())
        Category.createInManagedObjectContext(managedObjectContext, title: "Questions", isSpecific: NSNumber(bool: false), recording: NSData())
        Category.createInManagedObjectContext(managedObjectContext, title: "Names", isSpecific: NSNumber(bool: false), recording: NSData())
        Category.createInManagedObjectContext(managedObjectContext, title: "Greetings", isSpecific: NSNumber(bool: false), recording: NSData())
        Category.createInManagedObjectContext(managedObjectContext, title: "Foods", isSpecific: NSNumber(bool: false), recording: NSData())
        Category.createInManagedObjectContext(managedObjectContext, title: "Places", isSpecific: NSNumber(bool: false), recording: NSData())
        Category.createInManagedObjectContext(managedObjectContext, title: "Feelings", isSpecific: NSNumber(bool: false), recording: NSData())
        Category.createInManagedObjectContext(managedObjectContext, title: "Activities", isSpecific: NSNumber(bool: false), recording: NSData())
        Category.createInManagedObjectContext(managedObjectContext, title: "Animals", isSpecific: NSNumber(bool: false), recording: NSData())
        Category.createInManagedObjectContext(managedObjectContext, title: "Phrases", isSpecific: NSNumber(bool: false), recording: NSData())
        
        // Save Categories
        save()
    }
    
    func setUpCategoryWords(){
        setUpMainWords()
        setUpPronounWords()
        
        save()
        
    }
    
    func setUpMainWords() {
        var catId = fetchCategoryIdLog("Main")
        var catIdPro = fetchCategoryIdLog("Pronouns")
        Word.createInManagedObjectContext(managedObjectContext, word: "I", recording: NSData(), image: NSData(), categoryIds: (String(catId) + " " + String(catIdPro) + " "), imageOrientation: UIImageOrientation.Up.rawValue)
        Word.createInManagedObjectContext(managedObjectContext, word: "You", recording: NSData(), image: NSData(), categoryIds: (String(catId) + " " + String(catIdPro) + " "), imageOrientation: UIImageOrientation.Up.rawValue)
        Word.createInManagedObjectContext(managedObjectContext, word: "He", recording: NSData(), image: NSData(), categoryIds: (String(catId) + " " + String(catIdPro) + " "), imageOrientation: UIImageOrientation.Up.rawValue)
        Word.createInManagedObjectContext(managedObjectContext, word: "She", recording: NSData(), image: NSData(), categoryIds: (String(catId) + " " + String(catIdPro) + " "), imageOrientation: UIImageOrientation.Up.rawValue)
        Word.createInManagedObjectContext(managedObjectContext, word: "It", recording: NSData(), image: NSData(), categoryIds: (String(catId) + " " + String(catIdPro) + " "), imageOrientation: UIImageOrientation.Up.rawValue)
        Word.createInManagedObjectContext(managedObjectContext, word: "They", recording: NSData(), image: NSData(), categoryIds: (String(catId) + " " + String(catIdPro) + " "), imageOrientation: UIImageOrientation.Up.rawValue)
    }
    
    func setUpPronounWords(){
        var catId = fetchCategoryIdLog("Pronouns")
        if (catId != -1){
            Word.createInManagedObjectContext(managedObjectContext, word: "me", recording: NSData(), image: NSData(), categoryIds: (String(catId) + " "), imageOrientation: UIImageOrientation.Up.rawValue)
            Word.createInManagedObjectContext(managedObjectContext, word: "my", recording: NSData(), image: NSData(), categoryIds: (String(catId) + " "), imageOrientation: UIImageOrientation.Up.rawValue)
            Word.createInManagedObjectContext(managedObjectContext, word: "mine", recording: NSData(), image: NSData(), categoryIds: (String(catId) + " "), imageOrientation: UIImageOrientation.Up.rawValue)
            Word.createInManagedObjectContext(managedObjectContext, word: "myself", recording: NSData(), image: NSData(), categoryIds: (String(catId) + " "), imageOrientation: UIImageOrientation.Up.rawValue)
            Word.createInManagedObjectContext(managedObjectContext, word: "your", recording: NSData(), image: NSData(), categoryIds: (String(catId) + " "), imageOrientation: UIImageOrientation.Up.rawValue)
            Word.createInManagedObjectContext(managedObjectContext, word: "yours", recording: NSData(), image: NSData(),    categoryIds: (String(catId) + " "), imageOrientation: UIImageOrientation.Up.rawValue)
            Word.createInManagedObjectContext(managedObjectContext, word: "yourself", recording: NSData(), image: NSData(), categoryIds: (String(catId) + " "), imageOrientation: UIImageOrientation.Up.rawValue)
            Word.createInManagedObjectContext(managedObjectContext, word: "him", recording: NSData(), image: NSData(), categoryIds: (String(catId) + " "), imageOrientation: UIImageOrientation.Up.rawValue)
            Word.createInManagedObjectContext(managedObjectContext, word: "his", recording: NSData(), image: NSData(), categoryIds: (String(catId) + " "), imageOrientation: UIImageOrientation.Up.rawValue)
            Word.createInManagedObjectContext(managedObjectContext, word: "himself", recording: NSData(), image: NSData(), categoryIds: (String(catId) + " "), imageOrientation: UIImageOrientation.Up.rawValue)
            Word.createInManagedObjectContext(managedObjectContext, word: "her", recording: NSData(), image: NSData(), categoryIds: (String(catId) + " "), imageOrientation: UIImageOrientation.Up.rawValue)
            Word.createInManagedObjectContext(managedObjectContext, word: "hers", recording: NSData(), image: NSData(), categoryIds: (String(catId) + " "), imageOrientation: UIImageOrientation.Up.rawValue)
            Word.createInManagedObjectContext(managedObjectContext, word: "herself", recording: NSData(), image: NSData(), categoryIds: (String(catId) + " "), imageOrientation: UIImageOrientation.Up.rawValue)
            Word.createInManagedObjectContext(managedObjectContext, word: "myself", recording: NSData(), image: NSData(), categoryIds: (String(catId) + " "), imageOrientation: UIImageOrientation.Up.rawValue)
            Word.createInManagedObjectContext(managedObjectContext, word: "its", recording: NSData(), image: NSData(), categoryIds: (String(catId) + " "), imageOrientation: UIImageOrientation.Up.rawValue)
            Word.createInManagedObjectContext(managedObjectContext, word: "itself", recording: NSData(), image: NSData(), categoryIds: (String(catId) + " "), imageOrientation: UIImageOrientation.Up.rawValue)
            Word.createInManagedObjectContext(managedObjectContext, word: "we", recording: NSData(), image: NSData(), categoryIds: (String(catId) + " "), imageOrientation: UIImageOrientation.Up.rawValue)
            Word.createInManagedObjectContext(managedObjectContext, word: "us", recording: NSData(), image: NSData(), categoryIds: (String(catId) + " "), imageOrientation: UIImageOrientation.Up.rawValue)
            Word.createInManagedObjectContext(managedObjectContext, word: "our", recording: NSData(), image: NSData(), categoryIds: (String(catId) + " "), imageOrientation: UIImageOrientation.Up.rawValue)
            Word.createInManagedObjectContext(managedObjectContext, word: "ours", recording: NSData(), image: NSData(), categoryIds: (String(catId) + " "), imageOrientation: UIImageOrientation.Up.rawValue)
            Word.createInManagedObjectContext(managedObjectContext, word: "ourselves", recording: NSData(), image: NSData(), categoryIds: (String(catId) + " "), imageOrientation: UIImageOrientation.Up.rawValue)
            Word.createInManagedObjectContext(managedObjectContext, word: "yourselves", recording: NSData(), image: NSData(), categoryIds: (String(catId) + " "), imageOrientation: UIImageOrientation.Up.rawValue)
            Word.createInManagedObjectContext(managedObjectContext, word: "them", recording: NSData(), image: NSData(), categoryIds: (String(catId) + " "), imageOrientation: UIImageOrientation.Up.rawValue)
            Word.createInManagedObjectContext(managedObjectContext, word: "their", recording: NSData(), image: NSData(), categoryIds: (String(catId) + " "), imageOrientation: UIImageOrientation.Up.rawValue)
            Word.createInManagedObjectContext(managedObjectContext, word: "theirs", recording: NSData(), image: NSData(), categoryIds: (String(catId) + " "), imageOrientation: UIImageOrientation.Up.rawValue)
            Word.createInManagedObjectContext(managedObjectContext, word: "themselves", recording: NSData(), image: NSData(), categoryIds: (String(catId) + " "), imageOrientation: UIImageOrientation.Up.rawValue)
        }
        
    }
    
    func fetchCategoryIdLog(categoryTitle: String) -> Int {
        let fetchRequest = NSFetchRequest(entityName: "Category")
        // Create a new predicate that filters out any object that
        // doesn't have a title of "1st Item" exactly.
        let predicate = NSPredicate(format: "title == %@", categoryTitle)
        
        // Set the predicate on the fetch request
        fetchRequest.predicate = predicate
        
        if let fetchResults = managedObjectContext.executeFetchRequest(fetchRequest, error: nil) as? [Category] {
            if (fetchResults.count > 0){
                var cat = fetchResults[0] as Category
                return cat.id.integerValue
            }
        }
        return -1
    }
}
