//
//  GameUIManager.swift
//  Home
//
//  Created by Aman Pandey on 4/1/23.
//

import Foundation
import SpriteKit

enum ConnectionStatus: String {
  case connected = "Connected", connecting = "Connecting", notConnected = "Not Connected", unknown = "Unknown Status"
}

class GameUIManager : ObservableObject, MPCManagerDelegate, GameSceneDelegate {

  var mpcManager : MPCManager
  
  @Published var receivedData = ""
  @Published var isConnectedToPeer: ConnectionStatus = .notConnected
  @Published var peerScore: Int?
  @Published var peerTossValue: Int?
  @Published var myTossValue: Int?
  @Published var myTurn = false
  @Published var peerMessage = ""
  @Published var matchResult: String?
  @Published var tossFlag = false
  @Published var gameModeOne = false
  @Published var gameModeTwo = false
  @Published var gameModeThree = false
  @Published var maxScore = 0
  
  /* Creating a variable to display the Game Scene */
  var gameScene: GameScene?
  
  init(){
    mpcManager = MPCManager()
    mpcManager.delegate = self
  }
  
  /* Some starter functions to implement the Multiplayer feature-------*/
  
  func advertise() {
    mpcManager.mpcAdvertise()
  }
  
  func invite() {
    mpcManager.mpcInvite()
  }
  
  func disconnect() {
    //sendData(data: "\(DataTransferProtocol.afp_disconnect.rawValue):Signal")
    mpcManager.mcSession.disconnect()
    resetPeer()
  }
  
  func resetPeer() {
    matchResult = nil
    peerScore = nil
    peerTossValue = nil
    tossFlag = false
    myTurn = false
  }
  
  func sendData(data: String) {
    mpcManager.mpcSendData(data: data)
  }
  
  func doToss() {
    matchResult = nil
    peerScore = nil
    self.myTossValue = Int.random(in: 1...100000)
    if peerTossValue != nil {
      tossResult()
    } else {
      sendData(data: "\(DataTransferProtocol.afp_toss.rawValue):\(self.myTossValue!)")
    }
  }
  
  // TODO: redo toss in case of tie
  func tossResult() {
    guard let mytossvalue = self.myTossValue else { return }
    if let peertossvalue = self.peerTossValue {
      self.myTurn = mytossvalue > peertossvalue ? true : false
      tossFlag = false
      //TODO: (BUG HERE!!)Should send an ACK here to peer to disable TOSS button. Also let the other player know who's 1st
      sendData(data: "\(DataTransferProtocol.afp_tossFlag):TossFlag")
    }
  }
  
  func getGameScene(mode: GamePlayMode) -> SKScene {
    gameScene = GameScene()
    
    gameScene!.mpcHandler = mpcManager
    gameScene!.size = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)  //UIScreen.main.bounds.size
    gameScene!.scaleMode = .aspectFill
    gameScene!.anchorPoint = CGPoint(x: 0.5, y: 0.5)
    gameScene!.gamePlayMode = mode
    gameScene!.scoreToBeat = nil
    gameScene!.myDelegate = self
    
    if let value = peerScore {
      gameScene!.scoreToBeat = value
    } else {
      gameScene!.scoreToBeat = nil
    }
    return gameScene!
  }
  
  /* MPCManagerDelegate Stubs */
  func currValDidChange(newVal: String) {
    receivedData = newVal
  }
  
  func currPeerLocationDidChange(newVal: String) {
    DispatchQueue.main.async {
      var x: CGFloat = CGFloat()
      var y: CGFloat = CGFloat()
      
      let substrings = newVal.components(separatedBy: ",")
      
      if substrings.count == 2 {
        let formatter = NumberFormatter()
        formatter.decimalSeparator = "."
        if let a = formatter.number(from: substrings[0]), let b = formatter.number(from: substrings[1]) {
          x = CGFloat(truncating: a)
          y = CGFloat(truncating: b)
          self.gameScene!.currentPeerLocation = CGPoint(x: x, y: y)
          print("PEER LOCATION: ", x, y)
          return
        }
        print("Error: Could not parse string")
        self.gameScene!.currentPeerLocation = CGPoint(x: self.gameScene!.frame.midX, y: self.gameScene!.frame.minY + 100)
        print(self.gameScene!.mpcHandler!.mcSession.connectedPeers[0].displayName, self.gameScene!.currentPeerLocation.x, self.gameScene!.currentPeerLocation.y)
      }
    }
  }
  
  func peerFiredAmmoSignal(newVal: String) {
    DispatchQueue.main.async {
      if newVal == "Triple" {
        self.gameScene!.fireAmmo(tripleFire: true, forPeer: true)
      } else if newVal == "Single" {
        self.gameScene!.fireAmmo(tripleFire: false, forPeer: true)
      }
    }
  }
  
  func isConnectedtoPeerDidChange(newVal: String) {
    DispatchQueue.main.async {
      if newVal == "Connected" {
        self.isConnectedToPeer = .connected
        self.doToss()
      } else if newVal == "Connecting" {
        self.isConnectedToPeer = .connecting
        self.resetPeer()
      } else if newVal == "Not Connected" {
        self.isConnectedToPeer = .connecting
        self.resetPeer()
      } else {
        self.isConnectedToPeer = .unknown
      }
    }
  }
  
  func peerScoreDidChange(newVal: String) {
    DispatchQueue.main.async {
      let formatter = NumberFormatter()
      if let score = formatter.number(from: newVal) {
        self.peerScore = Int(truncating: score)
        self.myTurn = true
      } else {
        self.peerScore = nil
      }
    }
  }
  
  func peerTossValueDidChange(newVal: String) {
    DispatchQueue.main.async {
      let formatter = NumberFormatter()
      if let tossValue = formatter.number(from: newVal) {
        self.peerTossValue = Int(truncating: tossValue)
        self.tossResult()
      } else {
        self.peerTossValue = nil
      }
    }
  }
  
  func peerMessageDidChange(newVal: String) {
    DispatchQueue.main.async {
      self.peerMessage = newVal
    }
  }
  
  func matchResultDidChange(newVal: String) {
    DispatchQueue.main.async {
      self.matchResult = newVal
      self.tossFlag = true
      self.peerTossValue = nil
      self.myTossValue = nil
      self.peerScore = nil
    }
  }
  
  func tossFlagDidChange(newVal: String) {
    DispatchQueue.main.async {
      self.tossFlag = false
    }
  }
  
  func disconnectSignal(newVal: String) {
    DispatchQueue.main.async {
      if newVal == "Signal" {
        self.matchResult = nil
        self.peerScore = nil
        self.peerTossValue = nil
        self.tossFlag = false
        self.myTurn = false
      }
    }
  }
  
  /*--------------------------------------------------------------------*/
  
  /* Game Scene Delegate Stubs*/
  func signalGameOverToSelf(newVal: Bool) {
    myTurn = !newVal
  }
  
  func didWin(newVal: String) {
    matchResult = newVal
    tossFlag = true
    peerTossValue = nil
    myTossValue = nil
    peerScore = nil
  }
  
  func exitFromGameMode(newVal: Bool, mode: GamePlayMode) {
    switch mode {
      case .gameModeOne:
        gameModeOne = newVal
      case .gameModeTwo:
        gameModeTwo = newVal
      case .gameModeThree:
        gameModeThree = newVal
    }
  }
  
  func notifyScore(newVal: Int) {
    if newVal > maxScore {
      maxScore = newVal
    }
  }
  
}
