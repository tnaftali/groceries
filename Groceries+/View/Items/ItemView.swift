//
//  ToggleButton.swift
//  Groceries+
//
//  Created by Tobías Naftali on 2024-03-03.
//

import SwiftUI

struct ItemView: View {
  @Bindable var item: Item
  
  @Environment(\.modelContext) private var modelContext

  var body: some View {
    HStack(spacing: 10) {
      Toggle(isOn: Binding(
        get: { item.checked },
        set: { newValue in
          withAnimation {
            item.checked = newValue
            
            if !newValue && !item.recurring {
              modelContext.delete(item)
            }
          }
        }
      )) {
        EmptyView()
      }
      .scaleEffect(0.8)
      .toggleStyle(SwitchToggleStyle(tint: .blue))
      .accentColor(.blue)
      .frame(width: 50)
      
      NavigationLink(destination: EditItemView(item: item)) {
        Text(item.name)
          .foregroundColor(.primary)
          .font(.system(size: 16))
          .multilineTextAlignment(.leading)
          .opacity(item.checked ? 1.0 : 0.5)
        Spacer()
      }
      .frame(height: 40)
      
    }
    .frame(height: 40)
  }
}

#Preview {
  ItemView(item: Item(name: "Test", checked: true))
}
