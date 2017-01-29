//
//  Session.swift
//  Cycle
//
//  Created by Brian Semiglia on 1/27/17.
//  Copyright © 2017 Brian Semiglia. All rights reserved.
//

import XCTest

class SessionTestCase: XCTestCase {
  
  func testModelConversion() {
    XCTAssert(
      Session.Model(Notification(name: .UIApplicationDidEnterBackground))
      .map { $0 == .didEnterBackground }
      ?? false
    )
    XCTAssert(
      Session.Model(Notification(name: .UIApplicationWillEnterForeground))
      .map { $0 == .willEnterForeground }
      ?? false
    )
    XCTAssert(
      Session.Model(Notification(name: .UIApplicationDidBecomeActive))
      .map { $0 == .didBecomeActive }
      ?? false
    )
    XCTAssert(
      Session.Model(Notification(name: .UIApplicationWillResignActive))
      .map { $0 == .willResignActive }
      ?? false
    )
    XCTAssert(
      Session.Model(Notification(name: .UIApplicationDidReceiveMemoryWarning))
      .map { $0 == .memoryWarning }
      ?? false
    )
    XCTAssert(
      Session.Model(Notification(name: .UIApplicationWillTerminate))
      .map { $0 == .willTerminate }
      ?? false
    )
    XCTAssert(
      Session.Model(Notification(name: .UIApplicationSignificantTimeChange))
      .map { $0 == .significantTimeChange }
      ?? false
    )
    XCTAssert(
      Session.Model(Notification(name: .UIApplicationDidFinishLaunching))
      .map { $0 == .didFinishLaunching }
      ?? false
    )
    XCTAssert(
      Session.Model(
        Notification(
          name: .UIApplicationDidFinishLaunching,
          object: nil,
          userInfo: [UIApplicationLaunchOptionsKey.location: 1]
        )
      )
      .map { $0 == .didFinishLaunchingWith(Session.Model.External.location(true)) }
      ?? false
    )
    XCTAssert(
      Session.Model(
        Notification(
          name: .UIApplicationDidFinishLaunching,
          object: nil,
          userInfo: [UIApplicationLaunchOptionsKey.localNotification: UILocalNotification()]
        )
      )
      .map { $0 == .didFinishLaunchingWith(Session.Model.External.notification(.local(UILocalNotification()))) }
      ?? false
    )
    XCTAssert(
      Session.Model(
        Notification(
          name: .UIApplicationDidFinishLaunching,
          object: nil,
          userInfo: [
            UIApplicationLaunchOptionsKey.url: URL(string: "http://google.com")!,
            UIApplicationLaunchOptionsKey.sourceApplication: ""
          ]
        )
      )
      .map {
        $0 == .didFinishLaunchingWith(
          Session.Model.External.query(
            Session.Model.External.Query(
              url: URL(string: "http://google.com")!,
              app: ""
            )
          )
        )
      }
      ?? false
    )
  }
  
  func testRemotePushConversion() {
    // Fails due to inability to compare payloads ([AnyHashable: Any])
    XCTAssert(
      Session.Model(
        Notification(
          name: .UIApplicationDidFinishLaunching,
          object: nil,
          userInfo: [UIApplicationLaunchOptionsKey.remoteNotification: ["":""]]
        )
      )
      .map { $0 == .didFinishLaunchingWith(Session.Model.External.notification(.remote(["":""]))) }
      ?? false
    )
  }
  
  func testModelEquality() {
    XCTAssert(.didEnterBackground == .didEnterBackground)
    XCTAssert(.willEnterForeground == .willEnterForeground)
    XCTAssert(.didFinishLaunching == .didFinishLaunching)
    XCTAssert(.didBecomeActive == .didBecomeActive)
    XCTAssert(.willResignActive == .willResignActive)
    XCTAssert(.memoryWarning == .memoryWarning)
    XCTAssert(.willTerminate == .willTerminate)
    XCTAssert(.significantTimeChange == .significantTimeChange)
  }
  
}
