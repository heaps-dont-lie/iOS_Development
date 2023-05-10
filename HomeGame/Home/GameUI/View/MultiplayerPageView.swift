//
//  TestMPCView.swift
//  Home
//
//  Created by Aman Pandey on 4/2/23.
//

import SpriteKit
import SwiftUI

struct MultiplayerPageView: View {
    @EnvironmentObject var gameUImanager : GameUIManager
    @State var modeBSheet = false
    @State var modeCSheet = false
  
    var body: some View {
      TabView {
        MultiplayerModeTwoView()
          .ignoresSafeArea()
          .tabItem {
            Text("1-VS-1")
              .frame(width: 50, height: 50)
          }
        MultiplayerModeThreeView()
          .ignoresSafeArea()
          .tabItem {
            Text("Live")
              .frame(width: 50, height: 50)
          }
      }
    }
}

struct TestMPCView_Previews: PreviewProvider {
    static var previews: some View {
        MultiplayerPageView()
          .environmentObject(GameUIManager())
    }
}
