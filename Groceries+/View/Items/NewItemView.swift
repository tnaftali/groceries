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
  @State var showingPopover = false
  @StateObject private var store = Store()
  @FocusState private var isFocused: Bool

  var body: some View {
    var showPopover: Bool {
      return items.count > 2
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
    .onAppear {
      Task {
        await store.updatePurchases()

        if !store.purchasedLifetime {
          isFocused = false
          
          showingPopover = showPopover
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
}

#Preview {
  NewItemView()
}
