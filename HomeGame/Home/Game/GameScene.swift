//
//  GameScene.swift
//  Home
//
//  Created by Aman Pandey on 4/3/23.
//

import MultipeerConnectivity
import GameplayKit
import CoreMotion
import SpriteKit


enum CollisionType: UInt32 {
  case spaceShip = 1
  case spaceDebris = 2
  case fireball = 4
  case collectibles = 8
}

enum GamePlayMode: Int {
  case gameModeOne = 1, gameModeTwo = 2, gameModeThree = 3
}

class GameScene: SKScene, SKPhysicsContactDelegate {
  /* Multiplayer */
  var mpcHandler: MPCManager?
  var mpcSpaceShips: [MCPeerID : SKSpriteNode] = [MCPeerID : SKSpriteNode]() /* Nodes for other players */
  
  
  /* For motion purposes */
  let motionManager = CMMotionManager()
  var xAcceleration: CGFloat = 0

  /* Defining Nodes for the Game */
  let spaceShip = SKSpriteNode(imageNamed: "ship")
  let score = SKLabelNode(fontNamed: "AmericanTypewriter")
  let pauseButton = SKLabelNode(fontNamed: "AmericanTypewriter")
  let endButton = SKLabelNode(fontNamed: "AmericanTypewriter")
  let left = SKLabelNode(text: "←")    // For Testing purposes.
  let right = SKLabelNode(text: "→")   // For Testing purposes.
  
  /* Timer variable for spawning different Collectible nodes */
  /* Note: Make sure none of the spawned items overlap */
  var spawnAmmoTimer: Timer!
  var spawnCollectiblesTimer: Timer!
  var spawnSpaceDebrisTimer: Timer!
  var longPressTimer: Timer?
  var gameOverTimer: Timer?
  
  /* Delegate */
  weak var myDelegate: GameSceneDelegate?
  
  /* Game Scene properties */
  var currentScore : Int = 0 {
    didSet {
      score.text = "Score: \(currentScore)\nAmmo Count: \(currentAmmoCount)\nLives Left: \(currentlivesLeft)"
    }
  }
  
  var currentAmmoCount : Int = 50 {
    didSet {
      score.text = "Score: \(currentScore)\nAmmo Count: \(currentAmmoCount)\nLives Left: \(currentlivesLeft)"
    }
  }
  
  var currentlivesLeft : Int = 3 {
    didSet {
      score.text = "Score: \(currentScore)\nAmmo Count: \(currentAmmoCount)\nLives Left: \(currentlivesLeft)"
    }
  }
  
  //Hard code the initial value of x:frame.midX, y:frame.minY + 100 later.
  var currentPeerLocation: CGPoint = CGPoint() {
    didSet {
      if gamePlayMode != nil && gamePlayMode == .gameModeThree {
        mpcSpaceShips[mpcHandler!.mcSession.connectedPeers[0]]?.position = currentPeerLocation
      }
    }
  }
  
