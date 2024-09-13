//
//  ContentView.swift
//  Groceries+
//
//  Created by Tobías Naftali on 2024-03-08.
//

import SwiftUI
import SwiftData

struct ContentView: View {
  var body: some View {
    ItemListView()
  }
}

#Preview {
  ContentView()
    .modelContainer(previewContainer)
}
