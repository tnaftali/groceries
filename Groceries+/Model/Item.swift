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
  var checked: Bool = false
  var category: Category?
  var creationDate: Date
  var recurring: Bool = true

  init(id: UUID = UUID(), name: String, checked: Bool = false, category: Category? = nil, creationDate: Date = .now, recurring: Bool = true) {
    self.id = id
    self.name = name
    self.checked = checked
    self.category = category
    self.creationDate = creationDate
    self.recurring = recurring
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
