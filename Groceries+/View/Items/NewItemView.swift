//
//  NewItemView.swift
//  Groceries+
//
//  Created by Tobías Naftali on 2024-03-07.
//

import SwiftUI
import SwiftData
import StoreKit

struct NewItemView: View {
  @Query private var categories: [Category]
  @Query(sort: \Item.name) private var items: [Item]
  
  @Environment(\.colorScheme) var colorScheme
  @Environment(\.presentationMode) var presentationMode
  @Environment(\.modelContext) private var modelContext
  
  @State private var editedName = ""
  @State private var selectedCategory: Category? = nil
  @State private var selectedQuantity: Int = 1
  @State private var oneTime: Bool = false
  @State private var important: Bool = false
  @State private var showEmptyError = false
  @State private var showDuplicatedError = false
  @State private var showNewCategoryView = false
  @State var showingPopover = false
  
  @Binding var returnToggle: Bool

  @StateObject private var store = Store()
  
  @FocusState private var isFocused: Bool
  
  let name : String?

  private let addCategoryFlag = Category(name: "ADD_CATEGORY_FLAG")
  
  var body: some View {
    var showPopover: Bool {
      return items.count > 20
    }

    ZStack {
      VStack {
        Form {
          Section(header: Text("Name")) {
            TextField("Enter name here", text: $editedName)
              .focused($isFocused)
              .autocorrectionDisabled()
              .onAppear {
                isFocused = true
                editedName = name ?? ""
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
            .onSubmit {
              handleFormSubmission()
            }
          }
          .listRowBackground(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))

          Section(header: Text("Options")) {
            Toggle(isOn: $oneTime) {
              Text("Delete after toggle?")
            }
            .toggleStyle(SwitchToggleStyle(tint: .blue))
            
            Toggle(isOn: $important) {
              Text("Important")
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
        .navigationBarTitle("Add Item")
      }
    }
    .onAppear {
      Task {
        await store.updatePurchases()

        if !store.purchasedLifetime {
          isFocused = false
          
          showingPopover = showPopover
        }
      }
    }
    .onDisappear {
      if presentationMode.wrappedValue.isPresented == false {
        if returnToggle {
          returnToggle = false
        } else {
          returnToggle = true
        }
      }
    }
    .popover(isPresented: $showingPopover) {
      PopoverStoreView(isPresented: $showingPopover)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground))
        .onDisappear {
          Task {
            await store.updatePurchases()
            print("Purchased lifetime?: \(store.purchasedLifetime)")
            
            if !store.purchasedLifetime {
              presentationMode.wrappedValue.dismiss()
            }
          }
        }
    }
  }
  
  private func handleFormSubmission() {
    if editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      showEmptyError = true
      showDuplicatedError = false
      isFocused = true
    } else {
      if items.contains(where: { $0.name == editedName }) {
        showEmptyError = false
        showDuplicatedError = true
        isFocused = true
      } else {
        showEmptyError = false
        showDuplicatedError = false
        let newItem = Item(name: editedName, checked: true, category: selectedCategory, oneTime: oneTime, important: important, quantity: selectedQuantity)
        modelContext.insert(newItem)
        presentationMode.wrappedValue.dismiss()
      }
    }
  }
}

#Preview {
  NewItemView(returnToggle: .constant(true), name: "")
}