  var totalShotsAbove = 0
  var isTripleFire = false
  var scoreToBeat: Int?
  var gamePlayMode: GamePlayMode?
  var globalCount = 0
  
  
  override func didMove(to view: SKView) {
    
    /* Setting up the Starry background */
    if let background = SKEmitterNode(fileNamed: "Stars") {
      background.zPosition = -1
      background.advanceSimulationTime(60)
      addChild(background)
    }

    /* Add the Player in the Game Scene */
    initializePlayer()
    
    /* For Testing purposes. */
    initializeOrientationButtons()
    
    /* Initialize the score board */
    initializeInfoBoard()
    
    /* Initialize the pause button. */
    initializePauseButton()
    
    /* Add motion of the Player in the Game Scene */
    initializeMotion()
    

    self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
    self.physicsWorld.contactDelegate = self
    
    
    /* Spawning space debris and collectibles */
    spawnAmmoTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(spawnAmmo), userInfo: nil, repeats: true)
    spawnSpaceDebrisTimer = Timer.scheduledTimer(timeInterval: 0.75, target: self, selector: #selector(spawnSpaceDebris), userInfo: nil, repeats: true)
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    for touch in touches {
      let location = touch.location(in: self)
      let touchNode = atPoint(location)
      
      if touchNode.name == "Pause Game" {
        self.view?.isPaused.toggle()
      }
      
      else if touchNode.name == "End Game" {
        endGame()
      }
      
      /* For Testing purposes. */
      else if touchNode.name == "LeftArrow" {
        spaceShip.position.x -= 25
        
        if spaceShip.position.x <= frame.minX {
          spaceShip.position.x = frame.maxX
        } else if spaceShip.position.x >= frame.maxX {
          spaceShip.position.x = frame.minX
        }
        if gamePlayMode != nil && gamePlayMode == .gameModeThree {
          /* Sending self updated position to peer on clicking left button */
          let data_left = "\(DataTransferProtocol.afp_Mode_Three.rawValue):" + String(format: "%.4f", spaceShip.position.x) + "," + String(format: "%.4f", spaceShip.position.y)
          sendData(data: data_left)
        }
      }
      
      /* For Testing purposes. */
      else if touchNode.name == "RightArrow" {
        spaceShip.position.x += 25
        
        if spaceShip.position.x <= frame.minX {
          spaceShip.position.x = frame.maxX
        } else if spaceShip.position.x >= frame.maxX {
          spaceShip.position.x = frame.minX
        }
        if gamePlayMode != nil && gamePlayMode == .gameModeThree {
          /* Sending self updated position to peer on clicking right button */
          let data_right = "\(DataTransferProtocol.afp_Mode_Three.rawValue):" + String(format: "%.4f", spaceShip.position.x) + "," + String(format: "%.4f", spaceShip.position.y)
          sendData(data: data_right)
        }
      }
      
    }
    
    /* start the long press timer when a touch begins */
    longPressTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(longPressAction), userInfo: nil, repeats: false)
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    /* For Testing Purposes. */
    for touch in touches {
      let location = touch.location(in: self)
      let touchNode = atPoint(location)
      
      if touchNode.name != "RightArrow" && touchNode.name != "LeftArrow" && touchNode.name != "End Game" && touchNode.name != "Pause Game" {
        let values = isTripleFire ? (2, 3, true) : (0, 1, false)
        if currentAmmoCount > values.0 {
          currentAmmoCount -= values.1
          fireAmmo(tripleFire: values.2, forPeer: false)
          totalShotsAbove += values.1
        }
      }
    }
    
