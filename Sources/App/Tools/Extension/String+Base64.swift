//
//  String+Base64.swift
//  
//
//  Created by Alif on 19/6/20.
//

import Foundation

extension String {

    func base64Encoded() -> String? {
        return data(using: .utf8)?.base64EncodedString()
    }

    func base64Decoded() -> String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

private let allowedCharacterSet: CharacterSet = {
  var set = CharacterSet.decimalDigits
  set.insert("+")
  return set
}()

extension String {
    static func randomDigits(ofLength length: Int) -> String {
      guard length > 0 else {
        fatalError("randomDigits must receive length > 0")
      }

      var result = ""
      while result.count < length {
        result.append(String(describing: Int.random(in: 0...9)))
      }

      return result
    }

    var removingInvalidCharacters: String {
      return String(unicodeScalars.filter { allowedCharacterSet.contains($0) })
    }
}

extension String {
    static func random(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
}
