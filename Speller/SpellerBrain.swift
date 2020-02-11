//
//  SpellerBrain.swift
//  Speller
//
//  Created by Erick Sanchez on 1/13/20.
//  Copyright © 2020 Erick Sanchez. All rights reserved.
//

import Foundation

enum CharacterRemoveMethod {
  case random
  case leading
  case trailing
}

struct SpellerDifficulty {
  let precentageOfWordsMissing: Float
}

class SpellerBrain {

  var answer: String? {
    return self.currentWordString
  }

  private let words = SpellerBrain.words
  private var currentWordString: String?

  func newGame(difficulty: SpellerDifficulty) -> Word {

    //    let lengthOfWord
    let percentageOfWordMissing = difficulty.precentageOfWordsMissing

    let wordData = self.words.randomElement()!
    self.currentWordString = wordData.word

    let maxNumberOfMissingLetters = Int(Float(wordData.word.count) * percentageOfWordMissing)
    var nMissingLetters = 0

    let wordDescriptions = wordData.word.map { character -> WordDescription in
      guard nMissingLetters < maxNumberOfMissingLetters else {
        return .letter(String(character))
      }

      let removeLetter = Int.random(in: 0...1) == 0
      if removeLetter {
        nMissingLetters += 1
        return .missingLetter
      } else {
        return .letter(String(character))
      }
    }

    guard nMissingLetters > 0 else { return self.newGame(difficulty: difficulty) }

    let w = Word(description: wordDescriptions, imageURL: wordData.imageURL)

    return w
  }

  func check(_ input: String) -> Bool {
    return input.lowercased() == self.currentWordString?.lowercased()
  }
}
