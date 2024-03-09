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
  @Bindable var item: Item
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
              editedName = item.name
            }
            .onSubmit {
              item.name = editedName
              presentationMode.wrappedValue.dismiss()
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

//#Preview {
//  let modelData = ModelData()
//  return ItemDetail(itemName: .constant("test"), item: modelData.items[0]).environment(modelData)
  
//  return ItemDetail(itemName: .constant("test"), item: nil)
//}

//#Preview {
//  EditItemView(item: Item(id: UUID(), name: "Test", checked: true))
//}
