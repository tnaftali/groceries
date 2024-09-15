//
//  ModelData.swift
//  Groceries+
//
//  Created by Tobías Naftali on 2024-03-03.
//

import Foundation

struct SampleItems {
  static var categories: [Category] = []
  
  static var items: [Item] = [
    Item(name: "Apples", checked: true),
    Item(name: "Bananas", checked: true),
    Item(name: "Cheese", checked: true),
    Item(name: "Chicken", checked: true),
    Item(name: "Eggs", checked: true),
    Item(name: "Ground beef"),
    Item(name: "Milk"),
    Item(name: "Olive oil", checked: true),
    Item(name: "Pasta"),
    Item(name: "Peanut butter"),
    Item(name: "Potatoes", checked: true),
    Item(name: "Rice", checked: true),
    Item(name: "Salmon"),
    Item(name: "Steaks"),
    Item(name: "Tomatoes")
  ]
}

struct SampleItemsWithCategories {
  static var categories: [Category] = []
  
  static var dairy = Category(name: "🥛 Dairy")
  static var meats = Category(name: "🥩 Meats")
  static var pantry = Category(name: "🥫 Pantry")
  static var produce = Category(name: "🥬 Produce")
  
  static var items: [Item] = [
    Item(name: "Apples", checked: true, category: produce),
    Item(name: "Bananas", checked: true, category: produce),
    Item(name: "Cheese", checked: true, category: dairy),
    Item(name: "Chicken", checked: true, category: meats, important: true, quantity: 2),
    Item(name: "Eggs", checked: true, important: true, quantity: 12),
    Item(name: "Ground beef", checked: true, category: meats, important: true),
    Item(name: "Milk", category: dairy),
    Item(name: "Olive oil", checked: true),
    Item(name: "Pasta", category: pantry),
    Item(name: "Peanut butter"),
    Item(name: "Potatoes", checked: true, category: produce),
    Item(name: "Rice", checked: true, category: pantry),
    Item(name: "Salmon", category: meats),
    Item(name: "Steaks", category: meats),
    Item(name: "Tomatoes", category: produce),
  ]
}

struct SampleItemsWithStoreCategories {
  static var categories: [Category] = []
  
  static var wholeFoods = Category(name: "🌱 Whole Foods Market")
  static var carrefour = Category(name: "🛒 Carrefour")
  static var costco = Category(name: "🛒 Costco")
  
  static var items: [Item] = [
    Item(name: "Apples", checked: true, category: wholeFoods),
    Item(name: "Bananas", checked: true, category: wholeFoods),
    Item(name: "Cheese", checked: true, category: costco),
    Item(name: "Chicken", checked: true, category: wholeFoods, quantity: 2),
    Item(name: "Eggs", category: wholeFoods, important: true, quantity: 12),
    Item(name: "Ground beef", important: true),
    Item(name: "Milk", category: costco),
    Item(name: "Olive oil", checked: true, category: carrefour),
    Item(name: "Pasta"),
    Item(name: "Peanut butter", category: costco),
    Item(name: "Potatoes", checked: true, category: wholeFoods),
    Item(name: "Rice", checked: true),
    Item(name: "Salmon"),
    Item(name: "Steaks"),
    Item(name: "Tomatoes", category: wholeFoods)
  ]
}

struct SampleItemsWithImportantAndOneTime {
  static var categories: [Category] = []
  
  static var items: [Item] = [
    Item(name: "Apples"),
    Item(name: "Fresh basil", checked: true, oneTime: true),
    Item(name: "Brie cheese", checked: true, oneTime: true),
    Item(name: "Bananas", checked: true, important: true),
    Item(name: "Cheese", checked: true),
    Item(name: "Chicken", checked: true, important: true),
    Item(name: "Eggs", checked: true, important: true),
    Item(name: "Ground beef"),
    Item(name: "Milk"),
    Item(name: "Olive oil"),
    Item(name: "Pasta"),
    Item(name: "Peanut butter"),
    Item(name: "Potatoes"),
    Item(name: "Rice", checked: true, important: true),
    Item(name: "Salmon"),
    Item(name: "Steaks"),
    Item(name: "Tomatoes")
  ]
}
