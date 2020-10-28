/*
 * Monoalphabetic substitution decryption tool in Swift by Andrew Lubinger
 *
 * Not necessarily the most efficient, but it's not brute force.
 * Uses an algorithm with actual scoring.
 *
 * Enter your ciphertext and maximum number of guesses.
 * It'll use English frequency analysis for tetragrams to hopefully find the correct plaintext.
 *
 * In Windows, after Swift is installed correctly, compile and run with the following commands in an admin x64 VS 2019 Command Prompt
 * set SWIFTFLAGS=-sdk %SDKROOT% -resource-dir %SDKROOT%/usr/lib/swift -I %SDKROOT%/usr/lib/swift -L %SDKROOT%/usr/lib/swift/windows
 * swiftc %SWIFTFLAGS% -emit-executable -o Monoalphabetic.exe main.swift tetragrams.swift
 * Monoalphabetic.exe
 *
 * Or just run the already compiled executable by going in command prompt and entering Monoalphabetic.exe.
 * Compilation will take about 20 minutes due to the size of the tetragrams dictionary.
 * Running time for 2500 guesses should take some time between ~3-15 minutes.
 */

import Foundation

//First entry point.

//User inputs
//Ciphertext, spaces can be included
print("Enter the ciphertext:\n")
let ciphertext = readLine()!.replacingOccurrences(of: " ", with: "").lowercased()
//Ask how many tries until just returning the best result. Too large and it might not ever print the best result, too few and it might be close but not quite make it.
//It seems to get the answer pretty quickly, at least compared to playfair, so I'll recommend 2.5k instead of the playfair recommended 20k I used for that program.
print("What is the maximum number of guesses I can make? I recommend 2500.\n")
let maximumTries = Int(readLine()!)!

let alphabet = ["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"]

//Decipher using the key
//Takes the key as a paramter
//Returns the plaintext
func decipher(key: [String]) -> String {
  //Use the key to decipher
  var answer = ""

  //Find the index the letter is in the regular alphabet, and get the letter at that position in the key.
  for char in ciphertext {
    let i = alphabet.firstIndex(of: String(char)) ?? alphabet.endIndex
    answer += key[i]
  }

  return answer
}

var shouldTryAgain = false
var usedKeys = Set<[String]>()

//Useful extension to rotate an array.
extension RangeReplaceableCollection {
  mutating func rotateRight(positions: Int) {
    let index = self.index(endIndex, offsetBy: -positions, limitedBy: startIndex) ?? startIndex
    let slice = self[index...]
    removeSubrange(index...)
    insert(contentsOf: slice, at: startIndex)
  }
}

//Get a new key.
//Make sure it's not in the usedKeys set.
func keyFrom(key: [String]) -> [String] {
  //Either make a letter swap, or rotate the entire key a number of positions.
  var newKey = key
  var attempts = 0
  var n1 = -1
  var n2 = -1
  var option = -1
  //Try to get a new key but need to stop trying after a certain number of attempts so we don't get stuck.
  while(usedKeys.contains(newKey) && attempts < 100000) {
    attempts += 1
    newKey = key

    //Choose a random option
    //We should definitely do more letter swaps than rotations though.
    option = Int.random(in: 0...100)
    switch option {
      case 1:
        //Rotate entire key.
        newKey.rotateRight(positions: Int.random(in: 1..<key.count))

      default:
        //Swap letters
        n1 = Int.random(in: 0..<key.count)
        n2 = Int.random(in: 0..<key.count)
        let i = newKey[n1]
        newKey[n1] = newKey[n2]
        newKey[n2] = i
    }
  }
  if(attempts == 100000) {
    shouldTryAgain = true
    print("ERROR: Can't find an unused key variation.") //Not actually an error, but it can be helpful to see that it is resetting with a new random key.
  } else {
    usedKeys.insert(newKey)
  }
  return newKey
}

//Calculate the score of the plaintext.
//Specifically, find the tetragrams in the plaintext and add their english frequency value to the score.
//score = sum(quartet.each { $0.englishFreq })
//Higher score is better
func getScore(text: String) -> Double {
  var score = 0.0
  for pairPos in 0..<text.count - 3 {
    //For each quartet in the plaintext, find its frequency and add it to the score.
    let quartet = String(text[text.index(text.startIndex, offsetBy: pairPos)...text.index(text.startIndex, offsetBy: pairPos + 3)])
    if let englishFrequency = tetragrams[quartet] {
      score += englishFrequency
    }
  }
  return score
}

//Some variables
var tries = 0
var key = alphabet.shuffled()
var topKey = key
var topNewKey = key
var topScore = -1.0
var topNewScore = -1.0
var topPlaintext = ""
var topAttempt = 0

//Main program entry point.

//Run monoalphabetic substitution over and over with different keys keeping track of the best 
//option of plaintext/key. At that point, show the user the possible plaintext and key.
//Also show each time the new top score is found
while(tries < maximumTries) {
  if(shouldTryAgain) {
    //Struggling to find a new key from this variation, start again with a new random key.
    shouldTryAgain = false
    topNewScore = -1.0
    key = alphabet.shuffled()
  } else {
    //Get next key normally.
    key = keyFrom(key: topNewKey)
  }
  let plaintext = decipher(key: key)
  let score = getScore(text: plaintext)
  //Higher score is better
  if(score >= topNewScore) {
    topNewScore = score
    topNewKey = key
    print("\n\n")
    print(plaintext)
    print(score)
    print(key)
    print("\n\n")
    if(score >= topScore) {
      topScore = score
      topKey = key
      topPlaintext = plaintext
      topAttempt = tries
    }
  }
  tries += 1
}
print("\n\nTop score was:")
print(topScore)
print("with key:")
print(topKey)
print("on attempt number:")
print(topAttempt)
print("resulting in:")
print(topPlaintext)
