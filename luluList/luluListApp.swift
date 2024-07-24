//
//  luluListApp.swift
//  luluList
//
//  Created by Jules Burt on 2024-07-23.
//

import SwiftUI

@main
struct luluListApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
