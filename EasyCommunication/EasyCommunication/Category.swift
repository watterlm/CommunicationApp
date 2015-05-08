//
//  Category.swift
//  EasyCommunication
//
//  Created by CSSE Department on 2/4/15.
//  Copyright (c) 2015 CSSE Department. All rights reserved.
//

import Foundation
import CoreData

class Category: NSManagedObject {

    @NSManaged var id: NSNumber
    @NSManaged var title: String
    @NSManaged var isSpecific: NSNumber
    @NSManaged var recording: NSData
    @NSManaged var timesUsed: NSNumber

    class func createInManagedObjectContext(moc: NSManagedObjectContext, title: String, isSpecific: NSNumber, recording: NSData) -> Category {
        let newCategory = NSEntityDescription.insertNewObjectForEntityForName("Category", inManagedObjectContext: moc) as Category
        newCategory.title = title
        newCategory.isSpecific = isSpecific
        if (isSpecific.boolValue){
            newCategory.recording = recording
        }
        newCategory.id = NSNumber(int: (fetchMaxIDLog(moc).intValue + 1))
        return newCategory
    }
    
    class func fetchMaxIDLog(managedObjectContext: NSManagedObjectContext) -> NSNumber{
        let fetchRequest = NSFetchRequest(entityName: "Category")
        
        // Create a sort descriptor object that sorts on the "title"
        // property of the Core Data object
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: false)
        
        // Set the list of sort descriptors in the fetch request,
        // so it includes the sort descriptor
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        if let fetchResults = managedObjectContext.executeFetchRequest(fetchRequest, error: nil) as? [Category] {
            return fetchResults[0].id
        }
        return -1
    }
}
