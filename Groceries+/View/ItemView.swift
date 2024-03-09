//
//  ToggleButton.swift
//  Groceries+
//
//  Created by Tobías Naftali on 2024-03-03.
//

import SwiftUI

struct ItemView: View {
  @Bindable var item: Item
  
  var body: some View {
    HStack {
      NavigationLink(destination: EditItemView(item: item)) {
        Text(item.name)
          .foregroundColor(.primary)
          .font(.system(size: 16))
          .opacity(item.checked ? 1.0 : 0.5)
        Spacer()
      }
      .frame(height: 40)
      Toggle(isOn: Binding(
        get: { item.checked },
        set: { newValue in
          withAnimation {
            item.checked = newValue
          }
        }
      )) {
        EmptyView()
      }
      .scaleEffect(0.8)
      .toggleStyle(SwitchToggleStyle(tint: .blue))
      .accentColor(.blue)
      .frame(width: 80)
    }
    .frame(height: 40)
  }
}

//#Preview {
//  print(previewContainer)
//  ItemView()
//    .modelContainer(previewContainer)
//  return Text("test")
  
  
//  return ItemView(item: previewContainer[0])
  
//  return ItemView(item: Item(id: UUID(), name: "test", checked: true))
//  ItemView()
//}
