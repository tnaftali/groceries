//
//  ContentView.swift
//  Groceries+
//
//  Created by Tobías Naftali on 2024-03-08.
//

import SwiftUI
import SwiftData

struct ContentView: View {
  @Query private var appConfigs: [AppConfig]
  @Environment(\.modelContext) private var modelContext
  
  var body: some View {
    var appConfig: AppConfig {
      return getAppConfig(appConfigs: appConfigs)
    }

    ItemListView(appConfig: appConfig)
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
}

#Preview {
  ContentView()
    .modelContainer(previewContainer)
}
