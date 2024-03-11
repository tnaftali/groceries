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
      for: Item.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let modelContext = container.mainContext
    if try modelContext.fetch(FetchDescriptor<Item>()).isEmpty {
      SampleItems.items.forEach { container.mainContext.insert($0) }
    }
    if try modelContext.fetch(FetchDescriptor<Category>()).isEmpty {
      SampleItems.categories.forEach { container.mainContext.insert($0) }
    }
    return container
  } catch {
    fatalError("Failed to create container")
  }
}()
