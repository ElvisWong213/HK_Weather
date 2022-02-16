//
//  weatherApp.swift
//  WeatherWatch WatchKit Extension
//
//  Created by Steve on 10/2/2022.
//

import SwiftUI

@main
struct weatherApp: App {
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}
