//
//  Word.swift
//  Speller
//
//  Created by Erick Sanchez on 2/11/20.
//  Copyright © 2020 Erick Sanchez. All rights reserved.
//

import Foundation

struct Word: Collection {
  var imageURL: URL?

  var startIndex: Int { return self.description.startIndex }
  var endIndex: Int { return self.description.endIndex }

  private let description: [WordDescription]

  init(description: [WordDescription], imageURL: URL?) {
    self.description = description
    self.imageURL = imageURL
  }

  subscript(index: Int) -> WordDescription {
    return self.description[index]
  }

  func index(after index: Int) -> Int {
    return self.description.index(after: index)
  }
}

enum WordDescription {
  case letter(String)
  case missingLetter
}

struct WordData {
  let word: String
  let imageURL: URL?
}

extension SpellerBrain {
  static let words: [WordData] = {
    let dropBoxURL = "https://www.dropbox.com/s/9q65vdch12ifcfn/Speller.txt?raw=1"
    let data = try! Data(contentsOf: URL(string: dropBoxURL)!)
    let text = String(data: data, encoding: .utf8)!

    return text.components(separatedBy: "\n").compactMap { wordData in
      let components = wordData.split(separator: ",")
      guard components.count == 1 || components.count == 2 else { return nil }
      let url = components.count == 2 ? URL(string: String(components[1])) : nil
      let word = String(components[0]).replacingOccurrences(of: "\r", with: "")
      return WordData(word: word, imageURL: url)
    }
  }()
}


