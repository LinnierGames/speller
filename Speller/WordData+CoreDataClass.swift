//
//  WordData+CoreDataClass.swift
//  Speller
//
//  Created by Erick Sanchez on 3/12/22.
//  Copyright © 2022 Erick Sanchez. All rights reserved.
//
//

import Foundation
import CoreData

@objc(WordData)
public class WordData: NSManagedObject {
  @nonobjc public class func fetchRequest() -> NSFetchRequest<WordData> {
      return NSFetchRequest<WordData>(entityName: "Word")
  }

  @NSManaged public var word: String
  @NSManaged public var imageURL: URL?
}
