//
//  NewItemView.swift
//  Groceries+
//
//  Created by Tobías Naftali on 2024-03-07.
//

import SwiftUI

struct NewItemView: View {
  @State private var editedName = ""
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
              let newItem = Item(name: editedName, checked: false)
              modelContext.insert(newItem)
              presentationMode.wrappedValue.dismiss()
            }
        }
        Section {
          Button("Save") {
            let newItem = Item(name: editedName, checked: false)
            modelContext.insert(newItem)
            presentationMode.wrappedValue.dismiss()
          }
        }
      }
      .navigationBarTitle("New Item")
    }
  }
}

#Preview {
  NewItemView()
}
