//
//  Word.swift
//  EasyCommunication
//
//  Created by CSSE Department on 2/4/15.
//  Copyright (c) 2015 CSSE Department. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class Word: NSManagedObject {

    @NSManaged var word: String
    @NSManaged var image: NSData
    @NSManaged var recording: NSData
    @NSManaged var categoryIds: String
    @NSManaged var timesUsed: NSNumber
    @NSManaged var imageOrientation: NSNumber

    class func createInManagedObjectContext(moc: NSManagedObjectContext, word: String, recording: NSData, image: NSData, categoryIds: String, imageOrientation: NSNumber) -> Word {
        let newWord = NSEntityDescription.insertNewObjectForEntityForName("Word", inManagedObjectContext: moc) as Word
        newWord.word = word
        newWord.recording = recording
        newWord.image = image
        newWord.categoryIds = categoryIds
        newWord.imageOrientation = imageOrientation
        
        return newWord
    }
}
