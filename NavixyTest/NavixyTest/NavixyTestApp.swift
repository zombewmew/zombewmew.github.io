//
//  NavixyTestApp.swift
//  NavixyTest
//
//  Created by christina on 03.05.2026.
//

import SwiftUI
import CoreData

@main
struct NavixyTestApp: App {
    private let appEnvironment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            RootMapView(appEnvironment: appEnvironment)
                .environment(\.managedObjectContext, appEnvironment.persistenceController.container.viewContext)
                .environmentObject(appEnvironment.networkMonitor)
        }
    }
}
