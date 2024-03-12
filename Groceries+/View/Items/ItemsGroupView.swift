//
//  ItemsGroupView.swift
//  Groceries+
//
//  Created by Tobías Naftali on 2024-03-09.
//

import SwiftUI
import SwiftData
import Foundation

struct ItemsGroupView: View {
  @Query(sort: \Item.name) private var items: [Item]
  var category: Category?
  @Binding var searchText: String
  
  var body: some View {
    var filteredCategoryItems: [Item] {
      if searchText.isEmpty {
        return items.filter { $0.category == category }
      } else {
        return items.filter { $0.category == category && $0.name.localizedCaseInsensitiveContains(searchText) }
      }
    }
    
    VStack(spacing: 5) {
      let indicesTwoByTwo = Array(stride(from: 0, through: filteredCategoryItems.count - 1, by: 2))
      ForEach(indicesTwoByTwo, id: \.self) { index in
        let item1 = filteredCategoryItems.count > index ? filteredCategoryItems[index] : nil
        let item2Index = index + 1
        let item2 = filteredCategoryItems.count > item2Index ? filteredCategoryItems[item2Index] : nil
        
        if item1 != nil || item2 != nil {
          HStack {
            if let item1 = item1 {
              ItemView(item: item1)
            } else {
              GeometryReader { geometry in
                Color.clear.frame(width: geometry.size.width * 0.5)
              }
            }
            
            if let item2 = item2 {
              ItemView(item: item2)
            } else {
              GeometryReader { geometry in
                Color.clear.frame(width: geometry.size.width * 0.5)
              }
            }
          }
          .padding(.horizontal, 10)
        }
      }
    }
  }
}

//#Preview {
//  ItemsGroupView()
//}
