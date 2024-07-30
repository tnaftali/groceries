//
//  PreviewSampleData.swift
//  Groceries+
//
//  Created by Tobías Naftali on 2024-03-07.

import SwiftData

@MainActor
let previewContainer: ModelContainer = {
  do {
    let container = try ModelContainer(
      for: Item.self, AppConfig.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let modelContext = container.mainContext
    if try modelContext.fetch(FetchDescriptor<Item>()).isEmpty {
      SampleItemsWithCategories.items.forEach { container.mainContext.insert($0) }
    }
    if try modelContext.fetch(FetchDescriptor<Category>()).isEmpty {
      SampleItemsWithCategories.categories.forEach { container.mainContext.insert($0) }
    }
    return container
  } catch {
    fatalError("Failed to create container")
  }
}()
