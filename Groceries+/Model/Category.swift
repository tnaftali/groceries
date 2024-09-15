//
//  Category.swift
//  Groceries+
//
//  Created by Tobías Naftali on 2024-03-09.
//

import Foundation
import SwiftData

@Model
final class Category {
  var id: UUID
  var name: String
  @Relationship(deleteRule: .nullify, inverse: \Item.category) var items: [Item]
  var creationDate: Date
  var expanded: Bool = true

  init(id: UUID = UUID(), name: String, items: [Item] = [], creationDate: Date = .now, expanded: Bool = true) {
    self.id = id
    self.name = name
    self.items = items
    self.creationDate = creationDate
    self.expanded = expanded
  }
}

extension Category: Identifiable { }

extension Category: Hashable {
  static func == (lhs: Category, rhs: Category) -> Bool {
    lhs.id == rhs.id
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
