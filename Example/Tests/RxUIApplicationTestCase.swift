//
//  RxUIApplicationTestCase.swift
//  Cycle
//
//  Created by Brian Semiglia on 1/27/17.
//  Copyright © 2017 Brian Semiglia. All rights reserved.
//

import XCTest
@testable import Cycle
import RxSwift

class RxUIApplicationTestCase: XCTestCase {
  
  // Starts with EMPTY always
  static func statesFromCall(
    initial: RxUIApplication.Model = .empty,
    call: (RxUIApplication) -> Any
  ) -> [RxUIApplication.Model] {
    var output: [RxUIApplication.Model] = []
    let application = RxUIApplication(intitial: initial, application: UIApplication.shared)
    _ = application
      .rendered(.just(initial))
      .subscribe {
        if let new = $0.element {
          output += [new]
        }
      }
    _ = call(application)
    return output
  }
  
  // Only starts with EMPTY if not specified, thus difference with -statesFromCall
  static func statesFrom(
    stream: Observable<RxUIApplication.Model>,
    model: RxUIApplication.Model = .empty
  ) -> [RxUIApplication.Model] {
    var output: [RxUIApplication.Model] = []
    let application = RxUIApplication(intitial: model, application: UIApplication.shared)
    _ = application
      .rendered(stream)
      .subscribe {
        if let new = $0.element {
          output += [new]
        }
    }
    return output
  }
  
  func testWillTerminate() {
    
    XCTAssert(
      RxUIApplicationTestCase
      .statesFromCall { $0.applicationWillTerminate(UIApplication.shared) }
      .map { $0.session.state }
      ==
      [.currently(.awaitingLaunch), .pre(.terminated)]
    )
  }

  func testDidBecomeActive() {
    XCTAssert(
      RxUIApplicationTestCase
      .statesFromCall { $0.applicationDidBecomeActive(UIApplication.shared) }
      .map { $0.session.state }
      ==
      [.currently(.awaitingLaunch), .currently(.active(.some))]
    )
  }
  
  func testWillResignActive() {
    XCTAssert(
      RxUIApplicationTestCase
      .statesFromCall { $0.applicationWillResignActive(UIApplication.shared) }
      .map { $0.session.state }
      ==
      [.currently(.awaitingLaunch), .pre(.resigned)]
    )
  }
  
  func testDidEnterBackground() {
    XCTAssert(
      RxUIApplicationTestCase
      .statesFromCall { $0.applicationDidEnterBackground(UIApplication.shared) }
      .map { $0.session.state }
      ==
      [.currently(.awaitingLaunch), .currently(.resigned)]
    )
  }
  
