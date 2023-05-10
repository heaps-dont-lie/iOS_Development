//
//  MessagingPageView.swift
//  Home
//
//  Created by Aman Pandey on 4/16/23.
//

import SwiftUI

struct MessagingPageView: View {
    @EnvironmentObject var gameUImanager: GameUIManager
    @State var message = ""
    var messageTemplates = ["Wanna play again?", "Close Match!!", "Well Played!", "Until Next Time.", "GoodBye."]
  
    var body: some View {
      VStack {
        VStack {
          Text("\(gameUImanager.peerMessage)")
        }.padding()

        VStack {
          TextField("Type your message here", text: $message)
            .onSubmit {
              gameUImanager.sendData(data: "\(DataTransferProtocol.afp_msg.rawValue):\(message)")
            }
          
          ScrollView(.horizontal, showsIndicators: false) {
            HStack {
              ForEach(0..<messageTemplates.count, id: \.self) { index in
                Button {
                  message = messageTemplates[index]
                } label: {
                  Text(messageTemplates[index])
                    .font(.title3)
                    .foregroundColor(.black)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color.blue).frame(minWidth: 200, minHeight: 30))
                }
              }.padding(50)
            }
          }
          
        }.padding()
        
      }
    }
}

struct MessagingPageView_Previews: PreviewProvider {
    static var previews: some View {
        MessagingPageView()
          .environmentObject(GameUIManager())
    }
}