    /* cancel the long press timer when a touch ends */
    longPressTimer?.invalidate()
    longPressTimer = nil
    isTripleFire = false
    
  }
  
  override func didSimulatePhysics() {
    /* For testing purposes */
    //let randomValue = CGFloat.random(in: 100...500)
    
    spaceShip.position.x += xAcceleration * 50
    
    if spaceShip.position.x <= frame.minX {
      spaceShip.position.x = frame.maxX
    } else if spaceShip.position.x >= frame.maxX {
      spaceShip.position.x = frame.minX
    }
    //TODO: At this point I can send player's location (on current device) to my peer(s).
    //let data = String(format: "%.4f", spaceShip.position.x) + "*" + String(format: "%.4f", spaceShip.position.y)
    //mpcHandler!.mpcSendData(data: data)
  }
  
  func didBegin(_ contact: SKPhysicsContact) {
    let firstBody = contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask ? contact.bodyA : contact.bodyB
    let secondBody = contact.bodyA.categoryBitMask > contact.bodyB.categoryBitMask ? contact.bodyA : contact.bodyB
    guard (firstBody.node != nil && secondBody.node != nil) else { return }
    
    /* Collision --> spaceDebris & fireball */
    if (firstBody.categoryBitMask & CollisionType.spaceDebris.rawValue != 0) && (secondBody.categoryBitMask & CollisionType.fireball.rawValue != 0) {
      debrisFireballCollision(debris: firstBody.node as! SKSpriteNode, fireball: secondBody.node as! SKSpriteNode)
      currentScore += (firstBody.node?.name == "fireball") ? 1 : 2
      if gamePlayMode != nil && gamePlayMode == .gameModeTwo {
        if let value = scoreToBeat {
          if currentScore > value {
            gameOver(result: true)
          }
        }
      }
    } else if (firstBody.categoryBitMask & CollisionType.spaceShip.rawValue != 0) && (secondBody.categoryBitMask & CollisionType.collectibles.rawValue != 0) {
      spaceShipCollectibleCollision(ship: firstBody.node as! SKSpriteNode, collectible: secondBody.node as! SKSpriteNode)
      currentAmmoCount += 2
    } else if (firstBody.categoryBitMask & CollisionType.spaceShip.rawValue != 0) && (secondBody.categoryBitMask & CollisionType.spaceDebris.rawValue != 0) {
      spaceShipDebrisCollision(ship: firstBody.node as! SKSpriteNode, debris: secondBody.node as! SKSpriteNode)
    }
  }
  
  func initializePlayer() {
    /* Setting up the Space Ship --> HOST */
    initializeAPlayer(theShip: spaceShip, name: "Player0", peer: false)
    addChild(spaceShip)
    
    /* Setting up the Space Ship --> PEER, that is, Mode 3. */
    if gamePlayMode != nil && gamePlayMode == .gameModeThree {
      var i = 0
      while i < mpcHandler!.mcSession.connectedPeers.count {
        //May have to add a new ship for identification purposes.
        mpcSpaceShips[mpcHandler!.mcSession.connectedPeers[i]] = SKSpriteNode(imageNamed: "ship")
        initializeAPlayer(theShip: mpcSpaceShips[mpcHandler!.mcSession.connectedPeers[i]]!, name: "Player\(i+1)", peer: true)
        mpcSpaceShips[mpcHandler!.mcSession.connectedPeers[i]]!.position.x += 100
        addChild(mpcSpaceShips[mpcHandler!.mcSession.connectedPeers[i]]!)
        i += 1
        
        //Limiting to just 1 player for now
        break
      }
    }
  }
  
  func initializeAPlayer(theShip: SKSpriteNode, name: String, peer: Bool) {
    theShip.name = name
    theShip.size = CGSize(width: 75, height: 75)
    theShip.zPosition = 1
    theShip.position.x = frame.midX
    theShip.position.y = frame.minY + 100
    
    if !peer {
      theShip.physicsBody = SKPhysicsBody(rectangleOf: spaceShip.size)
      theShip.physicsBody?.isDynamic = false
      theShip.physicsBody?.categoryBitMask = CollisionType.spaceShip.rawValue
      theShip.physicsBody?.collisionBitMask = 0
      theShip.physicsBody?.contactTestBitMask = CollisionType.spaceDebris.rawValue | CollisionType.collectibles.rawValue
    }
  }
  
  func initializeOrientationButtons() {
    left.position = CGPoint(x: frame.minX + 50, y: frame.minY + 50)
    left.fontColor = UIColor(.white)
    left.fontSize = 30
    left.name = "LeftArrow"
    
    right.position = CGPoint(x: frame.minX + 100, y: frame.minY + 50)
    right.fontColor = UIColor(.white)
    right.fontSize = 30
    right.name = "RightArrow"
    
    addChild(left)
    addChild(right)
  }
  
  func initializeInfoBoard() {
    score.position = CGPoint(x: frame.maxX-10, y: frame.maxY-120)
    score.zPosition = 0
    score.text = "Score: \(currentScore)\nAmmo Left: \(currentAmmoCount)\nLives Left: \(currentlivesLeft)"
    score.numberOfLines = 3
    score.fontSize = 20
    score.fontColor = UIColor(.green)
    score.horizontalAlignmentMode = .right
    addChild(score)
  }
  
  func initializePauseButton() {
    pauseButton.name = "Pause Game"
    pauseButton.position = CGPoint(x: frame.minX+20, y: frame.maxY-150)
    pauseButton.zPosition = 0
    pauseButton.text = "⏯"
    pauseButton.fontSize = 30
    pauseButton.fontColor = UIColor(.cyan)
    
    endButton.name = "End Game"
    endButton.position = CGPoint(x: frame.minX+30, y: frame.maxY-90)
    endButton.fontSize = 20
    endButton.text = "❌"
    endButton.fontColor = UIColor(.red)
    endButton.horizontalAlignmentMode = .right
    
    addChild(endButton)
    
    addChild(pauseButton)
  }
  
  func initializeMotion() {
    /* Setting up the way to move the spacecraft (Just Laterally) */
    motionManager.accelerometerUpdateInterval = 0.2
    motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { data, error in
      if let accelData = data {
        self.xAcceleration = accelData.acceleration.x * 0.75 + self.xAcceleration * 0.25
      }
    }
  }
  
  func initializeAmmoCollected() -> SKLabelNode {
    // create the checkpoint label
    let checkpointLabel = SKLabelNode(fontNamed: "AmericanTypewriter")
    checkpointLabel.text = "+2"
    checkpointLabel.fontSize = 24
    checkpointLabel.fontColor = .orange
    checkpointLabel.position = CGPoint(x: frame.midX, y: frame.midY)
    checkpointLabel.alpha = 0.0 // hide the label initially
    return checkpointLabel
  }
  
  func fireAmmo(tripleFire: Bool, forPeer: Bool) {
    let ammo = loadAmmo(id: 0, forPeer: forPeer)
    if tripleFire {
      let ammo_left = loadAmmo(id: 1, forPeer: forPeer)
      let ammo_right = loadAmmo(id: 2, forPeer: forPeer)
      
      ammo.0.run(SKAction.sequence(ammo.1))
      ammo_left.0.run(SKAction.sequence(ammo_left.1))
      ammo_right.0.run(SKAction.sequence(ammo_right.1))
    } else {
      ammo.0.run(SKAction.sequence(ammo.1))
    }
    if gamePlayMode != nil && gamePlayMode == .gameModeThree && !forPeer {
      let val = tripleFire ? "Triple" : "Single"
      sendData(data: "\(DataTransferProtocol.afp_fireBall.rawValue):\(val)")
    }
  }
  
  func loadAmmo(id: Int, forPeer: Bool) -> (SKSpriteNode, [SKAction]) {
    let object = ((gamePlayMode != nil && gamePlayMode == .gameModeThree) && (forPeer)) ? mpcSpaceShips[mpcHandler!.mcSession.connectedPeers[0]]! : spaceShip
    let ammo = SKSpriteNode(imageNamed: "fireball")
    var ammoActions = [SKAction]()
    
    ammo.name = "FireBall"
    ammo.size = CGSize(width: 20, height: 20)
    ammo.position.x = object.position.x
    ammo.position.y = object.position.y + 2
    
    ammo.physicsBody = SKPhysicsBody(circleOfRadius: ammo.size.width / 2)
    ammo.physicsBody?.isDynamic = true
    ammo.physicsBody?.categoryBitMask = CollisionType.fireball.rawValue
    ammo.physicsBody?.collisionBitMask = 0
    ammo.physicsBody?.contactTestBitMask = CollisionType.spaceDebris.rawValue
    
    addChild(ammo)
    
    if id == 0 {
      ammoActions.append(SKAction.move(by: CGVector(dx: 0, dy: frame.size.height), duration: 0.3))
    } else if id == 1 {
      ammoActions.append(SKAction.move(by: CGVector(dx: -frame.size.width, dy: frame.size.height), duration: 0.3))
    } else {
      ammoActions.append(SKAction.move(by: CGVector(dx: frame.size.width, dy: frame.size.height), duration: 0.3))
    }
    ammoActions.append(SKAction.removeFromParent())
    
    return (ammo, ammoActions)
  }
  
  func gameOver(result: Bool?) {
    view?.isPaused = true
    
    let gameover = SKLabelNode(text: "Game Over!")
    gameover.position = CGPoint(x: frame.midX, y: frame.midY)
    gameover.fontSize = 50
    gameover.fontColor = UIColor(.red)
    addChild(gameover)
    
    if let value = result {
      let gameResult = SKLabelNode(text: value ? "WON!!" : "LOST")
      gameResult.position = CGPoint(x: frame.midX, y: frame.midY - 100)
      gameResult.fontSize = 70
      gameResult.fontColor = UIColor(.red)
      addChild(gameResult)
      sendData(data: "\(DataTransferProtocol.afp_result.rawValue):\(value ? "LOST" : "WON!!")")
    } else if gamePlayMode != nil && gamePlayMode == .gameModeTwo {
      sendData(data: "\(DataTransferProtocol.afp_score.rawValue):\(currentScore)")
    }
    
    /* Timer set to kill all the childs */
//    gameOverTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(killAll), userInfo: nil, repeats: false)
    
  }
  
  func endGame() {
    self.view?.isPaused = true
    scene?.removeAllChildren()
    spawnAmmoTimer.invalidate()
    spawnSpaceDebrisTimer.invalidate()
    if let value = gamePlayMode {
      
      switch value {
      case .gameModeOne:
        myDelegate?.notifyScore(newVal: currentScore)
      case .gameModeTwo:
        if scoreToBeat == nil {
          sendData(data: "\(DataTransferProtocol.afp_score.rawValue):\(currentScore)")
          myDelegate?.signalGameOverToSelf(newVal: true)
        } else {
          sendData(data: "\(DataTransferProtocol.afp_result.rawValue):\(currentScore > scoreToBeat! ? "LOST" : "WON!!")")
          myDelegate?.didWin(newVal: currentScore > scoreToBeat! ? "WON!!" : "LOST")
          myDelegate?.signalGameOverToSelf(newVal: true)
        }
      case .gameModeThree:
        //TODO: Something
        break
      }
      myDelegate?.exitFromGameMode(newVal: false, mode: value)
    }
  }
  
  @objc func killAll() {
    self.scene?.removeAllChildren()
    self.spawnAmmoTimer.invalidate()
    self.spawnSpaceDebrisTimer.invalidate()
    self.gameOverTimer?.invalidate()
  }
  
  @objc func spawnAmmo() {
    if gamePlayMode != nil && gamePlayMode == .gameModeThree {
      return
    }
    
    let ammoCollectible = SKSpriteNode(imageNamed: "ammo")
    let ammoDropPos = GKRandomDistribution(lowestValue: Int(frame.minX), highestValue: Int(frame.maxX)).nextInt()
    var spawnActions = [SKAction]()
    
    ammoCollectible.name = "Ammo"
    ammoCollectible.size = CGSize(width: 40, height: 40)
    ammoCollectible.position = CGPoint(x: CGFloat(ammoDropPos), y: frame.maxY)
    ammoCollectible.zPosition = 1
    
    ammoCollectible.physicsBody = SKPhysicsBody(rectangleOf: ammoCollectible.size)
    ammoCollectible.physicsBody?.isDynamic = true
    ammoCollectible.physicsBody?.categoryBitMask = CollisionType.collectibles.rawValue
    ammoCollectible.physicsBody?.collisionBitMask = 0 //CollisionType.spaceShip.rawValue
    ammoCollectible.physicsBody?.contactTestBitMask = CollisionType.spaceShip.rawValue
    
    addChild(ammoCollectible)
    
    spawnActions.append(SKAction.move(to: CGPoint(x: CGFloat(ammoDropPos), y: frame.minY), duration: 5))
    spawnActions.append(SKAction.removeFromParent())
    
    ammoCollectible.run(SKAction.sequence(spawnActions))
  }
  
  @objc func spawnSpaceDebris() {
    var index: Int = 0
    var debrisDropPos: Int = 0
    var spawnActions = [SKAction]()
    let spaceDebrisCollection = ["spaceDebrisBig", "spaceDebrisSmall", "fireball"]
    
    if gamePlayMode != nil && gamePlayMode == .gameModeThree {
      index = 1
      if globalCount % 3 == 0 {
        debrisDropPos = Int(frame.minX) + 50
      } else if globalCount % 3 == 1 {
        debrisDropPos = Int(frame.midX)
      } else {
        debrisDropPos = Int(frame.maxX) - 50
      }
      globalCount += 1
    }
    
    else {
      //spaceShip's ammo (the fireball) can take a U-turn due to Blackholes Gravity an can head towards the spacecraft.
      index = GKRandomDistribution(lowestValue: 0, highestValue: (totalShotsAbove == 0) ? 1 : 2).nextInt()
      if index == 2 {
        totalShotsAbove -= 1
      }
      debrisDropPos = GKRandomDistribution(lowestValue: Int(frame.minX), highestValue: Int(frame.maxX)).nextInt()
    }
    
    let debris = SKSpriteNode(imageNamed: spaceDebrisCollection[index])
    debris.name = spaceDebrisCollection[index]
    debris.size = (index == 0) ? CGSize(width: 60, height: 60) : ((index == 1) ? CGSize(width: 50, height: 50) : CGSize(width: 20, height: 20))
    debris.position = CGPoint(x: CGFloat(debrisDropPos), y: frame.maxY)
    debris.zPosition = 1
    
    debris.physicsBody = SKPhysicsBody(rectangleOf: debris.size)
    debris.physicsBody?.isDynamic = true
    debris.physicsBody?.categoryBitMask = CollisionType.spaceDebris.rawValue
    debris.physicsBody?.collisionBitMask = 0 //CollisionType.spaceShip.rawValue
    debris.physicsBody?.contactTestBitMask = CollisionType.fireball.rawValue | CollisionType.spaceShip.rawValue
    
    addChild(debris)
    
    spawnActions.append(SKAction.move(to: CGPoint(x: CGFloat(debrisDropPos), y: frame.minY), duration: 5))
    spawnActions.append(SKAction.removeFromParent())
    
    debris.run(SKAction.sequence(spawnActions))
  }
  
  @objc func longPressAction() {
    isTripleFire = true
  }
  
  func debrisFireballCollision(debris: SKSpriteNode, fireball: SKSpriteNode) {
    let explosion = SKEmitterNode(fileNamed: "explosion")
    explosion?.position = debris.position
    addChild(explosion!)
    
    // you can also split the big rock into 2 and make the 2 pieces travel in "A" shape.
    if debris.name == "spaceDebrisBig" {
      debris.name = "spaceDebrisSmall"
      debris.size = CGSize(width: 50, height: 50)
    } else {
      debris.removeFromParent()
    }
    fireball.removeFromParent()
    
    self.run(SKAction.wait(forDuration: 0.5)) {
      explosion?.removeFromParent()
    }
  }
  
  func spaceShipCollectibleCollision(ship: SKSpriteNode, collectible: SKSpriteNode) {
    let checkpointLabel = initializeAmmoCollected()
    addChild(checkpointLabel)
    checkpointLabel.alpha = 1.0
    checkpointLabel.run(SKAction.sequence([SKAction.move(to: CGPoint(x: frame.midX, y: frame.midY+10), duration: 0.75), SKAction.fadeOut(withDuration: 0.25), SKAction.removeFromParent()]))
    collectible.removeFromParent()
  }
  
  func spaceShipDebrisCollision(ship: SKSpriteNode, debris: SKSpriteNode) {
    currentlivesLeft -= 1
    
    let explosion = SKEmitterNode(fileNamed: "explosion")
    explosion?.position = debris.position
    addChild(explosion!)
    
    self.run(SKAction.wait(forDuration: 0.5)) {
      explosion?.removeFromParent()
    }
    
    if currentlivesLeft <= 0 {
      if gamePlayMode != nil && gamePlayMode == .gameModeTwo {
        if let value = scoreToBeat {
          gameOver(result: currentScore > value)
        } else {
          gameOver(result: nil)
        }
      } else {
        gameOver(result: nil)
      }
    }
  }
  
}


/* This is the Network extension of the Game Scene */
extension GameScene: MPCManagerDelegate {
  
  func sendData(data: String){
    mpcHandler?.mpcSendData(data: data)
  }
  
  
  /* For Testing purposes */
  func currValDidChange(newVal: String) {

  }
  
  func currPeerLocationDidChange(newVal: String) {
    
  }
  
  func isConnectedtoPeerDidChange(newVal: String) {
    
  }
  
  func peerScoreDidChange(newVal: String) {
    
  }
  
  func peerTossValueDidChange(newVal: String) {
    
  }
  
  func peerMessageDidChange(newVal: String) {
    
  }
  
  func matchResultDidChange(newVal: String) {
    
  }
  
  func matchOverDidChange(newVal: String) {
    
  }
  
  func tossFlagDidChange(newVal: String) {
    
  }
  
  func peerFiredAmmoSignal(newVal: String) {
    
  }
  
  func disconnectSignal(newVal: String) {
    
  }
  
}

protocol GameSceneDelegate: AnyObject {
  func signalGameOverToSelf(newVal: Bool)
  func didWin(newVal: String)
  func exitFromGameMode(newVal: Bool, mode: GamePlayMode)
  func notifyScore(newVal: Int)
}
