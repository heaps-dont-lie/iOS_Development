//
//  MultiplayerModeThreeView.swift
//  Home
//
//  Created by Aman Pandey on 4/28/23.
//

import SpriteKit
import SwiftUI

struct MultiplayerModeThreeView: View {
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
            if gameUImanager.isConnectedToPeer == .connected {
              Button {
                gameUImanager.gameModeThree = true
              }label: {
                Text("Play Game")
                  .font(.largeTitle)
                  .foregroundColor(.black)
                  .background(RoundedRectangle(cornerRadius: 20).fill(Color.yellow).frame(minWidth: 200, minHeight: 70))
              }.padding(50).fullScreenCover(isPresented: $gameUImanager.gameModeThree) {
                SpriteView(scene: gameUImanager.getGameScene(mode: .gameModeThree))
                  .ignoresSafeArea()
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

struct MultiplayerModeThreeView_Previews: PreviewProvider {
    static var previews: some View {
        MultiplayerModeThreeView()
    }
}
