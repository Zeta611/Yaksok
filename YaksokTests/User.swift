//
//  User.swift
//  YaksokTests
//
//  Created by Jaeho Lee on 17/08/2019.
//  Copyright © 2019 Jay Lee. All rights reserved.
//

import Foundation
@testable import Yaksok

struct User: Equatable {
  var username: String
  var password: String


  static func login(username: String, password: String) -> Promise<User> {
    return Promise<User> { resolve in
      DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 3) {
        if password == "yaksok" {
          resolve(.success(User(username: username, password: password)))
        } else {
          resolve(.failure(UserError.passwordError))
        }
      }
    }
  }


  enum UserError: LocalizedError {
    case passwordError

    var localizedDescription: String {
      switch self {
      case .passwordError: return "Incorrect password was given."
      }
    }
  }
}
