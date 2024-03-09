//
//  ContentView.swift
//  Groceries+
//
//  Created by Tobías Naftali on 2024-03-08.
//

import SwiftUI
import SwiftData

struct ContentView: View {
  @Query private var items:[Item]
//  @State private var selection: Tab = .featured
  
//  enum Tab {
//    case categories
//    case items
//  }
  
  var body: some View {
    ItemList()
  }
}

#Preview {
  ContentView()
    .modelContainer(previewContainer)
}
