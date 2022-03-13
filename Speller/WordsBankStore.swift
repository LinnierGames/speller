//
//  WordsBankStore.swift
//  Speller
//
//  Created by Erick Sanchez on 3/12/22.
//  Copyright © 2022 Erick Sanchez. All rights reserved.
//

import CoreData

class WordsBankStore {
  static let shared = WordsBankStore()
  
  //    static var preview: PersistenceController = {
  //        let result = PersistenceController(inMemory: true)
  //        let viewContext = result.container.viewContext
  //        for _ in 0..<10 {
  //            let newItem = Sleep(context: viewContext)
  //            newItem.timestamp = Date()
  //          newItem.activity = "Driving"
  //        }
  //        do {
  //            try viewContext.save()
  //        } catch {
  //            // Replace this implementation with code to handle the error appropriately.
  //            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
  //            let nsError = error as NSError
  //            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
  //        }
  //        return result
  //    }()
  
  let container: NSPersistentContainer
  
  init(inMemory: Bool = false) {
    container = NSPersistentContainer(name: "WordsBank")
    if inMemory {
      container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
    }
    container.viewContext.automaticallyMergesChangesFromParent = true
    container.loadPersistentStores(completionHandler: { (storeDescription, error) in
      if let error = error as NSError? {
        // Replace this implementation with code to handle the error appropriately.
        // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        
        /*
         Typical reasons for an error here include:
         * The parent directory does not exist, cannot be created, or disallows writing.
         * The persistent store is not accessible, due to permissions or data protection when the device is locked.
         * The device is out of space.
         * The store could not be migrated to the current model version.
         Check the error message to determine what the actual problem was.
         */
        fatalError("Unresolved error \(error), \(error.userInfo)")
      }
    })
  }
  
  func words() -> [WordData] {
    let fetch = WordData.fetchRequest()
    return try! container.viewContext.fetch(fetch)
  }

  func add(_ word: String) {
    let newWord = WordData(context: container.viewContext)
    newWord.word = word

    try! container.viewContext.save()
  }

  func populate() {
    let newWord = WordData(context: container.viewContext)
    newWord.word = "Delegate"

    try! container.viewContext.save()
  }

  func delete(_ wordData: WordData) {
    container.viewContext.delete(wordData)
    try! container.viewContext.save()
  }
}
