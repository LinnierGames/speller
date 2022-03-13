//
//  WordsTableViewController.swift
//  Speller
//
//  Created by Erick Sanchez on 3/12/22.
//  Copyright © 2022 Erick Sanchez. All rights reserved.
//

import UIKit
import CoreData

class WordsTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
  private var wordBank: NSFetchedResultsController<WordData>!

  @IBAction func pressAddWord() {
    let alert = UIAlertController(title: "Add word", message: "enter new word here", preferredStyle: .alert)
    alert.addTextField { tf in
      tf.autocapitalizationType = .words
      tf.autocorrectionType = .yes
    }

    alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { _ in
      let tf = alert.textFields!.first!
      let newWord = tf.text ?? "Untitled"
      WordsBankStore.shared.add(newWord)
    }))
    present(alert, animated: true)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    let context = WordsBankStore.shared.container.viewContext
    let fetchRequest = WordData.fetchRequest()
    // Configure the request's entity, and optionally its predicate
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "word", ascending: true)]
    let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
    do {
      try controller.performFetch()
    } catch {
      fatalError("Failed to fetch entities: \(error)")
    }
    wordBank = controller
    wordBank.delegate = self
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    if let frc = wordBank {
      return frc.sections!.count
    }
    return 0
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    guard let sections = wordBank?.sections else {
      fatalError("No sections in fetchedResultsController")
    }
    let sectionInfo = sections[section]
    return sectionInfo.numberOfObjects
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    guard let object = wordBank?.object(at: indexPath) else {
      fatalError("Attempt to configure cell without a managed object")
    }
    // Configure the cell with data from the managed object.
    cell.textLabel?.text = object.word

    return cell
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    guard let sectionInfo = wordBank?.sections?[section] else {
      return nil
    }
    return sectionInfo.name
  }

  override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
    return wordBank?.sectionIndexTitles
  }

  override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
    guard let result = wordBank?.section(forSectionIndexTitle: title, at: index) else {
      fatalError("Unable to locate section for \(title) at index: \(index)")
    }
    return result
  }

  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    switch editingStyle {
    case .delete:
      guard let object = wordBank?.object(at: indexPath) else {
        fatalError("Attempt to configure cell without a managed object")
      }

      WordsBankStore.shared.delete(object)
    default:
      break
    }
  }

  func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    tableView.beginUpdates()
  }

  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
    switch (type) {
    case .insert:
      guard let indexPath = newIndexPath else {
        return
      }

      tableView.insertRows(at: [indexPath], with: .fade)
    case .delete:
      guard let indexPath = indexPath else {
        return
      }

      tableView.deleteRows(at: [indexPath], with: .fade)
    default:
      break
    }
  }

  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    tableView.endUpdates()
  }
}
