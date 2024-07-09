//
//  NewCategoryView.swift
//  Groceries+
//
//  Created by Tobías Naftali on 2024-03-09.
//

import SwiftUI
import SwiftData

struct NewCategoryView: View {
  var onCategoryCreated: (Category) -> Void
  
  @State private var editedName = ""
  @Query(sort: \Category.name) private var categories: [Category]
  @Environment(\.colorScheme) var colorScheme
  @Environment(\.presentationMode) var presentationMode
  @Environment(\.modelContext) private var modelContext
  @FocusState private var isFocused: Bool
  @State private var showEmptyError = false
  @State private var showDuplicatedError = false

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
              handleFormSubmission()
            }
          
          if showEmptyError {
            Text("Name cannot be empty.")
              .foregroundColor(.red)
              .font(.caption)
          }
          
          if showDuplicatedError {
            Text("A category with this name already exists.")
              .foregroundColor(.red)
              .font(.caption)
          }
        }
        .listRowBackground(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
        Section {
          Button("Save") {
            handleFormSubmission()
          }
        }
        .listRowBackground(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
      }
      .scrollContentBackground(.hidden)
      .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground))
      .navigationBarTitle("Add Category")
    }
  }
  
  private func handleFormSubmission() {
    if editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      showEmptyError = true
      showDuplicatedError = false
      isFocused = true
    } else {
      if categories.contains(where: { $0.name == editedName }) {
        showEmptyError = false
        showDuplicatedError = true
        isFocused = true
      } else {
        showEmptyError = false
        showDuplicatedError = false
        let newCategory = Category(name: editedName)
        modelContext.insert(newCategory)
        onCategoryCreated(newCategory) // Call the callback with the new Category
        presentationMode.wrappedValue.dismiss()
      }
    }
  }
}

#Preview {
  NewCategoryView(onCategoryCreated: { _ in })
}
