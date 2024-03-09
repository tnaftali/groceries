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
  @Query private var items: [Item]
  @Environment(\.colorScheme) var colorScheme
  @State private var searchText = ""
  @FocusState private var isFocused: Bool
  
  var body: some View {
    var filteredAndSortedItems: [Item] {
      if searchText.isEmpty {
        return items.sorted { $0.name < $1.name }
      } else {
        return items.filter { $0.name.localizedCaseInsensitiveContains(searchText) }.sorted { $0.name < $1.name }
      }
    }
    
    ZStack(alignment: .bottomTrailing) {
      VStack {
        NavigationStack {
          TextField("Search", text: $searchText)
            .focused($isFocused)
            .padding(.horizontal, 35)
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding()
            .overlay(
              HStack {
                Image(systemName: "magnifyingglass")
                  .foregroundColor(Color(.systemGray2))
                  .opacity(0.7)
                  .padding(.leading, 8)
                Spacer()
                Button(action: {
                  searchText = ""
                }) {
                  if searchText != "" {
                    Image(systemName: "xmark.circle.fill")
                      .foregroundColor(Color(.systemGray2))
                      .opacity(0.4)
                      .padding(.trailing, 8)
                  }
                }
              }
              .padding(.horizontal, 16)
            )
            .autocorrectionDisabled()
          Divider()
          ScrollView {
            VStack {
              ForEach(0..<((filteredAndSortedItems.count / 2) + 1), id: \.self) { index in
                let item1Index = index == 0 ? index : index * 2
                let item1 = filteredAndSortedItems.count > item1Index ? filteredAndSortedItems[item1Index] : nil
                let item2Index = index == 0 ? index + 1 : index * 2 + 1
                let item2 = filteredAndSortedItems.count > item2Index ? filteredAndSortedItems[item2Index] : nil
                
                HStack {
                  if let item1 = item1 {
                    ItemView(item: item1)
                      .padding(.leading, 10)
                  } else {
                    GeometryReader { geometry in
                      Color.clear.frame(width: geometry.size.width * 0.5)
                    }
                  }
                  
                  if let item2 = item2 {
                    ItemView(item: item2)
                      .padding(.trailing, 10)
                  } else {
                    GeometryReader { geometry in
                      Color.clear.frame(width: geometry.size.width * 0.5)
                    }
                  }
                  Divider()
                }
              }
            }
          }
          .frame(width: .infinity)
          .onTapGesture {
            isFocused = false
          }
          .navigationTitle("Groceries+")
          HStack {
            Spacer()
            NavigationLink(destination: NewItemView()) {
              Image(systemName: "plus")
                .font(.system(size: 36))
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
}
