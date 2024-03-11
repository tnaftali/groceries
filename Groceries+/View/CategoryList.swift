//
//  CategoryList.swift
//  Groceries+
//
//  Created by Tobías Naftali on 2024-03-09.
//

import SwiftUI
import SwiftData

struct CategoryList: View {
  @Query private var categories: [Category]
  
  var body: some View {
    List(categories, id: \.id) { category in
      Text(category.name)
    }
  }
}

#Preview {
  CategoryList()
    .modelContainer(previewContainer)
}
