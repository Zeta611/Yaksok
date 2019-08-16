//
//  String+*.swift
//  Yaksok
//
//  Created by Jaeho Lee on 2019/08/17.
//  Copyright © 2019 Jay Lee. All rights reserved.
//

import Foundation

extension String {
  static func * (lhs: String, rhs: Int) -> String {
    return Array(repeating: lhs, count: rhs).joined()
  }
}
