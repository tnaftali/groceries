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
          Task {
            await updateItemChecked(newValue)
          }
        }
      )) {
        EmptyView()
      }
      .scaleEffect(0.8)
      .toggleStyle(SwitchToggleStyle(tint: .blue))
      .frame(width: 50)
      
      NavigationLink(destination: EditItemView(item: item)) {
        Text(item.name)
          .foregroundColor(.primary)
          .font(.system(size: 16))
          .multilineTextAlignment(.leading)
          .opacity(item.checked ? 1.0 : 0.5)
          .overlay(
            Group {
              if item.important && item.checked {
                Circle()
                  .fill(Color.red)
                  .frame(width: 5, height: 5)
                  .offset(x: 10, y: 0)
              } else if item.oneTime && item.checked {
                Image(systemName: "sparkles")
                  .font(.system(size: 10))
                  .frame(width: 5, height: 5)
                  .foregroundColor(.gray)
                  .offset(x: 10, y: 0)
              }
            },
            alignment: .topTrailing
          )
        Spacer()
      }
      .frame(height: 40)
      
    }
    .frame(height: 40)
  }
  
  func updateItemChecked(_ newValue: Bool) async {
    item.checked = newValue
    
    if !newValue && item.oneTime {
      modelContext.delete(item)
    }
  }
}

#Preview {
  ItemView(item: Item(name: "Test", checked: true))
}
