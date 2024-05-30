//
//  Store.swift
//  Groceries+
//
//  Created by Tobías Naftali on 2024-05-30.
//

import Foundation
import StoreKit

class Store: ObservableObject {
    private var productIDs = ["com.groceries.lifetime"]
    
    @Published var purchasedLifetime = false

    init() {
      Task {
        await updatePurchases()
      }
    }
    
  @MainActor
  func updatePurchases() async {
    do {
      for try await result in Transaction.currentEntitlements {
        guard case .verified(let transaction) = result else { continue }
        
        if productIDs.contains(transaction.productID) {
          purchasedLifetime = transaction.revocationDate == nil
        }
      }
    } catch {
      print("Failed to fetch entitlements: \(error)")
    }
  }
}

