//
//  ItemListView.swift
//  Groceries+
//
//  Created by Tobías Naftali on 2024-03-03.
//

import SwiftUI
import SwiftData
import Foundation

struct ItemListView: View {
  @Query(sort: \Item.name) private var items: [Item]
  @Query(sort: \Category.name) private var categories: [Category]
  @Environment(\.colorScheme) var colorScheme
  @State private var searchText = ""
  @State private var toggleChecked = false
  @FocusState private var isFocused: Bool
  
  var body: some View {
    var filteredItems: [Item] {
      if searchText.isEmpty {
        return toggleChecked ? items.filter { $0.checked == toggleChecked } : items
      } else {
        return toggleChecked ? items.filter { $0.checked == toggleChecked && $0.name.localizedCaseInsensitiveContains(searchText) } : items.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
      }
    }
    
    NavigationStack {
      VStack {
        TextField("Search", text: $searchText)
          .focused($isFocused)
          .padding(.horizontal, 35)
          .padding(.vertical, 10)
          .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
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
        
        if filteredItems.count == 0 {
          Divider()
          Text("🛒 No pending groceries")
            .font(.system(size: 18))
            .foregroundColor(.primary)
            .padding(.top, 20)
        }

        ScrollView {
          VStack(spacing: 5) {
            ItemsGroupView(category: nil, searchText: $searchText, toggleChecked: $toggleChecked)
            
            ForEach(categories, id: \.self) { category in
              let categoryHasItems = filteredItems.filter { $0.category == category }.count > 0
              if categoryHasItems {
                GeometryReader { geometry in
                  ZStack(alignment: .leading) {
                    Rectangle()
                      .foregroundColor(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                      .frame(width: geometry.size.width)
                    NavigationLink(destination: EditCategoryView(category: category)) {
                      HStack(alignment: .center) {
                        Text(category.name)
                          .font(.system(size: 16))
                          .opacity(0.9)
                          .fontWeight(.semibold)
                          .foregroundColor(.primary)
                          .padding(.leading, 10)
                        Image(systemName: "chevron.right")
                          .foregroundColor(.primary)
                          .font(.system(size: 16, weight: .semibold))
                      }
                    }
                  }
                }
                .frame(height: 30)
                
                ItemsGroupView(category: category, searchText: $searchText, toggleChecked: $toggleChecked)
              }
            }
          }
          .padding(.bottom, 80)
        }
      }
      .overlay(
        ZStack {
          GeometryReader { geometry in
            HStack {
              Spacer()
              VStack {
                Button(action: {
                  toggleChecked.toggle()
                }) {
                  Image(systemName: toggleChecked ? "checklist.unchecked" : "checklist.checked")
                    .font(.system(size: 28))
                    .padding(12)
                    .padding(.horizontal, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Circle())
                    .shadow(radius: 8)
                    .padding(.bottom, 10)
                }
                
                NavigationLink(destination: NewItemView()) {
                  Image(systemName: "plus")
                    .font(.system(size: 28))
                    .padding(12)
                    .padding(.horizontal, 10)
                    .background(colorScheme == .dark ? Color(Color.customDarkColor2) : Color.white)
                    .foregroundColor(.accentColor)
                    .clipShape(Circle())
                    .shadow(radius: 8)
                    .overlay(
                      Circle()
                        .stroke(Color.blue, lineWidth: 2)
                    )
                }

              }
            }
            .frame(width: geometry.size.width - 10, height: geometry.size.height * 2 - 120)
          }
        }
      )
      .onTapGesture {
        isFocused = false
      }
      .navigationBarItems(
        leading:
          HStack(alignment: .center) {
            Text("Groceries+")
              .font(.largeTitle)
              .fontWeight(.bold)
              .foregroundColor(.primary)
              .padding(.top, 15)
          },
        trailing: HStack(alignment: .center) {
          NavigationLink(destination: NewCategoryView()) {
            Text("New Category")
              .padding(.top, 15)
          }
        }
      )
      .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground))
    }
  }
}

extension Color {
  static let customLightColor = Color(UIColor(red: 250/255, green: 250/255, blue: 250/255, alpha: 1.0))
  static let customDarkColor = Color(UIColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1.0))
  static let customDarkColor2 = Color(UIColor(red: 28/255, green: 28/255, blue: 31/255, alpha: 1.0))
}

#Preview {
  ItemListView()
    .modelContainer(previewContainer)
}
