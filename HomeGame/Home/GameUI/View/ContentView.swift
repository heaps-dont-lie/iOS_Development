//
//  ContentView.swift
//  Home
//
//  Created by Aman Pandey on 4/1/23.
//speaker.slash.fill

import AVFoundation
import SwiftUI


var audioPlayer: AVAudioPlayer!
var audioPlayerDelegate: AudioPlayerDelegate!

struct ContentView: View {
    @EnvironmentObject var gameUImanager : GameUIManager
    @State var mute = true
    @State var info = false
  
    var body: some View {
      NavigationView {
        HomePageView()
          .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
              Button {
                info = true
              } label: {
                Image(systemName: "info.circle.fill").foregroundColor(.cyan)
              }.sheet(isPresented: $info) {
                NavigationStack {
                  VStack {
                    Text("Information")
                      .font(.largeTitle)
                      .padding()
                    
                    Text("1. Single Player")
                      .font(.title)
                    Text("A single player plays the game.")
                      .padding()
                    
                    Text("2. Multiplayer: 1-VS-1")
                      .font(.title)
                    Text("Two players compete against each other and play in their respective turns one-by-one.")
                      .padding()
                    
                    Text("3. Multiplayer: Live")
                      .font(.title)
                    Text("Two players compete against each other simultaneously where they can see each other on their own screens.")
                      .padding()
                  }
                }
              }
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
              Button {
                mute.toggle()
                if !mute {
                  let sound = Bundle.main.path(forResource: "spaceSong", ofType: "mp3")
                  audioPlayer = try! AVAudioPlayer(contentsOf: URL(fileURLWithPath: sound!))
                  audioPlayerDelegate = AudioPlayerDelegate()
                  audioPlayer.delegate = audioPlayerDelegate
                  audioPlayer.play()
                } else {
                  audioPlayer.stop()
                }
              } label: {
                Image(systemName: mute ? "speaker.slash.fill" : "speaker.fill").foregroundColor(.cyan)
              }
            }
          }
        
      }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
          .environmentObject(GameUIManager())
    }
}

class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    var audioPlayer: AVAudioPlayer!
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            print("Audio finished playing")
            self.audioPlayer.play()
        }
    }
}
