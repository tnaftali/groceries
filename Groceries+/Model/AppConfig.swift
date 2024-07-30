//
//  AppConfig.swift
//  Groceries+
//
//  Created by Tobías Naftali on 2024-07-24.
//

import Foundation
import SwiftData

@Model
final class AppConfig {
  var id: UUID
  var checkedFilter: Bool

  init(id: UUID = UUID(), checkedFilter: Bool = false) {
    self.id = id
    self.checkedFilter = checkedFilter
  }
}
