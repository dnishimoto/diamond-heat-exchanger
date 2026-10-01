//
//  Diamond_Heat_ExchangerApp.swift
//  Diamond Heat Exchanger
//
//  Created by David Nishimoto on 10/1/26.
//

import SwiftUI
import CoreData

@main
struct Diamond_Heat_ExchangerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
