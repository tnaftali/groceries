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
  var oneTime: Bool = false
  var important: Bool = false
  var quantity: Int = 1

  init(id: UUID = UUID(), name: String, checked: Bool = false, category: Category? = nil, creationDate: Date = .now, oneTime : Bool = false, important : Bool = false, quantity : Int = 1) {
    self.id = id
    self.name = name
    self.checked = checked
    self.category = category
    self.creationDate = creationDate
    self.oneTime = oneTime
    self.important = important
    self.quantity = quantity
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
