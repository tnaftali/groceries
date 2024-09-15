//
//  ItemListView.swift
//  Groceries+
//
//  Created by Tobías Naftali on 2024-03-03.
//

import SwiftUI
import SwiftData
import Foundation

struct ItemListView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.colorScheme) var colorScheme
  
  @Query(sort: \Item.name) private var items: [Item]
  @Query(sort: \Category.name) private var categories: [Category]
  @Query private var appConfigs: [AppConfig]
  
  @State private var searchText = ""
  @State private var showLifetimeAlert = false
  @State private var showingLifetimeIcon = false
  @State private var returnToggle = true

  @FocusState private var isFocused: Bool
  
  @StateObject private var store = Store()
  
  var body: some View {
    var filteredItems: [Item] {
      
      if searchText.isEmpty {
        return appConfig.checkedFilter ? items.filter { $0.checked } : items
      } else {
        return items.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
      }
    }
    
    var appConfig: AppConfig {
      return getAppConfig(appConfigs: appConfigs)
    }

    NavigationStack {
      VStack {
        TextField("Search", text: $searchText)
          .focused($isFocused)
          .padding(.horizontal, 35)
          .padding(.vertical, 10)
          .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
          .cornerRadius(10)
          .padding(.leading)
          .padding(.trailing)
          .padding(.top, 20)
          .padding(.bottom, 5)
          .overlay(
            HStack {
              Image(systemName: "magnifyingglass")
                .foregroundColor(Color(.systemGray2))
                .opacity(0.7)
                .padding(.leading, 8)
                .padding(.top, 15)
              Spacer()
              Button(action: {
                searchText = ""
              }) {
                if searchText != "" {
                  Image(systemName: "xmark.circle.fill")
                    .foregroundColor(Color(.systemGray2))
                    .opacity(0.4)
                    .padding(.trailing, 8)
                    .padding(.top, 15)
                }
              }
            }
            .padding(.horizontal, 16)
          )
          .autocorrectionDisabled()
        
        let noCategoryItemsCount = filteredItems.filter { $0.category == nil }.count
        if noCategoryItemsCount > 0 {
          Divider()
        }
        
        if filteredItems.count == 0 {
          Divider()
          if searchText == "" {
            Text("🛒 No pending groceries")
              .font(.system(size: 18))
              .foregroundColor(.primary)
              .padding(.top, 20)
              .padding(.bottom, 20)
          } else {
            Text("🔎 No results found")
              .font(.system(size: 18))
              .foregroundColor(.primary)
              .padding(.top, 20)
              .padding(.bottom, 20)
          }
          Divider()
        }
        
        ScrollView {
          VStack(spacing: 5) {
            Group {
              GeometryReader { geometry in
                ZStack(alignment: .leading) {
                  Rectangle()
                    .foregroundColor(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                    .frame(width: geometry.size.width)
                  HStack(alignment: .center) {
                    Text("Uncategorized")
                      .font(.system(size: 16))
                      .opacity(0.9)
                      .fontWeight(.semibold)
                      .foregroundColor(.primary)
                      .padding(.leading, 10)
                    Button(action: {
                      Task {
                        await toggleCategory(nil, appConfig)
                      }
                    }) {
                      Spacer()
                      Image(systemName: appConfig.uncategorizedItemsExpanded ? "chevron.down" : "chevron.up")
                        .foregroundColor(.primary)
                        .font(.system(size: 16, weight: .semibold))
                        .padding(.trailing, 10)
                    }
                  }
                }
              }
              .frame(height: 30)
              if appConfig.uncategorizedItemsExpanded {
                ItemsGroupView(category: nil, searchText: $searchText, toggleChecked: .constant(appConfig.checkedFilter))
              }
            }

            ForEach(categories, id: \.self) { category in
              if filteredItems.contains(where: { $0.category == category }) {
                Group {
                  GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                      Rectangle()
                        .foregroundColor(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                        .frame(width: geometry.size.width)
                      HStack(alignment: .center) {
                        NavigationLink(destination: EditCategoryView(category: category)) {
                          Text(category.name)
                            .font(.system(size: 16))
                            .opacity(0.9)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .padding(.leading, 10)
                          Image(systemName: "square.and.pencil")
                            .foregroundColor(.secondary)
                            .font(.system(size: 16, weight: .semibold))
                        }
                        Button(action: {
                          Task {
                            await toggleCategory(category, appConfig)
                          }
                        }) {
                          Spacer()
                          Image(systemName: category.expanded ? "chevron.down" : "chevron.up")
                            .foregroundColor(.primary)
                            .font(.system(size: 16, weight: .semibold))
                            .padding(.trailing, 10)
                        }
                      }
                    }
                  }
                  .frame(height: 30)
                  if category.expanded {
                    ItemsGroupView(category: category, searchText: $searchText, toggleChecked: .constant(appConfig.checkedFilter))
                  }
                }
              }
            }
          }
          .padding(.bottom, 80)
        }
      }
      .overlay(
        ZStack {
          GeometryReader { geometry in
            VStack(alignment: .center) {
              if filteredItems.filter({ $0.checked }).count > 0 {
                Button(action: {
                  shareCheckedItems(items: filteredItems)
                }) {
                  Image(systemName: "square.and.arrow.up.circle.fill")
                    .resizable()
                    .background(Color.white)
                    .foregroundColor(.gray)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .shadow(radius: 6)
                }
              } else {
                GeometryReader { geometry2 in }.frame(height: 40)
              }
              Button(action: {
                Task {
                  await toggleCheckedFilter(appConfig)
                }
              }) {
                Image(systemName: appConfig.checkedFilter ? "checklist.unchecked" : "checklist.checked")
                  .font(.system(size: 36))
                  .padding(12)
                  .background(Color.blue)
                  .foregroundColor(.white)
                  .clipShape(Circle())
                  .shadow(radius: 8)
              }
              .padding(.top, 12)
            }
            .frame(width: geometry.size.width * 2 - 120, height: geometry.size.height * 2 - 140)
          }
        }
      )
      .onTapGesture {
        isFocused = false
      }
      .navigationBarItems(
        leading:
          HStack(alignment: .center) {
            Text("Groceries+")
              .font(.largeTitle)
              .fontWeight(.bold)
              .foregroundColor(.primary)
              .padding(.top, 15)
            
            if showingLifetimeIcon {
              Image(systemName: "crown.fill")
                .padding(.top, 15)
                .font(.system(size: 18))
                .padding(.horizontal, 0)
                .foregroundColor(.yellow)
                .onTapGesture {
                  showLifetimeAlert = true
                }
            }
          },
        trailing: HStack(alignment: .center) {
          NavigationLink(destination: NewItemView(returnToggle: $returnToggle)) {
            Text("Add item")
              .padding(.top, 15)
          }
        }
      )
      .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground))
    }
    .onAppear {
      Task {
        await store.updatePurchases()

        if store.purchasedLifetime {
          showingLifetimeIcon = true
        }
      }
    }
    .onChange(of: returnToggle) {
      // Returned from NewItemView
      Task {
        await store.updatePurchases()

        if store.purchasedLifetime {
          showingLifetimeIcon = true
        }
      }
    }
    .alert(isPresented: $showLifetimeAlert) {
      Alert(
        title: Text("Thank You"),
        message: Text("Thank you for purchasing Groceries+ Lifetime, enjoy unlimited items and all the upcoming features."),
        dismissButton: .default(Text("OK"))
      )
    }
  }
  
  private func shareCheckedItems(items: [Item]) {
    let itemsGroupedByCategory = Dictionary(grouping: items.filter { $0.checked }, by: { $0.category })
            
    var pendingItemsText = ""
    for (category, items) in itemsGroupedByCategory.sorted(by: { $0.key?.name ?? "" < $1.key?.name ?? "" }) {
      pendingItemsText += category != nil ? "*\(category?.name ?? "")*\n" : ""
      for item in items {
        pendingItemsText += "- \(item.name)\n"
      }
      pendingItemsText += "\n"
    }

    let activityVC = UIActivityViewController(activityItems: [pendingItemsText], applicationActivities: nil)
    
    // Find the top-most window's root view controller
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
     let rootViewController = windowScene.windows.first?.rootViewController {
       rootViewController.present(activityVC, animated: true, completion: nil)
    }
  }
  
  private func getAppConfig(appConfigs : [AppConfig]) -> AppConfig {
    if appConfigs == [] {
      // Initialize AppConfig if it doesn't exist.
      let appConfig = AppConfig(checkedFilter: false)
      modelContext.insert(appConfig)
      return appConfig
    } else {
      return appConfigs.first!
    }
  }
  
  private func toggleCategory(_ category : Category?, _ appConfig: AppConfig) async {
    if (category != nil) {
      category!.expanded = !category!.expanded
    } else {
      appConfig.uncategorizedItemsExpanded = !appConfig.uncategorizedItemsExpanded
    }
  }
  
  private func toggleCheckedFilter(_ appConfig: AppConfig) async {
    appConfig.checkedFilter.toggle()
  }
}

extension Color {
  static let darkRed = Color(UIColor(red: 210/255, green: 18/255, blue: 31/255, alpha: 1.0))
}

#Preview {
  ItemListView()
    .modelContainer(previewContainer)
}
