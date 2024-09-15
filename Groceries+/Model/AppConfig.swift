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
  var uncategorizedItemsExpanded : Bool = true

  init(id: UUID = UUID(), checkedFilter: Bool = false, uncategorizedItemsExpanded : Bool = true) {
    self.id = id
    self.checkedFilter = checkedFilter
    self.uncategorizedItemsExpanded = uncategorizedItemsExpanded
  }
}
