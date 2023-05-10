//
//  HomeApp.swift
//  Home
//
//  Created by Aman Pandey on 4/1/23.
//

import SwiftUI

@main
struct HomeApp: App {
  @StateObject var gameUImanager = GameUIManager()
    var body: some Scene {
        WindowGroup {
            ContentView()
              .environmentObject(GameUIManager())
        }
    }
}
