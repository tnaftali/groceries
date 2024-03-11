//
//  ItemList.swift
//  Groceries+
//
//  Created by Tobías Naftali on 2024-03-03.
//

import SwiftUI
import SwiftData
import Foundation

struct ItemList: View {
  @Query(sort: \Item.name) private var items: [Item]
  @Query(sort: \Category.name) private var categories: [Category]
  @Environment(\.colorScheme) var colorScheme
  @State private var searchText = ""
  @FocusState private var isFocused: Bool
  
  var body: some View {
    var filteredItems: [Item] {
      if searchText.isEmpty {
        return items
      } else {
        return items.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
      }
    }
    
    NavigationStack {
      VStack {
        TextField("Search", text: $searchText)
          .focused($isFocused)
          .padding(.horizontal, 35)
          .padding(.vertical, 10)
          .background(Color(.systemGray6))
          .cornerRadius(10)
          .padding(.leading)
          .padding(.trailing)
          .padding(.top, 20)
          .padding(.bottom, 5)
          .overlay(
            HStack {
              Image(systemName: "magnifyingglass")
                .foregroundColor(Color(.systemGray2))
                .opacity(0.7)
                .padding(.leading, 8)
                .padding(.top, 15)
              Spacer()
              Button(action: {
                searchText = ""
              }) {
                if searchText != "" {
                  Image(systemName: "xmark.circle.fill")
                    .foregroundColor(Color(.systemGray2))
                    .opacity(0.4)
                    .padding(.trailing, 8)
                    .padding(.top, 15)
                }
              }
            }
            .padding(.horizontal, 16)
          )
          .autocorrectionDisabled()
          
        let noCategoryItemsCount = filteredItems.filter { $0.category == nil }.count
        if noCategoryItemsCount > 0 {
          Divider()
        }
          
        VStack {
          ScrollView {
            VStack(spacing: 5) {
              ItemsGroup(category: nil, searchText: $searchText)
              
              ForEach(categories, id: \.self) { category in
                let categoryHasItems = filteredItems.filter { $0.category == category }.count > 0
                if categoryHasItems {
                  GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                      Rectangle()
                        .foregroundColor(Color(.systemGray5))
                        .frame(width: geometry.size.width)
                      Text(category.name)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .padding(.leading, 10)
                    }
                  }
                  .frame(height: 35)
                  
                  ItemsGroup(category: category, searchText: $searchText)
                }
              }
            }
          }
          .onTapGesture {
            isFocused = false
          }
          .navigationBarItems(
            leading:
              Text("Groceries+")
              .font(.largeTitle)
              .fontWeight(.bold)
              .foregroundColor(.primary)
              .padding(.top, 20),
            trailing: NavigationLink(destination: NewCategoryView()) {
              Text("Add Category")
                .padding(.top, 20)
            }
          )
          
          HStack {
            Spacer()
            NavigationLink(destination: NewItemView()) {
              Image(systemName: "plus")
                .font(.system(size: 40))
                .padding(10)
                .padding(.horizontal, 20)
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(Circle())
                .shadow(radius: 8)
            }
          }
        }
      }
    }
    .preferredColorScheme(colorScheme == .dark ? .dark : .light)
  }
}

#Preview {
  ItemList()
    .modelContainer(previewContainer)
}
