//
//  MultiplayerModeOneView.swift
//  Home
//
//  Created by Aman Pandey on 4/22/23.
//

import SpriteKit
import SwiftUI

struct MultiplayerModeTwoView: View {
    @EnvironmentObject var gameUImanager : GameUIManager
    @State var messageSheet = false
    @State var messageUnreadIcon = false
  
    var body: some View {
      NavigationView {
        VStack {
            Text(gameUImanager.isConnectedToPeer.rawValue)
              .font(.largeTitle)
              .foregroundColor(gameUImanager.isConnectedToPeer == .connected ? .green : .red)
            
            if gameUImanager.isConnectedToPeer == .connected {
              Text("Connected with: " + gameUImanager.mpcManager.mcSession.connectedPeers[0].displayName)
                .font(.title2)
                .foregroundColor(.green)
            }
            
            if gameUImanager.myTurn {
              if let score = gameUImanager.peerScore {
                Text("You have to achive \(score+1) points in order to win!")
              } else {
                Text("You are playing first!")
              }
            }
            
            if let value = gameUImanager.matchResult {
              Text(value)
            }
            
            Button {
              gameUImanager.advertise()
            } label: {
              Text("Match Up")
                .font(.largeTitle)
                .foregroundColor(.black)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.yellow).frame(minWidth: 200, minHeight: 70))
            }.padding(50)
            
            Button {
              gameUImanager.invite()
            } label: {
              Text("Host")
                .font(.largeTitle)
                .foregroundColor(.black)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.yellow).frame(minWidth: 200, minHeight: 70))
            }.padding(50)
            
            // I can gray out the button instead of not showing the button at all.
            if gameUImanager.myTurn {
              Button {
                gameUImanager.gameModeTwo = true
              }label: {
                Text("Play Game")
                  .font(.largeTitle)
                  .foregroundColor(.black)
                  .background(RoundedRectangle(cornerRadius: 20).fill(Color.yellow).frame(minWidth: 200, minHeight: 70))
              }.padding(50).fullScreenCover(isPresented: $gameUImanager.gameModeTwo) {
                SpriteView(scene: gameUImanager.getGameScene(mode: .gameModeTwo))
                  .ignoresSafeArea()
              }
            }
            
            if gameUImanager.tossFlag {
              Button {
                gameUImanager.doToss()
              } label: {
                Text("Toss")
                  .font(.largeTitle)
                  .foregroundColor(.black)
                  .background(RoundedRectangle(cornerRadius: 20).fill(Color.yellow).frame(minWidth: 200, minHeight: 70))
              }
            }
          }
          .padding()
          .toolbar {
            if gameUImanager.isConnectedToPeer == .connected {
              ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                  messageSheet = true
                  messageUnreadIcon = false
                } label: {
                  Image(systemName: messageUnreadIcon ? "message.badge.filled.fill" : "message.fill")
                    .foregroundColor(.blue)
                }.onChange(of: gameUImanager.peerMessage) { _ in
                  messageUnreadIcon = true
                }
              }
              ToolbarItem(placement: .navigationBarLeading) {
                Button {
                  gameUImanager.disconnect()
                } label: {
                  Text("Disconnect")
                    .foregroundColor(.blue)
                }
              }
            }
          }
          .sheet(isPresented: $messageSheet) {
            MessagingPageView()
        }
      }
    }
}

struct MultiplayerModeOneView_Previews: PreviewProvider {
    static var previews: some View {
      MultiplayerModeTwoView()
          .environmentObject(GameUIManager())
    }
}
