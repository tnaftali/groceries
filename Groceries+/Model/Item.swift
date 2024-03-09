//
//  Item.swift
//  Groceries+
//
//  Created by Tobías Naftali on 2024-03-03.
//

import Foundation
import SwiftData

@Model
final class Item {
  var id: UUID
  var name: String
  var checked: Bool
  var creationDate: Date
  
  init(id: UUID = UUID(), name: String, checked: Bool, creationDate: Date = .now) {
    self.id = id
    self.name = name
    self.checked = checked
    self.creationDate = creationDate
  }
}

extension Item: Identifiable { }

extension Item: Hashable {
  static func == (lhs: Item, rhs: Item) -> Bool {
    lhs.id == rhs.id
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
