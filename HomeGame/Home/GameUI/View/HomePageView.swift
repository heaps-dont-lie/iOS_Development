//
//  HomePageView.swift
//  Home
//
//  Created by Aman Pandey on 4/2/23.
//

import SwiftUI
import SpriteKit

struct HomePageView: View {
    @EnvironmentObject var gameUImanager : GameUIManager
  
    var body: some View {

      ZStack {
          
          Image("space")
            .resizable()
            .ignoresSafeArea()
          
          
          VStack{
            HStack {
              Text("Highest Score: \(gameUImanager.maxScore)")
                .foregroundColor(.cyan)
                .onChange(of: gameUImanager.maxScore) { newValue in
                  UserDefaults.standard.set(gameUImanager.maxScore, forKey: "maxScore")
                }
                .onAppear {
                  gameUImanager.maxScore = UserDefaults.standard.integer(forKey: "maxScore")
                }
              
              Button {
                gameUImanager.maxScore = 0
              } label: {
                Image(systemName: "arrow.clockwise.circle.fill")
                  .foregroundColor(.cyan)
              }

            }
            
            Button {
              gameUImanager.gameModeOne = true
            }label: {
              Text("New Game")
                .font(.largeTitle)
                .foregroundColor(.black)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.yellow).frame(minWidth: 200, minHeight: 70))
            }.padding(50).fullScreenCover(isPresented: $gameUImanager.gameModeOne) {
              SpriteView(scene: gameUImanager.getGameScene(mode: .gameModeOne))
                .ignoresSafeArea()
            }
            
            NavigationLink {
              MultiplayerPageView()
                .ignoresSafeArea()
            }label: {
              Text("Multiplayer")
                .font(.largeTitle)
                .foregroundColor(.black)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.yellow).frame(minWidth: 200, minHeight: 70))
            }.padding(50)
          }

          
          /* For testing MPC  */
          //TestMPCView()
        }
      
    }
}

struct HomePageView_Previews: PreviewProvider {
    static var previews: some View {
        HomePageView()
          .environmentObject(GameUIManager())
    }
}
