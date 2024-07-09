//
//  EditCategoryView.swift
//  Groceries+
//
//  Created by Tobías Naftali on 2024-03-11.
//

import SwiftUI
import SwiftData
import Foundation

struct EditCategoryView: View {
  @Bindable var category: Category
  @Query(sort: \Item.name) private var items: [Item]
  @Query(sort: \Category.name) private var categories: [Category]
  @Environment(\.colorScheme) var colorScheme
  @Environment(\.presentationMode) var presentationMode
  @Environment(\.modelContext) private var modelContext
  @FocusState private var isFocused: Bool
  @State private var editedName = ""
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
              editedName = category.name
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
        Section {
          Button("Delete") {
            var categoryItems: [Item] {
              return items.filter { $0.category == category }
            }
            
            categoryItems.forEach { item in
              item.category = nil;
            }

            modelContext.delete(category)
            presentationMode.wrappedValue.dismiss()
          }
          .foregroundColor(.red)
        }
        .listRowBackground(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
      }
      .scrollContentBackground(.hidden)
      .frame(maxHeight: .infinity)
      .navigationBarTitle("Edit Category")
    }
    .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground))
  }
  
  func getFormattedDateString(date: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
    return dateFormatter.string(from: date)
  }
  
  private func handleFormSubmission() {
    if editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      showEmptyError = true
      showDuplicatedError = false
      isFocused = true
    } else {
      if categories.contains(where: { $0.id != category.id && $0.name == editedName }) {
        showEmptyError = false
        showDuplicatedError = true
        isFocused = true
      } else {
        showEmptyError = false
        showDuplicatedError = false
        category.name = editedName
        presentationMode.wrappedValue.dismiss()
      }
    }
  }
}

#Preview {
  EditCategoryView(category: Category(name: "Test"))
}
