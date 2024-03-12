//
//  NewCategoryView.swift
//  Groceries+
//
//  Created by Tobías Naftali on 2024-03-09.
//

import SwiftUI

struct NewCategoryView: View {
  @State private var editedName = ""
  @Environment(\.colorScheme) var colorScheme
  @Environment(\.presentationMode) var presentationMode
  @Environment(\.modelContext) private var modelContext
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
              let newCategory = Category(name: editedName)
              modelContext.insert(newCategory)
              presentationMode.wrappedValue.dismiss()
            }
        }
        .listRowBackground(Color(.systemGray5))
        Section {
          Button("Save") {
            let newCategory = Category(name: editedName)
            modelContext.insert(newCategory)
            presentationMode.wrappedValue.dismiss()
          }
        }
        .listRowBackground(Color(.systemGray5))
      }
      .scrollContentBackground(.hidden)
      .background(colorScheme == .dark ? Color.customDarkColor : Color.customLightColor)
      .navigationBarTitle("New Category")
    }
  }
}

#Preview {
  NewCategoryView()
}
