//
//  NewItemView.swift
//  Groceries+
//
//  Created by Tobías Naftali on 2024-03-07.
//

import SwiftUI
import SwiftData

struct NewItemView: View {
  @Query private var categories: [Category]
  @Environment(\.colorScheme) var colorScheme
  @Environment(\.presentationMode) var presentationMode
  @Environment(\.modelContext) private var modelContext
  @State private var editedName = ""
  @State private var selectedCategory: Category? = nil
  @FocusState private var isFocused: Bool
  
  var body: some View {
    VStack {
      Form {
        Section(header: Text("Name")) {
          TextField("Enter name here", text: $editedName)
            .focused($isFocused)
            .autocorrectionDisabled()
            .onAppear {
              isFocused = true
            }
            .onSubmit {
              let newItem = Item(name: editedName, checked: true)
              modelContext.insert(newItem)
              presentationMode.wrappedValue.dismiss()
            }
        }
        .listRowBackground(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
        Section(header: Text("Category")) {
          Picker("Select category", selection: $selectedCategory) {
            Text("None").tag(nil as Category?)
            ForEach(categories, id: \.id) { category in
              Text(category.name).tag(Optional(category))
            }
          }
          
        }
        .listRowBackground(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
        Section {
          Button("Save") {
            let newItem = Item(name: editedName, checked: true, category: selectedCategory)
            modelContext.insert(newItem)
            presentationMode.wrappedValue.dismiss()
          }
        }
        .listRowBackground(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
      }
      .scrollContentBackground(.hidden)
      .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground))
      .navigationBarTitle("New Item")
    }
  }
}

#Preview {
  NewItemView()
}
