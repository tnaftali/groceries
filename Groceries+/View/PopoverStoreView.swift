//
//  PopoverStoreView.swift
//  Groceries+
//
//  Created by Tobías Naftali on 2024-05-30.
//

import SwiftUI
import StoreKit

struct PopoverStoreView: View {
  @Binding var isPresented: Bool
  @Environment(\.presentationMode) var presentationMode
  @Environment(\.colorScheme) var colorScheme
  @State private var showAlert = false
  @State private var alertTitle = ""
  @State private var alertMessage = ""
  @StateObject private var store = Store()

  var body: some View {
    VStack {
      HStack() {
        Spacer()
        Button(action: {
          isPresented = false
        }) {
          Image(systemName: "xmark.circle.fill")
            .resizable()
            .frame(width: 24, height: 24)
            .foregroundColor(.gray)
            .padding()
        }
      }
      Spacer()
      ProductView(id: "com.groceries.lifetime") { _ in
        Image(uiImage: UIImage(named: "AppIcon") ?? UIImage())
          .resizable()
          .scaledToFit()
          .frame(width: 100, height: 100)
          .clipShape(RoundedRectangle(cornerRadius: 20))
      } placeholderIcon: {
        ProgressView()
      }
      .productViewStyle(.large)
      .padding(.bottom)
      .onInAppPurchaseStart { product in
        print("User has started buying \(product.id)")
      }
      .onInAppPurchaseCompletion { product, result in
        if case .success(.success(let transaction)) = result {
          print("Purchased successfully: \(transaction.signedDate)")
          
          alertTitle = "Purchase Successful"
          alertMessage = "Thank you for your purchase!"
          showAlert = true
          
          presentationMode.wrappedValue.dismiss()
        } else {
          alertTitle = "Purchase Failed"
          alertMessage = "The purchase could not be completed. Please try again."
          showAlert = true
        }
      }
      .alert(isPresented: $showAlert) {
        Alert(
            title: Text(alertTitle),
            message: Text(alertMessage),
            dismissButton: .default(Text("OK"))
        )
      }

      Button {
        Task {
          do {
            try await AppStore.sync()
            await store.updatePurchases()
          } catch {
            print(error)
          }
        }
      } label: {
        Text("Restore Purchases")
      }
      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

#Preview {
  PopoverStoreView(isPresented: .constant(true))
}
