//
//  MultipeerJSON.swift
//  Pods
//
//  Created by Brian Semiglia on 7/3/17.
//
//

import Foundation
import MultipeerConnectivity
import RxSwift

public class MultipeerJSON:
             NSObject,
             MCNearbyServiceBrowserDelegate,
             MCSessionDelegate {

  private let cleanup = DisposeBag()
  private var input = ReplaySubject<[AnyHashable: Any]>.create(bufferSize: 1000)
  private let output = BehaviorSubject<[AnyHashable: Any]>(value: [:])
  
  var session: MCSession?
  let mine: MCPeerID
  let browser: MCNearbyServiceBrowser
  
  public override init() {
    mine = MCPeerID(
      displayName: UIDevice.current.name
    )
    browser = MCNearbyServiceBrowser(
      peer: mine,
      serviceType: "Cycle-Monitor"
    )
    super.init()
    browser.delegate = self
    browser.startBrowsingForPeers()
  }
  
  public func rendered(_ input: Observable<[AnyHashable: Any]>) -> Observable<[AnyHashable: Any]> {
    
    input.subscribe { [weak self] in
      if let element = $0.element {
        self?.input.on(.next(element))
      }
    }.disposed(by: cleanup)
    
    return output
  }
  
  func render(_ input: [AnyHashable: Any]) {
    if let connected = session?.connectedPeers {
      try? session?.send(
        JSONSerialization.data(
          withJSONObject: input,
          options: JSONSerialization.WritingOptions(rawValue: 0)
        ),
        toPeers: connected,
        with: .reliable
      )
    }
  }
  
  public func browser(
    _ browser: MCNearbyServiceBrowser,
    foundPeer peerID: MCPeerID,
    withDiscoveryInfo info: [String : String]?
  ) {
    if session == nil {
      browser.stopBrowsingForPeers()
      let session = MCSession(
        peer: mine,
        securityIdentity: nil,
        encryptionPreference: .required
      )
      session.delegate = self
      browser.invitePeer(
        peerID,
        to: session,
        withContext: nil,
        timeout: 100.0
      )
      self.session = session
    }
  }
  
  public func browser(
    _ browser: MCNearbyServiceBrowser,
    lostPeer peerID: MCPeerID
  ) {
    
  }
  
  public func session(
    _ session: MCSession,
    peer peerID: MCPeerID,
    didChange state: MCSessionState
  ) {
    switch state {
    case .connected:
      DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
        self.input.subscribe { [weak self] in
          if let element = $0.element {
            self?.render(element)
          }
        }.disposed(by: self.cleanup)
      }
    case .connecting:
      break
    case .notConnected:
      self.session = nil
      browser.startBrowsingForPeers()
    }
  }
  
  public func session(
    _ session: MCSession,
    didReceive data: Data,
    fromPeer peerID: MCPeerID
  ) {
    
  }
  
  public func session(
    _ session: MCSession,
    didReceive stream: InputStream,
    withName streamName: String,
    fromPeer peerID: MCPeerID
  ) {
    
  }
  
  public func session(
    _ session: MCSession,
    didStartReceivingResourceWithName resourceName: String,
    fromPeer peerID: MCPeerID,
    with progress: Progress
  ) {
    
  }
  
  public func session(
    _ session: MCSession,
    didFinishReceivingResourceWithName resourceName: String,
    fromPeer peerID: MCPeerID,
    at localURL: URL,
    withError error: Error?
  ) {

  }
  
}
