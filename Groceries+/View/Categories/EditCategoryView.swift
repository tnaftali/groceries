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
  @Environment(\.colorScheme) var colorScheme
  @Environment(\.presentationMode) var presentationMode
  @Environment(\.modelContext) private var modelContext
  @State private var editedName = ""
  
  var body: some View {
    VStack {
      Form {
        Section(header: Text("Name")) {
          TextField("Enter name here", text: $editedName)
            .autocorrectionDisabled()
            .onAppear {
              editedName = category.name
            }
            .onSubmit {
              category.name = editedName
              presentationMode.wrappedValue.dismiss()
            }
        }
        .listRowBackground(Color(.systemGray5))
        Section(header: Text("Created On")) {
          Text(getFormattedDateString(date: category.creationDate))
            .foregroundColor(Color.gray)
        }
        .listRowBackground(Color(.systemGray5))
        Section {
          Button("Save") {
            category.name = editedName
            presentationMode.wrappedValue.dismiss()
          }
        }
        .listRowBackground(Color(.systemGray5))
        Section {
          Button("Delete") {
            modelContext.delete(category)
            presentationMode.wrappedValue.dismiss()
          }
          .foregroundColor(.red)
        }
        .listRowBackground(Color(.systemGray5))
      }
      .scrollContentBackground(.hidden)
      .background(colorScheme == .dark ? Color.customDarkColor : Color.customLightColor)
      .frame(maxHeight: .infinity)
      .navigationBarTitle("Edit Category")
    }
    .background(colorScheme == .dark ? Color.customDarkColor : Color.customLightColor)
  }
  
  func getFormattedDateString(date: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
    return dateFormatter.string(from: date)
  }
}

#Preview {
  EditCategoryView(category: Category(name: "Test"))
}
