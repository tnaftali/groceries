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
  @Query(sort: \Item.name) private var items: [Item]
  
  @Bindable var item: Item
  
  @Environment(\.colorScheme) var colorScheme
  @Environment(\.presentationMode) var presentationMode
  @Environment(\.modelContext) private var modelContext
  
  @FocusState private var isFocused: Bool
  
  @State private var editedName = ""
  @State private var selectedCategory: Category? = nil
  @State private var selectedQuantity: Int = 1
  @State private var oneTime: Bool = false
  @State private var important: Bool = false
  @State private var showEmptyError = false
  @State private var showDuplicatedError = false
  @State private var showNewCategoryView = false
  @State private var isChecked = false
  
  private let addCategoryFlag = Category(name: "ADD_CATEGORY_FLAG")

  var body: some View {
    VStack {
      Form {
        Section(header: Text("Name")) {
          TextField("Enter name here", text: $editedName)
            .focused($isFocused)
            .autocorrectionDisabled()
            .onAppear {
              editedName = item.name
              selectedCategory = item.category
              selectedQuantity = item.quantity
              oneTime = item.oneTime
              important = item.important
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
              Text("An item with this name already exists.")
                .foregroundColor(.red)
                .font(.caption)
            }
        }
        .listRowBackground(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
        
        Section(header: Text("Category")) {
          Picker("Select category", selection: $selectedCategory) {
            Text("None").tag(nil as Category?)
            ForEach(categories, id: \.id) { category in
              Text(category.name).tag(Optional(category))
            }
            HStack(alignment: .center) {
              Image(systemName: "plus.circle")
              Text("Add category")
            }.tag(Optional(addCategoryFlag))
          }
          .onChange(of: selectedCategory) {
            isFocused = false
            
            if selectedCategory == addCategoryFlag {
              showNewCategoryView = true
            }
          }
        }
        .listRowBackground(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
        
        Section(header: Text("Quantity")) {
          Stepper(value: $selectedQuantity, in: 1...20) {
            Text("\(selectedQuantity)")
          }
        }
        .listRowBackground(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))

        Section(header: Text("Options")) {
          Toggle(isOn: $oneTime) {
            Text("Delete after toggle?")
          }
          .onTapGesture {
            isFocused = false
          }
          .toggleStyle(SwitchToggleStyle(tint: .blue))
          
          Toggle(isOn: $important) {
            Text("Important")
          }
          .onTapGesture {
            isFocused = false
          }
          .toggleStyle(SwitchToggleStyle(tint: .blue))
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
            modelContext.delete(item)
            presentationMode.wrappedValue.dismiss()
          }
          .foregroundColor(.red)
        }
        .listRowBackground(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
      }
      .fullScreenCover(isPresented: $showNewCategoryView) {
        VStack {
          HStack {
            Spacer()
            Button(action: {
              showNewCategoryView = false
            }) {
              Image(systemName: "xmark.circle.fill")
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundColor(.gray)
                .padding()
            }
          }
          NewCategoryView(onCategoryCreated: { newCategory in
            self.selectedCategory = newCategory
            self.showNewCategoryView = false
          })
        }
        .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground))
      }
      .scrollContentBackground(.hidden)
      .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground))
      .navigationBarTitle("Edit Item")
    }
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
      if items.contains(where: { $0.id != item.id && $0.name == editedName }) {
        showEmptyError = false
        showDuplicatedError = true
        isFocused = true
      } else {
        showEmptyError = false
        showDuplicatedError = false
        item.name = editedName
        item.category = selectedCategory
        item.quantity = selectedQuantity
        item.oneTime = oneTime
        item.important = important
        presentationMode.wrappedValue.dismiss()
      }
    }
  }
}

#Preview {
  EditItemView(item: Item(name: "Test", checked: true))
}
