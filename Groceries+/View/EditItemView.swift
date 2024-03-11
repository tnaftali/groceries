//
//  ItemDetail.swift
//  Groceries+
//
//  Created by Tobías Naftali on 2024-03-03.
//

import SwiftUI
import SwiftData
import Foundation

struct EditItemView: View {
  @Query private var categories: [Category]
  @Bindable var item: Item
  @Environment(\.presentationMode) var presentationMode
  @Environment(\.modelContext) private var modelContext
  @State private var editedName = ""
  @State private var selectedCategory: Category? = nil
  
  var body: some View {
    VStack {
      Form {
        Section(header: Text("Name")) {
          TextField("Enter name here", text: $editedName)
            .autocorrectionDisabled()
            .onAppear {
              editedName = item.name
              selectedCategory = item.category
            }
            .onSubmit {
              item.name = editedName
              presentationMode.wrappedValue.dismiss()
            }
        }
        Section(header: Text("Category")) {
          Picker("Select category", selection: $selectedCategory) {
            Text("None").tag(nil as Category?)
            ForEach(categories, id: \.id) { category in
              Text(category.name).tag(Optional(category))
            }
          }
          .onChange(of: selectedCategory) {
            item.category = selectedCategory
          }
        }
        Section(header: Text("Creation Date")) {
          Text(getFormattedDateString(date: item.creationDate))
            .foregroundColor(Color.gray)
        }
        Section {
          Button("Save") {
            item.name = editedName
            presentationMode.wrappedValue.dismiss()
          }
        }
        Section {
          Button("Delete") {
            modelContext.delete(item)
            presentationMode.wrappedValue.dismiss()
          }
          .foregroundColor(.red)
        }
      }
      .frame(maxHeight: .infinity)
      .navigationBarTitle("Edit Item")
    }
  }
  
  func getFormattedDateString(date: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
    return dateFormatter.string(from: date)
  }
}

#Preview {
  EditItemView(item: Item(name: "Test", checked: true))
}
