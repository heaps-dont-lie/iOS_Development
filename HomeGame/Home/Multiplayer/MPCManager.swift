//
//  MPCManager.swift
//  Home
//
//  Created by Aman Pandey on 4/1/23.
//

import UIKit
import Foundation
import MultipeerConnectivity

enum DataTransferProtocol: String {
  case afp_score = "Score", afp_toss = "Toss", afp_msg = "Message", afp_result = "Result"
  case afp_Mode_Three = "Mode_Three", afp_tossFlag = "TossFlag", afp_fireBall = "Fire"
  case afp_disconnect = "Disconnect"
}

class MPCManager: NSObject, ObservableObject, MCSessionDelegate, MCBrowserViewControllerDelegate, MCNearbyServiceAdvertiserDelegate {
  
  var mcpeerID: MCPeerID
  var mcSession: MCSession
  var mcNearbyServiceAdvertiser: MCNearbyServiceAdvertiser?
  
  weak var delegate: MPCManagerDelegate?
  
  /* For Testing purposes */
  var currentVal : String = "" {
    didSet {
      delegate?.currValDidChange(newVal: currentVal)
    }
  }
  
  var peerLocation: String = "" {
    didSet {
      delegate?.currPeerLocationDidChange(newVal: peerLocation)
    }
  }
  
  var peerFiredAmmo: String = "" {
    didSet {
      delegate?.peerFiredAmmoSignal(newVal: peerFiredAmmo)
    }
  }
  
  var connectionStatus: String = "Not Connected" {
    didSet {
      delegate?.isConnectedtoPeerDidChange(newVal: connectionStatus)
    }
  }
  
  var peerScore: String = "" {
    didSet {
      delegate?.peerScoreDidChange(newVal: peerScore)
    }
  }
  
  var peerTossValue: String = "" {
    didSet {
      delegate?.peerTossValueDidChange(newVal: peerTossValue)
    }
  }
  
  var peerMessage: String = "" {
    didSet {
      delegate?.peerMessageDidChange(newVal: peerMessage)
    }
  }
  
  var matchResult: String = "" {
    didSet {
      delegate?.matchResultDidChange(newVal: matchResult)
    }
  }
  
  var tossFlag: String = "" {
    didSet {
      delegate?.tossFlagDidChange(newVal: tossFlag)
    }
  }
  
  var disconnectFlag: String = "" {
    didSet {
      delegate?.disconnectSignal(newVal: disconnectFlag)
    }
  }
  
  override init() {
    mcpeerID = MCPeerID(displayName: UIDevice.current.name)
    mcSession = MCSession(peer: mcpeerID, securityIdentity: nil, encryptionPreference: .required)
    super.init()
    mcSession.delegate = self
  }
  
  /* GameUI Helper Functions */
  func mpcAdvertise() {
    mcNearbyServiceAdvertiser = MCNearbyServiceAdvertiser(peer: mcpeerID, discoveryInfo: nil, serviceType: "afp-game")
    mcNearbyServiceAdvertiser?.delegate = self
    mcNearbyServiceAdvertiser?.startAdvertisingPeer()
  }
  
  func mpcInvite() {
    let browser = MCBrowserViewController(serviceType: "afp-game", session: mcSession)
    browser.delegate = self
    UIApplication.shared.windows.first?.rootViewController?.present(browser, animated: true)
  }
  
  func mpcSendData(data: String) {
    if let val = data.data(using: .utf8) {
      try? mcSession.send(val, toPeers: mcSession.connectedPeers, with: .reliable)
    }
  }
  
  func serializeAndSetNetworkData(data: String) {
    let components = data.components(separatedBy: ":")
    let dataTransferProtocol = components[0]
    let dataVal = components[1]
    
    /* DEBUG */
    print(data)
    
    if dataTransferProtocol == DataTransferProtocol.afp_score.rawValue {
      self.peerScore = dataVal
    } else if dataTransferProtocol == DataTransferProtocol.afp_toss.rawValue {
      self.peerTossValue = dataVal
    } else if dataTransferProtocol == DataTransferProtocol.afp_msg.rawValue {
      self.peerMessage = dataVal
    } else if dataTransferProtocol == DataTransferProtocol.afp_result.rawValue {
      self.matchResult = dataVal
    } else if dataTransferProtocol == DataTransferProtocol.afp_Mode_Three.rawValue {
      self.peerLocation = dataVal
    } else if dataTransferProtocol == DataTransferProtocol.afp_tossFlag.rawValue {
      self.tossFlag = dataVal
    } else if dataTransferProtocol == DataTransferProtocol.afp_fireBall.rawValue {
      self.peerFiredAmmo = dataVal
    } else if dataTransferProtocol == DataTransferProtocol.afp_disconnect.rawValue {
      self.disconnectFlag = dataVal
    }
  }
  
  /* MC Delegate Stubs */
  func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
    switch state {
    case .connected:
      connectionStatus = "Connected"
    case .connecting:
      connectionStatus = "Connecting"
    case .notConnected:
      connectionStatus = "Not Connected"
    @unknown default:
      connectionStatus = "Unknow"
    }
  }
  
  func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
    if let val = String(data: data, encoding: .utf8) {
      DispatchQueue.main.async {
        self.serializeAndSetNetworkData(data: val)
      }
    }
  }
  
  func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
    
  }
  
  func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
    
  }
  
  func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
    
  }
  
  func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
    browserViewController.dismiss(animated: true)
  }
  
  func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
    browserViewController.dismiss(animated: true)
  }
  
  func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
    invitationHandler(true, mcSession)
  }
  
}

protocol MPCManagerDelegate : AnyObject {
  
  /* For Testing Purposes */
  func currValDidChange(newVal : String)
  
  func currPeerLocationDidChange(newVal: String)
  func peerFiredAmmoSignal(newVal: String)
  func isConnectedtoPeerDidChange(newVal: String)
  func peerScoreDidChange(newVal: String)
  func peerTossValueDidChange(newVal: String)
  func peerMessageDidChange(newVal: String)
  func matchResultDidChange(newVal: String)
  func tossFlagDidChange(newVal: String)
  func disconnectSignal(newVal: String)
}
