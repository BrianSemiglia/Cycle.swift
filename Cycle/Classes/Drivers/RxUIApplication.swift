//
//  Session.swift
//  Cycle
//
//  Created by Brian Semiglia on 1/26/17.
//  Copyright © 2017 Brian Semiglia. All rights reserved.
//

import Foundation
import RxSwift

class Session {
  
  static let shared = Session()
  
  enum Model {
    enum External {
      struct Query {
        let url: URL
        let app: String
      }
      enum Notification {
        case local(UILocalNotification)
        case remote([AnyHashable: Any])
      }
      case query(Query)
      case location(Bool)
      case notification(Notification)
    }
    case willEnterForeground
    case didEnterBackground
    case didFinishLaunching
    case didFinishLaunchingWith(External)
    case didBecomeActive
    case willResignActive
    case willTerminate
    case significantTimeChange
    case memoryWarning
  }
  
  fileprivate let handler: Observable<Model>
  
  init() {
    handler = Observable.create { observer in
      [
        NSNotification.Name.UIApplicationDidEnterBackground,
        NSNotification.Name.UIApplicationWillEnterForeground,
        NSNotification.Name.UIApplicationDidFinishLaunching,
        NSNotification.Name.UIApplicationDidBecomeActive,
        NSNotification.Name.UIApplicationWillResignActive,
        NSNotification.Name.UIApplicationDidReceiveMemoryWarning,
        NSNotification.Name.UIApplicationWillTerminate,
        NSNotification.Name.UIApplicationSignificantTimeChange
      ].forEach { name in
        NotificationCenter.default.addObserver(
          forName: name,
          object: nil,
          queue: .main,
          using: { notification in
            if let new = Session.Model(notification) {
              observer.on(.next(new))
            }
          }
        )
      }
      return Disposables.create()
    }
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  func asObservable() -> Observable<Session.Model> { return
    handler
  }
  
}

extension Session.Model {
  init?(_ input: Notification) {
    switch input {
    case let a where a.name == .UIApplicationDidEnterBackground:
      self = .didEnterBackground
    case let a where a.name == .UIApplicationWillEnterForeground:
      self = .willEnterForeground
    case let a where a.name == .UIApplicationDidBecomeActive:
      self = .didBecomeActive
    case let a where a.name == .UIApplicationWillResignActive:
      self = .willResignActive
    case let a where a.name == .UIApplicationDidReceiveMemoryWarning:
      self = .memoryWarning
    case let a where a.name == .UIApplicationWillTerminate:
      self = .willTerminate
    case let a where a.name == .UIApplicationSignificantTimeChange:
      self = .significantTimeChange
    case let a where a.userInfo.flatMap { Session.Model.remote($0) } != nil:
      self = .didFinishLaunchingWith(
        .notification(
          .remote(
            Session.Model.remote(a.userInfo!)!
          )
        )
      )
    case let a where a.userInfo.flatMap { Session.Model.local($0) } != nil:
      self = .didFinishLaunchingWith(
        .notification(
          .local(
            Session.Model.local(a.userInfo!)!
          )
        )
      )
    case let a where a.userInfo.flatMap { Session.Model.query($0) } != nil:
      self = .didFinishLaunchingWith(
        .query(
          Session.Model.query(a.userInfo!)!
        )
      )
    case let a where a.userInfo.flatMap { Session.Model.location($0) } != nil:
      self = .didFinishLaunchingWith(
        .location(
          Session.Model.location(a.userInfo!)!
        )
      )
    case let a where a.name == .UIApplicationDidFinishLaunching:
      self = .didFinishLaunching
    default:
      return nil
    }
  
  fileprivate static func local(_ input: [AnyHashable: Any]) -> UILocalNotification? { return
    input[UIApplicationLaunchOptionsKey.localNotification] as? UILocalNotification
  }
  
  fileprivate static func query(_ input: [AnyHashable: Any]) -> Session.Model.External.Query? {
    if let
    url = input[UIApplicationLaunchOptionsKey.url] as? URL,
    let source = input[UIApplicationLaunchOptionsKey.sourceApplication] as? String {
      return Session.Model.External.Query(
        url: url,
        app: source
      )
    } else {
      return nil
    }
  }
  
  fileprivate static func remote(_ input: [AnyHashable: Any]) -> [String: Any]? { return
    input[UIApplicationLaunchOptionsKey.remoteNotification] as? [String: Any]
  }
  
  fileprivate static func location(_ input: [AnyHashable: Any]) -> Bool? { return
    input[UIApplicationLaunchOptionsKey.location]
    .flatMap { $0 as? NSNumber }
    .map { $0.boolValue }
  }
}

extension Session.Model: Equatable {
  static func ==(left: Session.Model, right: Session.Model) -> Bool {
    switch (left, right) {
    case (.didEnterBackground, .didEnterBackground): return true
    case (.willEnterForeground, .willEnterForeground): return true
    case (.didFinishLaunching, .didFinishLaunching): return true
    case (.didBecomeActive, .didBecomeActive): return true
    case (.willResignActive, .willResignActive): return true
    case (.memoryWarning, .memoryWarning): return true
    case (.willTerminate, .willTerminate): return true
    case (.significantTimeChange, .significantTimeChange): return true
    case (.didFinishLaunchingWith(let a), .didFinishLaunchingWith(let b)) where a == b: return true
    default: return false
    }
  }
}

extension Session.Model.External.Query: Equatable {
  static func ==(left: Session.Model.External.Query, right: Session.Model.External.Query) -> Bool { return
    left.url == right.url
    &&
    left.app == right.app
  }
}

extension Session.Model.External.Notification: Equatable {
  static func ==(left: Session.Model.External.Notification, right: Session.Model.External.Notification) -> Bool {
    switch (left, right) {
    case (.local(let a), .local(let b)) where a == b: return true
//  case (.remote(let a), .remote(let b)) where a == b: return true
    default: return false
    }
  }
}

extension Session.Model.External: Equatable {
  static func ==(left: Session.Model.External, right: Session.Model.External) -> Bool {
    switch (left, right) {
    case (.query(let a), .query(let b)) where a == b: return true
    case (.location(let a), .location(let b)) where a == b: return true
    case (.notification(let a), .notification(let b)) where a == b: return true
    default: return false
    }
  }
}