  func testWillFinishLaunching() {
    XCTAssert(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application(
          UIApplication.shared,
          willFinishLaunchingWithOptions: nil
        )
      }
      .map { $0.session.state }
      ==
      [.currently(.awaitingLaunch), .pre(.active(.first(nil)))]
    )
  }
  
  func testDidFinishLaunching() {
    XCTAssert(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application(
          UIApplication.shared,
          didFinishLaunchingWithOptions: nil
        )
      }
      .map { $0.session.state }
      ==
      [.currently(.awaitingLaunch), .currently(.active(.first(nil)))]
    )
  }
  
  func testWillEnterBackground() {
    XCTAssertEqual(
      RxUIApplicationTestCase
      .statesFromCall { $0.applicationWillEnterForeground(UIApplication.shared) }
      .map { $0.session.state }
      ,
      [.currently(.awaitingLaunch), .pre(.active(.some))]
    )
  }
  
  func testSignificantTimeChange() {
    XCTAssert(
      RxUIApplicationTestCase
      .statesFromCall { $0.applicationSignificantTimeChange(UIApplication.shared) }
      .map { $0.isObservingSignificantTimeChange }
      ==
      [false, true]
    )
  }
  
  func testMemoryWarning() {
    XCTAssert(
      RxUIApplicationTestCase
      .statesFromCall { $0.applicationDidReceiveMemoryWarning(UIApplication.shared) }
      .map { $0.isExperiencingMemoryWarning }
      ==
      [false, true]
    )
  }
  
  func testShouldRequestHealthAuthorization() {
    XCTAssert(
      RxUIApplicationTestCase
      .statesFromCall { $0.applicationShouldRequestHealthAuthorization(UIApplication.shared) }
      .map { $0.isExperiencingHealthAuthorizationRequest }
      ==
      [false, true]
    )
  }
  
  func testProtectedDataDidBecomeAvailable() {
    XCTAssert(
      RxUIApplicationTestCase
      .statesFromCall { $0.applicationProtectedDataDidBecomeAvailable(UIApplication.shared) }
      .map { $0.isProtectedDataAvailable }
      ==
      [.currently(false), .currently(true)]
    )
  }
  
  func testProtectedDataWillBecomeUnavailable() {
    XCTAssert(
      RxUIApplicationTestCase
      .statesFromCall { $0.applicationProtectedDataWillBecomeUnavailable(UIApplication.shared) }
      .map { $0.isProtectedDataAvailable }
      ==
      [.currently(false), .pre(false)]
    )
  }
  
  func testConversionCallbacks() {
    XCTAssert(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application(
          UIApplication.shared,
          didRegister: UIUserNotificationSettingsStub(id: "x")
        )
      }
      .map { $0.userNotificationSettings }
      ==
      [
        .idle,
        .registered(UIUserNotificationSettingsStub(id: "x") as UIUserNotificationSettings)
      ]
    )
  }
  
  func testDidFailToRegisterForRemoteNotifications() {
    XCTAssert(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application(
          UIApplication.shared,
          didFailToRegisterForRemoteNotificationsWithError: ErrorStub(id: "x")
        )
      }
      .map { $0.remoteNotificationRegistration }
      ==
      [.idle, .error(ErrorStub(id: "x") as Error)]
    )
  }
  
  func testDidRegisterForRemoteNotifications() {
    XCTAssert(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application(
          UIApplication.shared,
          didRegisterForRemoteNotificationsWithDeviceToken: Data()
        )
      }
      .map { $0.remoteNotificationRegistration }
      ==
      [.idle, .some(token: Data())]
    )
  }
  
  func testDidDecodeRestorableState() {
    XCTAssert(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application(
          UIApplication.shared,
          didDecodeRestorableStateWith: CoderStub(id: "x")
        )
      }
      .map { $0.stateRestoration }
      ==
      [.idle, .decoding(CoderStub(id: "x"))]
    )
  }
  
  func testWillEncodeRestorableState() {
    XCTAssert(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application(
          UIApplication.shared,
          willEncodeRestorableStateWith: CoderStub(id: "x")
        )
      }
      .map { $0.stateRestoration }
      ==
      [.idle, .encoding(CoderStub(id: "x"))]
    )
  }
  
  func testShouldSaveApplicationStateConsidering() {
    XCTAssert(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application(
          UIApplication.shared,
          shouldSaveApplicationState: CoderStub(id: "x")
        )
      }
      .map { $0.shouldSaveApplicationState }
      ==
      [.idle, .considering(CoderStub(id: "x") as NSCoder)]
    ) // might want to refactor to bool or change default to .allow(true)
  }
  
  func testShouldRestoreApplicationStateConsidering() {
    XCTAssert(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application(
          UIApplication.shared,
          shouldRestoreApplicationState: CoderStub(id: "x")
        )
      }
      .map { $0.shouldRestoreApplicationState }
      ==
      [.idle, .considering(CoderStub(id: "x") as NSCoder)]
    ) // might want to refactor to bool or change default to .allow(true)
  }
  
  func testWillContinueUserActivityWithType() {
    XCTAssert(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application(
          UIApplication.shared,
          willContinueUserActivityWithType: "x"
        )
      }
      .map { $0.userActivityState }
      ==
      [.idle, .willContinue("x")]
    )
  }
  
  func testDidFailToContinueUserActivity() {
    XCTAssert(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application(
          UIApplication.shared,
          didFailToContinueUserActivityWithType: "x",
          error: ErrorStub(id: "y")
        )
      }
      .map { $0.userActivityState }
      ==
      [.idle, .failing("x", ErrorStub(id: "y"))]
    )
  }
  
  func testDidUpdateUserActivity() {
    let activity = NSUserActivity(activityType: "x")
    XCTAssert(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application(
          UIApplication.shared,
          didUpdate: activity
        )
      }
      .map { $0.userActivityState }
      ==
      [.idle, .completing(activity)]
    )
  }
  
  func testContinueUserActivity() {
    let activity = NSUserActivity(activityType: "x")
    XCTAssert(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application(
          UIApplication.shared,
          continue: activity,
          restorationHandler: { _ in }
        )
      }
      .map { $0.userActivityState }
      ==
      [.idle, .isContinuing(activity, restoration: { _ in })]
    )
  }
  
  func testWillChangeStatusBarOrientation() {
    XCTAssert(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application(
          UIApplication.shared,
          willChangeStatusBarOrientation: .landscapeLeft,
          duration: 0.0
        )
      }
      .map { $0.statusBarOrientation }
      ==
      [.currently(.unknown), .pre(.landscapeLeft)]
    )
  }
  
  func testDidChangeStatusBarOrientation() {
    // This can fail based on simulator. Needs better solution.
    XCTAssertEqual(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application(
          UIApplication.shared,
          didChangeStatusBarOrientation: .landscapeLeft
        )
      }
      .map { $0.statusBarOrientation }
      ,
      [.currently(.unknown), .currently(.portrait)]
    )
  }
  
  func testWillChangeStatusBarFrame() {
    XCTAssert(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application(
          UIApplication.shared,
          willChangeStatusBarFrame: CGRect(x: 1, y: 2, width: 3, height: 4)
        )
      }
      .map { $0.statusBarFrame }
      ==
      [.currently(.zero), .pre(CGRect(x: 1, y: 2, width: 3, height: 4))]
    )
  }
  
  func testDidChangeStatusBarFrame() {
    // Consider adding beginState to -willChange enum option .pre(from: to:)
    // Or firing changes for every frame of animation
    
//    XCTAssert(
//      RxUIApplicationTestCase
//      .statesFrom {
//        $0.application(
//          UIApplication.shared,
//          didChangeStatusBarFrame: CGRect(x: 1, y: 2, width: 3, height: 4)
//        )
//      }
//      .map { $0.statusBarFrame }
//      ==
//      [.none(.zero), .currently(CGRect(x: 0, y: 0, width: 320, height: 20))]
//    )
  }
  
  func testHandleActionWithIdentifierLocal() {
    XCTAssert(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application(
          UIApplication.shared,
          handleActionWithIdentifier: "x",
          for: UILocalNotification(),
          completionHandler: {}
        )
      }
      .map { $0.localAction }
      ==
      [
        .idle,
        .progressing(
          .ios8(
            id: .some( "x"),
            notification: UILocalNotification(),
            completion: {}
          )
        )
      ]
    )
  }
  
  func testHandleActionWithIdentifierResponseInfoRemote() {
    XCTAssert(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application(
          UIApplication.shared,
          handleActionWithIdentifier: "x",
          forRemoteNotification: ["y":"z"],
          withResponseInfo: ["a":"b"],
          completionHandler: {}
        )
      }
      .map { $0.remoteAction }
      ==
      [
        .idle,
        .progressing(
          .ios9(
            id: .some( "x"),
            userInfo: ["y":"z"],
            responseInfo: ["a":"b"],
            completion: {}
          )
        )
      ]
    )
  }
  
  func testHandleActionWithIdentifierResponseInfoRemoteComplete_ios9() {
    var x = RxUIApplication.Model.empty
    x.remoteAction = .complete(
      .ios9(
        id: .some( "x"),
        userInfo: ["y":"z"],
        responseInfo: ["a":"b"],
        completion: {}
      )
    )
    XCTAssert(
      RxUIApplicationTestCase
        .statesFrom(stream: .just(x))
        .map { $0.remoteAction }
        ==
        [.idle]
    )
  }
  
  func testHandleActionWithIdentifierResponseInfoRemoteComplete_ios8() {
    var x = RxUIApplication.Model.empty
    x.remoteAction = .complete(
      .ios8(
        id: .some( "x"),
        userInfo: ["y":"z"],
        completion: {}
      )
    )
    XCTAssert(
      RxUIApplicationTestCase
        .statesFrom(stream: .just(x))
        .map { $0.remoteAction }
        ==
        [.idle]
    )
  }
  
  func testHandleActionWithIdentifierRemote() {
    XCTAssert(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application(
          UIApplication.shared,
          handleActionWithIdentifier: "x",
          forRemoteNotification: ["y":"z"],
          completionHandler: {}
        )
      }
      .map { $0.remoteAction }
      ==
      [
        .idle,
        .progressing(
          .ios8(
            id: .some( "x"),
            userInfo: ["y":"z"],
            completion: {}
          )
        )
      ]
    )
  }
  
  func testHandleActionWithIdentifierResponseInfo() {
    XCTAssert(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application(
          UIApplication.shared,
          handleActionWithIdentifier: "x",
          for: UILocalNotification(),
          withResponseInfo: ["y":"z"],
          completionHandler: {}
        )
      }
      .map { $0.localAction }
      ==
      [
        .idle,
        .progressing(
          .ios9(
            id: .some( "x"),
            notification: UILocalNotification(),
            response: ["y":"z"],
            completion: {}
          )
        )
      ]
    )
  }
  
  func testHandleActionLocalComplete_ios9() {
    var x = RxUIApplication.Model.empty
    x.localAction = .complete(
      .ios9(
        id: .defaultAction,
        notification: UILocalNotification(),
        response: ["a":"b"],
        completion: {}
      )
    )
    XCTAssert(
      RxUIApplicationTestCase
        .statesFrom(stream: .just(x))
        .map { $0.localAction }
        ==
        [.idle]
    )
  }
  
  func testHandleActionLocalComplete_ios8() {
    var x = RxUIApplication.Model.empty
    x.localAction = .complete(
      .ios8(
        id: .defaultAction,
        notification: UILocalNotification(),
        completion: {}
      )
    )
    XCTAssert(
      RxUIApplicationTestCase
        .statesFrom(stream: .just(x))
        .map { $0.localAction }
        ==
        [.idle]
    )
  }
  
  func testPerformActionForShortcutAction() {
    XCTAssert(
      RxUIApplicationTestCase.statesFromCall(
        initial: RxUIApplication.Model.empty.with(
          shortcutItem: RxUIApplication.Model.ShortcutAction(
            item: .stub,
            state: .idle
          )
        ),
        call: {
          $0.application(
            UIApplication.shared,
            performActionFor: .stub,
            completionHandler: { _ in }
          )
        }
      )
      .map { $0.shortcutActions }
      .flatMap { $0 }
      ==
      [
        RxUIApplication.Model.ShortcutAction(
          item: .stub,
          state: .idle
        ),
        RxUIApplication.Model.ShortcutAction(
          item: .stub,
          state: .progressing({ _ in })
        )
      ]
    )
  }
  
  func testHandleEventsForBackgroundURLSession() {
    XCTAssert(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application(
          UIApplication.shared,
          handleEventsForBackgroundURLSession: "x",
          completionHandler: {}
        )
      }
      .map { $0.backgroundURLSessions }
      .flatMap { $0 }
      ==
      [
        RxUIApplication.Model.BackgroundURLSessionAction(
          id: "x",
          completion: {},
          state: .progressing
        )
      ]
    )
  }
  
  func testDidReceiveRemoteNotification() {
    XCTAssert(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application(
          UIApplication.shared,
          didReceiveRemoteNotification: ["x":"y"],
          fetchCompletionHandler: { _ in }
        )
      }
      .map { $0.remoteNotifications }
      .flatMap { $0 }
      ==
      [
        RxUIApplication.Model.RemoteNofitication(
          notification: ["x":"y"],
          state: .progressing({ _ in })
        )
      ]
    )
  }
  
  func testHandlewatchKitExtensionRequestsProgressing() {
    XCTAssert(
      RxUIApplicationTestCase
        .statesFromCall {
          $0.application(
            UIApplication.shared,
            handlewatchKitExtensionRequests: ["x":"y"],
            reply: { _ in }
          )
        }
        .map { $0.watchKitExtensionRequests }
        .flatMap { $0 }
      ==
      [
        RxUIApplication.Model.watchKitExtensionRequests(
          completion: { _ in },
          state: .progressing(
            info: ["x":"y"]
          )
        )
      ]
    )
  }
  
  func testHandlewatchKitExtensionRequestsResponding() {
    var x = RxUIApplication.Model.empty
    x.watchKitExtensionRequests = [
      RxUIApplication.Model.watchKitExtensionRequests(
        completion: { _ in },
        state: .responding(
          response: ["x":"y"]
        )
      )
    ]
    XCTAssertEqual(
      RxUIApplicationTestCase.statesFrom(stream: .just(x))
        .map { $0.watchKitExtensionRequests }
        .flatMap { $0 },
      []
    )
  }
  
  func testShouldAllowExtensionPointIdentifier() {
    XCTAssert(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application(
          UIApplication.shared,
          shouldAllowExtensionPointIdentifier: .keyboard
        )
      }
      .map { $0.extensionPointIdentifier }
      ==
      [.idle, .considering(.keyboard)]
    )
  }
  
  func testSupportedInterfaceOrientationsFor() {
    XCTAssert(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application(
          UIApplication.shared,
          supportedInterfaceOrientationsFor: WindowStub(id: "x")
        )
      }
      .map { $0.interfaceOrientations }
      .flatMap { $0 }
      ==
      [.considering(WindowStub(id: "x") as UIWindow)]
    )
  }
  
  func testViewControllerWithRestorationIdentifierPathConsidering() {
    XCTAssert(
      RxUIApplicationTestCase
      .statesFromCall {
        let x = $0.application(
          UIApplication.shared,
          viewControllerWithRestorationIdentifierPath: ["x"],
          coder: CoderStub(id: "y")
        )
        return x ?? {}
      }
      .map { $0.viewControllerRestoration }
      ==
      [
        .idle,
        .considering(
          RxUIApplication.Model.RestorationQuery(
            identifier: "x",
            coder: CoderStub(id: "y") as NSCoder
          )
        )
      ]
    )
  }
  
  func testWillFinishLaunchingWithOptionsFalse() {
    let cycle = RxUIApplicationCycle { events, application -> Observable<RxUIApplicationTestCase.RxUIApplicationCycle.DriverModels> in
      application
      .rendered(events.map { $0.application })
      .map { model -> RxUIApplication.Model in
        switch model.session.state {
        case .pre(let a):
          switch a {
          case .active(.first):
            var new = model
            new.shouldLaunch = false
            return new
          default:
            return model
          }
        default:
          return model
        }
      }
      .withLatestFrom(events) { model, app in
        var edit = app
        edit.application = model
        return edit
      }
    }
    let delegate = CycledApplicationDelegate(
      filter: cycle
    ) as UIApplicationDelegate
    XCTAssertFalse(
      delegate.application!(
        UIApplication.shared,
        willFinishLaunchingWithOptions: [:]
      )
    )
  }
  
  func testShouldOpenURLs4() {
    let cycle = RxUIApplicationCycle { events, application -> Observable<RxUIApplicationTestCase.RxUIApplicationCycle.DriverModels> in
      application
      .rendered(events.map { $0.application })
      .map { model -> RxUIApplication.Model in
        var new = model
        if
        case .considering(let query) = model.urlActionIncoming,
        case .ios4(let URL, _, _) = query {
          new.urlActionIncoming = .allowing(URL)
        }
        return new
      }
      .withLatestFrom(events) { model, app in
        var edit = app
        edit.application = model
        return edit
      }
    }
    let delegate = CycledApplicationDelegate(
      filter: cycle
    ) as UIApplicationDelegate
    
    delegate.application!(
      UIApplication.shared,
      willFinishLaunchingWithOptions: [:]
    )
    
    XCTAssert(
      delegate.application!(
        UIApplication.shared,
        open: URL(string: "https://www.duckduckgo.com")!,
        sourceApplication: "x",
        annotation: [:]
      )
      ==
      true
    )
  }
  
  func testShouldOpenURLs9() {
    let cycle = RxUIApplicationCycle { events, application -> Observable<RxUIApplicationTestCase.RxUIApplicationCycle.DriverModels> in
      application
      .rendered(events.map { $0.application })
      .map { model -> RxUIApplication.Model in
        var new = model
        if
        case .considering(let query) = model.urlActionIncoming,
        case .ios9(let URL, _) = query {
          new.urlActionIncoming = .allowing(URL)
        }
        return new
      }
      .withLatestFrom(events) { model, app in
        var edit = app
        edit.application = model
        return edit
      }
    }
    let delegate = CycledApplicationDelegate(
      filter: cycle
    ) as UIApplicationDelegate
    
    delegate.application!(
      UIApplication.shared,
      willFinishLaunchingWithOptions: [:]
    )
    
    XCTAssert(
      delegate.application!(
        UIApplication.shared,
        open: URL(string: "https://www.duckduckgo.com")!,
        options: [:]
      )
      ==
      true
    )
  }

  func testSupportedInterfaceOrientations() {
    let cycle = RxUIApplicationCycle { events, application -> Observable<RxUIApplicationTestCase.RxUIApplicationCycle.DriverModels> in
      application
      .rendered(events.map { $0.application })
      .map { model -> RxUIApplication.Model in
        var new = model
        new.interfaceOrientations = model.interfaceOrientations.map {
          switch $0 {
          case .considering(let window):
            return .allowing(
              RxUIApplication.Model.WindowResponse(
                window: window,
                orientation: .portraitUpsideDown
              )
            )
          default:
            return $0
          }
        }
        return new
      }
      .withLatestFrom(events) { model, app in
        var edit = app
        edit.application = model
        return edit
      }
    }
    let delegate = CycledApplicationDelegate(
      filter: cycle
    ) as UIApplicationDelegate
    
    delegate.application!(
      UIApplication.shared,
      willFinishLaunchingWithOptions: [:]
    )
    
    XCTAssert(
      delegate.application!(
        UIApplication.shared,
        supportedInterfaceOrientationsFor: WindowStub(id: "x")
      )
      ==
      .portraitUpsideDown
    )
  }
  
  func testextensionPointIdentifier() {
    let cycle = RxUIApplicationCycle { events, application -> Observable<RxUIApplicationTestCase.RxUIApplicationCycle.DriverModels> in
      application
      .rendered(events.map { $0.application })
      .map { model -> RxUIApplication.Model in
        var new = model
        if case .considering(let ID) = model.extensionPointIdentifier {
          new.extensionPointIdentifier = .allowing(ID)
        }
        return new
      }
      .withLatestFrom(events) { model, app in
        var edit = app
        edit.application = model
        return edit
      }
    }
    let delegate = CycledApplicationDelegate(
      filter: cycle
    ) as UIApplicationDelegate
    
    delegate.application!(
      UIApplication.shared,
      willFinishLaunchingWithOptions: [:]
    )
    
    XCTAssert(
      delegate.application!(
        UIApplication.shared,
        shouldAllowExtensionPointIdentifier: .keyboard
      )
      ==
      true
    )
  }
  
  func testViewControllerWithRestorationIdentifierPathAllowing() {
    let cycle = RxUIApplicationCycle { events, application -> Observable<RxUIApplicationTestCase.RxUIApplicationCycle.DriverModels> in
      application
      .rendered(events.map { $0.application })
      .map { model -> RxUIApplication.Model in
        var new = model
        if case .considering(let query) = new.viewControllerRestoration {
          new.viewControllerRestoration = .allowing(
            RxUIApplication.Model.RestorationResponse(
              identifier: query.identifier,
              view: ViewControllerStub(id: "x")
            )
          )
        }
        return new
      }
      .withLatestFrom(events) { model, app in
        var edit = app
        edit.application = model
        return edit
      }
    }
    let delegate = CycledApplicationDelegate(
      filter: cycle
    ) as UIApplicationDelegate
    
    delegate.application!(
      UIApplication.shared,
      willFinishLaunchingWithOptions: [:]
    )
    
    XCTAssert(
      delegate.application!(
        UIApplication.shared,
        viewControllerWithRestorationIdentifierPath: ["y"],
        coder: CoderStub(id: "z")
      )
      ==
      ViewControllerStub(id: "x")
    )
  }
  
  func testShouldSaveApplicationStateAllowing() {
    let cycle = RxUIApplicationCycle { events, application -> Observable<RxUIApplicationTestCase.RxUIApplicationCycle.DriverModels> in
      application
      .rendered(events.map { $0.application })
      .map { model -> RxUIApplication.Model in
        var new = model
        if case .considering(_) = model.shouldSaveApplicationState {
          new.shouldSaveApplicationState = .allowing(true)
        }
        return new
      }
      .withLatestFrom(events) { model, app in
        var edit = app
        edit.application = model
        return edit
      }
    }
    let delegate = CycledApplicationDelegate(
      filter: cycle
    ) as UIApplicationDelegate
    
    delegate.application!(
      UIApplication.shared,
      willFinishLaunchingWithOptions: [:]
    )
    
    XCTAssert(
      delegate.application!(
        UIApplication.shared,
        shouldSaveApplicationState: CoderStub(id: "x")
      )
      ==
      true
    )
  }
  
  func testShouldRestoreApplicationStateAllowing() {
    let cycle = RxUIApplicationCycle { events, application -> Observable<RxUIApplicationTestCase.RxUIApplicationCycle.DriverModels> in
      application
      .rendered(events.map { $0.application })
      .map { model -> RxUIApplication.Model in
        var new = model
        if case .considering(_) = model.shouldRestoreApplicationState {
          new.shouldRestoreApplicationState = .allowing(true)
        }
        return new
      }
      .withLatestFrom(events) { model, app in
        var edit = app
        edit.application = model
        return edit
      }
    }
    let delegate = CycledApplicationDelegate(
      filter: cycle
    ) as UIApplicationDelegate
    
    delegate.application!(
      UIApplication.shared,
      willFinishLaunchingWithOptions: [:]
    )
    
    XCTAssert(
      delegate.application!(
        UIApplication.shared,
        shouldRestoreApplicationState: CoderStub(id: "x")
      )
      ==
      true
    )
  }
  
  func testShouldNotifyUserActivitiesWithTypes() {
    let cycle = RxUIApplicationCycle { events, application -> Observable<RxUIApplicationTestCase.RxUIApplicationCycle.DriverModels> in
      application
      .rendered(events.map { $0.application })
      .map { model -> RxUIApplication.Model in
        var new = model
        if case .willContinue(let type) = model.userActivityState {
          new.userActivityState = .shouldNotifyUserActivitiesWithType(type)
        }
        return new
      }
      .withLatestFrom(events) { model, app in
        var edit = app
        edit.application = model
        return edit
      }
    }
    let delegate = CycledApplicationDelegate(
      filter: cycle
    ) as UIApplicationDelegate
    
    delegate.application!(
      UIApplication.shared,
      willFinishLaunchingWithOptions: [:]
    )
    
    XCTAssert(
      delegate.application!(
        UIApplication.shared,
        willContinueUserActivityWithType: "x"
      )
      ==
      true
    )
  }
  
  func testActivitiesWithAvaliableData() {
    let cycle = RxUIApplicationCycle { events, application -> Observable<RxUIApplicationTestCase.RxUIApplicationCycle.DriverModels> in
      application
      .rendered(events.map { $0.application })
      .map { model -> RxUIApplication.Model in
        var new = model
        if case .isContinuing(let activity) = model.userActivityState {
          new.userActivityState = .hasAvailableData(activity.0)
        }
        return new
      }
      .withLatestFrom(events) { model, app in
        var edit = app
        edit.application = model
        return edit
      }
    }
    let delegate = CycledApplicationDelegate(
      filter: cycle
    ) as UIApplicationDelegate
    
    delegate.application!(
      UIApplication.shared,
      willFinishLaunchingWithOptions: [:]
    )
    
    XCTAssert(
      delegate.application!(
        UIApplication.shared,
        continue: NSUserActivity(activityType: "x"),
        restorationHandler: { _ in }
      )
      ==
      true
    )
  }
  
  func testMomentaryState() {
    var x = RxUIApplication.Model.empty
    x.isExperiencingHealthAuthorizationRequest = true

    XCTAssertEqual(
      RxUIApplicationTestCase.statesFrom(stream: .just(x))
        .map { $0.isExperiencingHealthAuthorizationRequest }
      ,
      [false]
    )
  }
  
  func testRenderingIsIgnoringUserEvents() {

    let x = RxUIApplication.Model.empty
    var y = x; y.isIgnoringUserEvents = true
    var z = y; z.isIgnoringUserEvents = false
    
    XCTAssert(
      RxUIApplicationTestCase.statesFrom(stream: Observable.of(x, y, x))
      .map { $0.isIgnoringUserEvents }
      ==
      [
        false,
        true,
        false
      ]
    )
  }
  
  func testRenderingIsIdleTimerDisabled() {
    
    let x = RxUIApplication.Model.empty
    var y = x; y.isIdleTimerDisabled = true
    var z = y; z.isIdleTimerDisabled = false
    
    XCTAssert(
      RxUIApplicationTestCase.statesFrom(stream: Observable.of(x, y, x))
      .map { $0.isIdleTimerDisabled }
      ==
      [
        false,
        true,
        false
      ]
    )
  }

  func testRenderingURLActionOutgoingOpening() {
    var x = RxUIApplication.Model.empty
    x.urlActionOutgoing = .attempting(URL(string: "https://www.duckduckgo.com")!)
    XCTAssertEqual(
      RxUIApplicationTestCase.statesFrom(stream: .just(x))
        .map { $0.urlActionOutgoing }
      ,
      [.opening(URL(string: "https://www.duckduckgo.com")!)]
    )
  }
  
  func testRenderingURLActionOutgoingIdle() {
    var x = RxUIApplication.Model.empty
    x.urlActionOutgoing = .opening(URL(string: "https://www.duckduckgo.com")!)
    XCTAssertEqual(
      RxUIApplicationTestCase.statesFrom(stream: .just(x))
        .map { $0.urlActionOutgoing }
      ,
      [.idle]
    )
  }
  
  func testRenderingSendActionSending() {
    let action = RxUIApplication.Model.TargetAction(
      action: #selector(getter: UIApplication.isIdleTimerDisabled),
      target: UIApplication.shared,
      sender: nil,
      event: nil
    )
    var x = RxUIApplication.Model.empty
    x.targetAction = .sending(action)
    XCTAssertEqual(
      RxUIApplicationTestCase.statesFrom(stream: .just(x))
        .map { $0.targetAction }
      ,
      [.responding(action, true)]
    )
  }
  
  func testRenderingSendActionIdle() {
    let action = RxUIApplication.Model.TargetAction(
      action: #selector(getter: UIApplication.isIdleTimerDisabled),
      target: UIApplication.shared,
      sender: nil,
      event: nil
    )
    var x = RxUIApplication.Model.empty
    x.targetAction = .responding(action, true)
    XCTAssertEqual(
      RxUIApplicationTestCase.statesFrom(stream: .just(x))
        .map { $0.targetAction }
      ,
      [.idle]
    )
  }
  
  func testRenderingBackgroundTasksProgressing() {
    var y = RxUIApplication.Model.empty
    y.backgroundTasks = [
      RxUIApplication.Model.BackgroundTask(
        name: "x",
        state: .pending
      )
    ]
    XCTAssert(
      RxUIApplicationTestCase.statesFrom(stream: .just(y))
      .map { $0.backgroundTasks }
      .flatMap { $0 }
      // This test will occasionally fail due to harcoded UIBackgroundTaskIdentifier.
      // Needs better solution
      ==
      [
        RxUIApplication.Model.BackgroundTask(
          name: "x",
          state: .progressing(1)
        )
      ]
    )
  }
  
  func testRenderingBackgroundTasksComplete() {
    var y = RxUIApplication.Model.empty
    y.backgroundTasks = [
      RxUIApplication.Model.BackgroundTask(
        name: "x",
        state: .complete(1)
      )
    ]
    XCTAssertEqual(
      RxUIApplicationTestCase.statesFrom(stream: .just(y))
      .map { $0.backgroundTasks }
      .flatMap { $0 }
      ,
      []
    )
  }
  
  func testRenderingBackgroundFetchProgressCallback() {
    XCTAssertEqual(
      RxUIApplicationTestCase.statesFromCall(call: {
        $0.application(
          UIApplication.shared,
          performFetchWithCompletionHandler: { _ in }
        )
      })
      .map { $0.backgroundFetch }
      ,
      [
        RxUIApplication.Model.BackgroundFetch(
          minimumInterval: .never,
          state: .idle
        ),
        RxUIApplication.Model.BackgroundFetch(
          minimumInterval: .never,
          state: .progressing({ _ in})
        )
      ]
    )
  }
  
  func testRenderingBackgroundFetchComplete() {
    var x = RxUIApplication.Model.empty
    x.backgroundFetch = RxUIApplication.Model.BackgroundFetch(
      minimumInterval: .never,
      state: .complete(.noData, { _ in})
    )
    XCTAssertEqual(
      RxUIApplicationTestCase.statesFrom(stream: .just(x))
      .map { $0.backgroundFetch }
      ,
      [
        RxUIApplication.Model.BackgroundFetch(
          minimumInterval: .never,
          state: .idle
        )
      ]
    )
  }
  
  func testRenderingBackgroundURLSessionActionProgressing() {
    XCTAssertEqual(
      RxUIApplicationTestCase.statesFromCall {
        $0.application(
          UIApplication.shared,
          handleEventsForBackgroundURLSession: "id",
          completionHandler: {}
        )
      }
      .map { $0.backgroundURLSessions }
      .flatMap { $0 }
      ,
      [
        RxUIApplication.Model.BackgroundURLSessionAction(
          id: "id",
          completion: {},
          state: .progressing
        )
      ]
    )
  }
  
  func testRenderingBackgroundURLSessionActionComplete() {
    var x = RxUIApplication.Model.empty
    x.backgroundURLSessions = Set([
      RxUIApplication.Model.BackgroundURLSessionAction(
        id: "id",
        completion: {},
        state: .complete
      )
    ])
    XCTAssertEqual(
      RxUIApplicationTestCase.statesFrom(stream: .just(x))
        .map { $0.backgroundURLSessions }
        .flatMap { $0 }
      ,
      []
    )
  }
  
  func testDictionaryConcatenation() {
    XCTAssert(
      [WindowStub(id: "x"): UIInterfaceOrientationMask.allButUpsideDown] +
      [WindowStub(id: "y"): UIInterfaceOrientationMask.allButUpsideDown]
      ==
      [WindowStub(id: "y"): UIInterfaceOrientationMask.allButUpsideDown,
      WindowStub(id: "x"): UIInterfaceOrientationMask.allButUpsideDown]
    )
  }
  
  func testDictionaryMerging() {
    let same = WindowStub(id: "x")
    XCTAssert(
      [same: UIInterfaceOrientationMask.allButUpsideDown] +
      [same: UIInterfaceOrientationMask.allButUpsideDown]
      ==
      [same: UIInterfaceOrientationMask.allButUpsideDown]
    )
  }
  
  func testDictionaryMergeOverwrite() {
    let same = WindowStub(id: "x")
    XCTAssert(
      [same: UIInterfaceOrientationMask.allButUpsideDown] +
      [same: UIInterfaceOrientationMask.portraitUpsideDown]
      ==
      [same: UIInterfaceOrientationMask.allButUpsideDown]
    )
  }
  
  func testAdditions() {
    let x = ["x"]
    let y: [String] = []
    let z = RxUIApplication.additions(new: x, old: y)
    XCTAssert(z.count == 1)
  }
  
  func testDeletions() {
    let x = ["x"]
    let y: [String] = []
    let z = RxUIApplication.deletions(old: x, new: y)
    XCTAssert(z.count == 1)
  }
  
  func testCompletedBackgroundIDs() {
    let x = [RxUIApplication.Model.BackgroundTask(name: "x", state: .complete(2017))]
    let z = x.flatMap { $0.ID }
    XCTAssert(z == [2017])
  }
  
  func testDeletedBackgroundTaskIDs() {
    let x = [RxUIApplication.Model.BackgroundTask(name: "x", state: .progressing(2017))]
    let y: [RxUIApplication.Model.BackgroundTask] = []
    let z = RxUIApplication.deletions(old: x, new: y).flatMap { $0.ID }
    XCTAssert(z == [2017])
  }

  struct ErrorStub: Error, Equatable {
    let id: String
    static func ==(left: ErrorStub, right: ErrorStub) -> Bool {
      return left.id == right.id
    }
  }
  
  class CoderStub: NSCoder {
    let id: String
    init(id: String) {
      self.id = id
      super.init()
    }
    override func isEqual(_ object: Any?) -> Bool {
      if let other = object as? CoderStub { return
        other.id == id
      } else { return
        false
      }
    }
  }
  
  class UIUserNotificationSettingsStub: UIUserNotificationSettings {
    let id: String
    init(id: String) {
      self.id = id
      super.init()
    }
    override func isEqual(_ object: Any?) -> Bool {
      if let other = object as? UIUserNotificationSettingsStub { return
        other.id == id
      } else { return
        false
      }
    }
  }
  
  class WindowStub: UIWindow {
    let id: String
    init(id: String) {
      self.id = id
      super.init(frame: .zero)
    }
    required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
    override func isEqual(_ object: Any?) -> Bool {
      if let other = object as? WindowStub { return
        other.id == id
      } else { return
        false
      }
    }
    override var hashValue: Int {
      return id.hashValue
    }
    override var debugDescription: String {
      return id
    }
  }
  
  class RxUIApplicationCycle: SinkSourceConverting {
    struct Drivers: CycleDrivable {
      var application: RxUIApplication!
    }
    struct DriverModels: Initializable {
      var application = RxUIApplication.Model.empty
    }
    let filter: (Observable<DriverModels>, RxUIApplication) -> Observable<DriverModels>
    init(filter: @escaping (Observable<DriverModels>, RxUIApplication) -> Observable<DriverModels>) {
      self.filter = filter
    }
    func effectsFrom(events: Observable<DriverModels>, drivers: Drivers) -> Observable<DriverModels> { return
      filter(events, drivers.application)
    }
  }
  
  class ViewControllerStub: UIViewController {
    let id: String
    init(id: String) {
      self.id = id
      super.init(nibName: "", bundle: nil)
    }
    required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
    override func isEqual(_ object: Any?) -> Bool {
      if let other = object as? ViewControllerStub {
        return other.id == id
      } else {
        return false
      }
    }
  }
}

extension RxUIApplication.Model {
  func with(shortcutItem: RxUIApplication.Model.ShortcutAction) -> RxUIApplication.Model {
    var edit = self
    edit.shortcutActions += [shortcutItem]
    return edit
  }
}

func ==<T: Equatable>(left: [T?], right: [T?]) -> Bool { return
  left.count == right.count &&
  zip(left, right).first { $0 != $1 } == nil
}

extension UIApplicationShortcutItem {
  static var stub: UIApplicationShortcutItem { return
    UIApplicationShortcutItem(
      type: "x",
      localizedTitle: "y"
    )
  }
}
