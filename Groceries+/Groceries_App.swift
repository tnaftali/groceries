//
//  Groceries_App.swift
//  Groceries+
//
//  Created by Tobías Naftali on 2024-03-08.
//

import SwiftUI
import SwiftData

@main
struct TogglesApp: App {
  let modelContainer: ModelContainer
      
  init() {
    do {
      modelContainer = try ModelContainer(for: Item.self, Category.self, AppConfig.self)
    } catch {
      fatalError("Could not initialize ModelContainer")
    }
  }
  
  var body: some Scene {
    WindowGroup {
      ContentView()
        .modelContainer(modelContainer)
    }
  }
}
