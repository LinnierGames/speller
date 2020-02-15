//
//  MindfulHealthKit.swift
//  Speller
//
//  Created by Erick Sanchez on 2/15/20.
//  Copyright © 2020 Erick Sanchez. All rights reserved.
//

import HealthKit

struct MindfulnessPerformance {
  let correctWordCount: Int
  let incorrectWordCount: Int
}

class MindfullHealthKitService {

  private let healthStore = HKHealthStore()

  private var currentSessionStartDate: Date?
  private var nCorrectWords = 0
  private var correctWords = Set<String>()
  private var nIncorrectWords = 0
  private var incorrectWords = Set<String>()

  func startSession() {
    if self.currentSessionStartDate != nil {
      self.endSession()
    }

    self.currentSessionStartDate = Date()
    self.nCorrectWords = 0
    self.nIncorrectWords = 0

    self.authenticate { _ in }
  }

  func markCorrect(word: String) {
    // Do not mark word correct if word was previously misspelled.
    if !self.incorrectWords.contains(word) {
      self.correctWords.insert(word)
    }
    self.nCorrectWords += 1
  }

  func markIncorrect(word: String) {
    self.incorrectWords.insert(word)
    self.nIncorrectWords += 1
  }

  func endSession() {
    guard let startDate = self.currentSessionStartDate else {
      print("no start date set")
      return
    }

    let endDate = Date()

    guard self.isAvailable() else {
      print("health kit is no available")
      return
    }

    self.authenticate { authorized in
      guard authorized else {
        print("not authorized for health kit")
        return
      }

      guard self.isAuthorizedForMindfulness() else {
        print("not authorized for mindfulness")
        return
      }

      self.saveMindfulnessSession(start: startDate, end: endDate)
    }
  }

  private func isAvailable() -> Bool {
    return HKHealthStore.isHealthDataAvailable()
  }

  private func authenticate(complition: @escaping (Bool) -> Void) {
    let types = Set([
      HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.mindfulSession)!,
    ])

    self.healthStore.requestAuthorization(toShare: types, read: nil) { success, error in
      guard success else {
        print(error as Any)
        return complition(false)
      }

      complition(true)
    }
  }

  private func isAuthorizedForMindfulness() -> Bool {
    let status = self.healthStore.authorizationStatus(
      for: HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.mindfulSession)!
    )

    switch status {
    case .sharingAuthorized:
      return true
    default:
      return false
    }
  }

  private func saveMindfulnessSession(start: Date, end: Date) {
    let mindfulType = HKQuantityType.categoryType(forIdentifier: .mindfulSession)!
    let spellingSession = HKCategorySample(
      type: mindfulType,
      value: HKCategoryValue.notApplicable.rawValue,
      start: start,
      end: end,
      metadata: [
        "Total words": NSNumber(value: self.correctWords.count + self.incorrectWords.count),
        "Correct words": self.correctWords.joined(separator: ", ") as NSString,
        "Incorrect words": self.incorrectWords.joined(separator: ", ") as NSString,
        "Number of misspellings": NSNumber(value: self.nIncorrectWords),
      ]
    )

    self.healthStore.save(spellingSession) { (success, error) in
      guard success else {
        print("failed to save mindfulness session", error as Any)
        return
      }

      print("saved mindfulness session")
    }
  }
}
