//
//  ViewController.swift
//  Speller
//
//  Created by Erick Sanchez on 1/13/20.
//  Copyright © 2020 Erick Sanchez. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
  
  let speller = SpellerBrain()
  
  let mindfulnessSession = MindfullHealthKitService()
  
  var word: GameWord!
  
  @IBOutlet weak var imageViewHint: UIImageView!
  @IBOutlet weak var wordTextFieldStackView: UIStackView!
  @IBOutlet weak var missingLettersSlider: UISlider!
  @IBOutlet weak var autoSpeakSwitch: UISwitch!
  
  private let synthesizer = AVSpeechSynthesizer()
  
  func startGame() {
    self.word = self.speller.newGame(difficulty: SpellerDifficulty(precentageOfWordsMissing: self.missingLettersSlider.value))
    
    self.wordTextFieldStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
    var firstTextfield: UITextField!
    var previousTextfield: CharacterTextField?
    let fontSize: CGFloat = 24
    let largeFont = UIFont.boldSystemFont(ofSize: fontSize)
    for description in self.word {
      switch description {
      case .missingLetter:
        let textfield = CharacterTextField()
        textfield.borderStyle = .line
        textfield.font = largeFont
        textfield.textAlignment = .center
        self.wordTextFieldStackView.addArrangedSubview(textfield)
        
        if firstTextfield == nil {
          textfield.widthAnchor.constraint(equalToConstant: fontSize).isActive = true
          firstTextfield = textfield
        }
        
        if let childTextfield = previousTextfield {
          childTextfield.nextTextField = textfield
          textfield.previousTextField = childTextfield
        }
        
        previousTextfield = textfield
      case .letter(let string):
        let label = UILabel()
        label.font = largeFont
        label.text = string.uppercased()
        label.textAlignment = .center
        self.wordTextFieldStackView.addArrangedSubview(label)
      }
    }
    
    previousTextfield?.nextTextField = ResponderBox { [weak self] in
      previousTextfield?.resignFirstResponder()
      self?.spellCheck()
    }
    
    self.imageViewHint.image = try? self.word.imageURL
      .map { try Data.init(contentsOf: $0) }
      .flatMap { UIImage(data: $0) }
    
    if autoSpeakSwitch.isOn {
      speakAnswer()
    }
    
    DispatchQueue.main.async {
      firstTextfield.becomeFirstResponder()
    }
  }
  
  @IBAction func pressSpeak(_ sender: Any) {
    self.speakAnswer()
  }
  
  @IBAction func pressSkip(_ sender: Any) {
    self.startGame()
  }
  
  @IBAction func pressReveal(_ sender: Any) {
    self.revealAnswer()
  }
  
  @IBAction func didTapBackground(_ sender: Any) {
    self.view.endEditing(true)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(ViewController.applicationDidBecomeActive),
      name: UIApplication.didBecomeActiveNotification,
      object: nil)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(ViewController.applicationWillResignActive),
      name: UIApplication.willResignActiveNotification,
      object: nil)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.startGame()
  }
  
  // MARK: - Private
  
  @objc private func applicationDidBecomeActive() {
    self.mindfulnessSession.startSession()
  }
  
  @objc private func applicationWillResignActive() {
    self.mindfulnessSession.endSession()
  }
  
  private func speakAnswer() {
    guard let answerToSpeak = self.speller.answer else { return }
    
    let utterance = AVSpeechUtterance(string: answerToSpeak)
    self.synthesizer.speak(utterance)
  }
  
  private func revealAnswer() {
    for (index, description) in self.word.enumerated() {
      guard case .missingLetter = description else { continue }
      
      guard self.wordTextFieldStackView.arrangedSubviews.indices.contains(index),
            let textfield = self.wordTextFieldStackView.arrangedSubviews[index] as? UITextField
      else {
        continue
      }
      
      let string = self.speller.answer!
      textfield.text = String(string[string.index(string.startIndex, offsetBy: index)]).uppercased()
      textfield.isEnabled = false
    }
  }
  
  private func spellCheck() {
    let input = self.wordTextFieldStackView.arrangedSubviews.compactMap { view -> String? in
      if let label = view as? UILabel {
        return label.text!
      } else if let textfield = view as? UITextField {
        return textfield.text!
      }
      
      return nil
    }.reduce("", +)
    
    guard self.speller.check(input) else {
      self.displayMisspelledWord()
      self.mindfulnessSession.markIncorrect(word: self.speller.answer!)
      return
    }
    
    self.displayCorrectSpelling()
    self.mindfulnessSession.markCorrect(word: self.speller.answer!)
  }
  
  private func displayMisspelledWord() {
    let alert = UIAlertController(title: nil, message: "oops", preferredStyle: .alert)
    //    alert.addAction(UIAlertAction(title: "Try Again", style: .default, handler: nil))
    self.present(alert, animated: true) {
      DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250)) {
        self.dismiss(animated: true)
      }
    }
  }
  
  private func displayCorrectSpelling() {
    let alert = UIAlertController(title: nil, message: "yay!!", preferredStyle: .alert)
    //    alert.addAction(UIAlertAction(title: "Go Again", style: .default) { _ in self.startGame() })
    self.present(alert, animated: true) {
      DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250)) {
        self.dismiss(animated: true) {
          self.startGame()
        }
      }
    }
  }
}

class ResponderBox: UIResponder {
  private let block: () -> Void
  
  init(_ block: @escaping () -> Void) {
    self.block = block
  }
  
  override var canBecomeFirstResponder: Bool {
    return true
  }
  
  override func becomeFirstResponder() -> Bool {
    defer { self.block() }
    return true
  }
}

class CharacterTextField: UITextField, UITextFieldDelegate {
  
  var nextTextField: UIResponder?
  var previousTextField: UIResponder?
  
  init() {
    super.init(frame: .zero)
    self.delegate = self
  }
  
  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func textFieldDidBeginEditing(_ textField: UITextField) {
    
    // remove current character if not empty
    guard (textField.text?.isEmpty ?? true) == false else { return }
    textField.text = ""
  }
  
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    if string.isEmpty {
      return true
    }
    
    DispatchQueue.main.async {
      self.findNextEmptyTextField()
    }
    
    return true
  }
  
  override func deleteBackward() {
    super.deleteBackward()
    
    DispatchQueue.main.async {
      self.previousTextField?.becomeFirstResponder()
    }
  }
  
  private func findNextEmptyTextField() {
    var current = self
    while let next = current.nextTextField {
      guard let textfield = next as? CharacterTextField else {
        next.becomeFirstResponder()
        break
      }
      
      guard textfield.text?.isEmpty ?? true else {
        current = textfield
        continue
      }
      
      textfield.becomeFirstResponder()
      break
    }
  }
}
