//
//  Session.swift
//  Cycle
//
//  Created by Brian Semiglia on 1/27/17.
//  Copyright © 2017 Brian Semiglia. All rights reserved.
//

import XCTest
import RxSwift

class SessionTestCase: XCTestCase {
  
  static func statesFromEvents(call: (Session) -> Any) -> [Session.Model] {
    var output: [Session.Model] = []
    let session = Session(
      .empty
    )
    _ = session
      .rendered(Observable<Session.Model>.just(.empty))
      .subscribe {
        if let new = $0.element {
          output += [new]
        }
      }
    _ = call(session)
    return output
  }
  
  func testConversionCallbacks() {
    
    XCTAssertEqual(
      SessionTestCase.statesFromEvents {
        $0.applicationWillTerminate(UIApplication.shared)
        }.map { $0.state },
      [.none(.awaitingLaunch), .will(.terminated)]
    )

    XCTAssertEqual(
      SessionTestCase.statesFromEvents {
        $0.applicationDidBecomeActive(UIApplication.shared)
      }.map { $0.state },
      [.none(.awaitingLaunch), .did(.active)]
    )

    XCTAssertEqual(
      SessionTestCase.statesFromEvents {
        $0.applicationWillResignActive(UIApplication.shared)
      }.map { $0.state },
      [.none(.awaitingLaunch), .will(.resigned)]
    )

    XCTAssertEqual(
      SessionTestCase.statesFromEvents {
        $0.applicationDidEnterBackground(UIApplication.shared)
      }.map { $0.state },
      [.none(.awaitingLaunch), .did(.resigned)]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesFromEvents {
        $0.application(
          UIApplication.shared,
          willFinishLaunchingWithOptions: nil
        )
      }.map { $0.state },
      [.none(.awaitingLaunch), .will(.launched(nil))]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesFromEvents {
        $0.application(
          UIApplication.shared,
          didFinishLaunchingWithOptions: nil
        )
      }.map { $0.state },
      [.none(.awaitingLaunch), .did(.launched(nil))]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesFromEvents {
        $0.applicationWillEnterForeground(UIApplication.shared)
      }.map { $0.state },
      [.none(.awaitingLaunch), .will(.active)]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesFromEvents {
        $0.applicationSignificantTimeChange(UIApplication.shared)
      }.map { $0.isObservingSignificantTimeChange },
      [false, true, false]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesFromEvents {
        $0.applicationDidReceiveMemoryWarning(UIApplication.shared)
      }.map { $0.isExperiencingMemoryWarning },
      [false, true, false]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesFromEvents {
        $0.applicationShouldRequestHealthAuthorization(UIApplication.shared)
      }.map { $0.isExperiencingHealthAuthorizationRequest },
      [false, true, false]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesFromEvents {
        $0.applicationProtectedDataDidBecomeAvailable(UIApplication.shared)
      }.map { $0.isProtectedDataAvailable },
      [.none(false), .did(true)]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesFromEvents {
        $0.applicationProtectedDataWillBecomeUnavailable(UIApplication.shared)
      }.map { $0.isProtectedDataAvailable },
      [.none(false), .will(false)]
    )
    
//    XCTAssertEqual(
//      SessionTestCase.statesForEvents {
//        $0.application(
//          UIApplication.shared,
//          didRegister: UIUserNotificationSettingsStub(id: "x")
//        )
//      }.map { $0.registeredUserNotificationSettings as? UIUserNotificationSettingsStub },
//      [
//        Optional<UIUserNotificationSettingsStub>.none,
//        UIUserNotificationSettingsStub(id: "x")
//      ]
//    )
    
//    XCTAssertEqual(
//      SessionTestCase.statesForEvents {
//        $0.application(
//          UIApplication.shared,
//          didFailToRegisterForRemoteNotificationsWithError: ErrorStub(id: "")
//        )
//      }.flatMap { $0.deviceToken as? Result.error(ErrorStub(id: "") },
//      [.none, .error(ErrorStub(id: "")]
//    )
    
    XCTAssertEqual(
      SessionTestCase.statesFromEvents {
        $0.application(
          UIApplication.shared,
          didRegisterForRemoteNotificationsWithDeviceToken: Data()
        )
      }.map { $0.deviceToken },
      [.none, .some(Data())]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesFromEvents {
        $0.application(
          UIApplication.shared,
          didDecodeRestorableStateWith: CoderStub(id: "")
        )
      }.map { $0.stateRestoration },
      [.idle, .didDecode(CoderStub(id: ""))]
    )

    XCTAssertEqual(
      SessionTestCase.statesFromEvents {
        $0.application(
          UIApplication.shared,
          willEncodeRestorableStateWith: CoderStub(id: "")
        )
      }.map { $0.stateRestoration },
      [.idle, .willEncode(CoderStub(id: ""))]
    )

    XCTAssertEqual(
      SessionTestCase.statesFromEvents {
        $0.application(
          UIApplication.shared,
          shouldSaveApplicationState: CoderStub(id: "")
        )
      }.map { $0.shouldSaveApplicationState },
      [.allowing(true), .considering(CoderStub(id: "") as NSCoder)]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesFromEvents {
        $0.application(
          UIApplication.shared,
          shouldRestoreApplicationState: CoderStub(id: "")
        )
      }.map { $0.shouldRestoreApplicationState },
      [.allowing(true), .considering(CoderStub(id: "") as NSCoder)]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesFromEvents {
        $0.application(
          UIApplication.shared,
          willContinueUserActivityWithType: ""
        )
      }.map { $0.userActivityState },
      [.idle, .willContinue("")]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesFromEvents {
        $0.application(
          UIApplication.shared,
          didFailToContinueUserActivityWithType: "",
          error: ErrorStub(id: "")
        )
      }.map { $0.userActivityState },
      [.idle, .didFail("", ErrorStub(id: ""))]
    )
    
    let activity = NSUserActivity(activityType: "x")
    XCTAssertEqual(
      SessionTestCase.statesFromEvents {
        $0.application(
          UIApplication.shared,
          didUpdate: activity
        )
      }.map { $0.userActivityState },
      [.idle, .didContinue(activity)]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesFromEvents {
        $0.application(
          UIApplication.shared,
          continue: activity,
          restorationHandler: { _ in }
        )
      }.map { $0.userActivityState },
      [.idle, .isContinuing(activity)]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesFromEvents {
        $0.applicationWillResignActive(UIApplication.shared)
        }.map { $0.state },
      [.none(.awaitingLaunch), .will(.resigned)]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesFromEvents {
        $0.application(
          UIApplication.shared,
          willChangeStatusBarOrientation: .landscapeLeft,
          duration: 0.0
        )
      }.map { $0.statusBarOrientation },
      [.none(.unknown), .will(.landscapeLeft)]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesFromEvents {
        $0.application(
          UIApplication.shared,
          didChangeStatusBarOrientation: .landscapeLeft
        )
      }.map { $0.statusBarOrientation },
      [.none(.unknown), .did(.landscapeLeft)]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesFromEvents {
        $0.application(
          UIApplication.shared,
          willChangeStatusBarFrame: CGRect(x: 1, y: 2, width: 3, height: 4)
        )
      }.map { $0.statusBarFrame },
      [.none(.zero), .will(CGRect(x: 1, y: 2, width: 3, height: 4))]
    )

    // Consider adding beginState to -willChange enum option .will(from: to:)
    // Or firing changes for every frame of animation
    
    XCTAssertEqual(
      SessionTestCase.statesFromEvents {
        $0.application(
          UIApplication.shared,
          didChangeStatusBarFrame: CGRect(x: 1, y: 2, width: 3, height: 4)
        )
      }.map { $0.statusBarFrame },
      [.none(.zero), .did(CGRect(x: 0, y: 0, width: 320, height: 20))]
    )

    XCTAssertEqual(
      SessionTestCase.statesFromEvents {
        $0.application(
          UIApplication.shared,
          handleActionWithIdentifier: "x",
          for: UILocalNotification(),
          completionHandler: {}
        )
      }.map { $0.localAction },
      [.idle,
       .progressing(.ios8(.some( "x"), UILocalNotification(), {}))
      ]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesFromEvents {
        $0.application(
          UIApplication.shared,
          handleActionWithIdentifier: "x",
          forRemoteNotification: ["":""],
          withResponseInfo: ["":""],
          completionHandler: {}
        )
      }.map { $0.remoteAction },
      [
        .idle,
        .progressing(
          .ios9(
            id: .some( "x"),
            userInfo: ["":""],
            responseInfo: ["":""],
            completion: {}
          )
        )
      ]
    )

    XCTAssertEqual(
      SessionTestCase.statesFromEvents {
        $0.application(
          UIApplication.shared,
          handleActionWithIdentifier: "x",
          forRemoteNotification: ["":""],
          completionHandler: {}
        )
      }.map { $0.remoteAction },
      [
        .idle,
        .progressing(
          .ios8(
            id: .some( "x"),
            userInfo: ["":""],
            completion: {}
          )
        )
      ]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesFromEvents {
        $0.application(
          UIApplication.shared,
          handleActionWithIdentifier: "x",
          for: UILocalNotification(),
          withResponseInfo: ["":""],
          completionHandler: {}
        )
      }.map { $0.localAction },
      [
        .idle,
        .progressing(
          .ios9(
            .some( "x"),
            UILocalNotification(),
            ["":""],
            {}
          )
        )
      ]
    )

    XCTAssertEqual(
      SessionTestCase.statesFromEvents {
        $0.application(
          UIApplication.shared,
          performActionFor: UIApplicationShortcutItem(type: "", localizedTitle: ""),
          completionHandler: { _ in }
        )
      }.map { $0.shortcutItemAction },
      [
        .idle,
        .progressing(
          Session.Model.ShortcutAction(
            item: UIApplicationShortcutItem(type: "", localizedTitle: ""),
            completion: { _ in }
          )
        )
      ]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesFromEvents {
        $0.application(
          UIApplication.shared,
          handleEventsForBackgroundURLSession: "x",
          completionHandler: {}
        )
      }.map { $0.backgroundURLSessionAction },
      [
        .idle,
        .progressing(
          Session.Model.BackgroundURLSessionAction(
            identifier: "x",
            completion: {}
          )
        )
      ]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesFromEvents {
        $0.application(
          UIApplication.shared,
          didReceiveRemoteNotification: ["":""],
          fetchCompletionHandler: { _ in }
        )
      }.map { $0.remoteNotification },
      [
        .idle,
        .progressing(
          Session.Model.RemoteNofiticationAction(
            notification: ["":""],
            completion: { _ in }
          )
        )
      ]
    )
    
//    XCTAssertEqual(
//      SessionTestCase.statesForEvents {
//        $0.application(
//          UIApplication.shared,
//          performFetchWithCompletionHandler: { _ in }
//        )
//      }.map { $0.fetch },
//      [
//        .idle,
//        .progressing(
//          Session.Model.FetchAction(
//            hash: Date().hashValue, // Needs fix. Returning false negative
//            completion: { _ in }
//          )
//        )
//      ]
//    )
    
    XCTAssertEqual(
      SessionTestCase.statesFromEvents {
        $0.application(
          UIApplication.shared,
          handleWatchKitExtensionRequest: ["":""],
          reply: { _ in }
        )
      }.map { $0.watchKitExtensionRequest },
      [
        .idle,
        .progressing(
          Session.Model.WatchKitExtensionRequest(
            userInfo: ["":""],
            reply: { _ in }
          )
        )
      ]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesFromEvents {
        $0.application(
          UIApplication.shared,
          shouldAllowExtensionPointIdentifier: .keyboard
        )
      }.map { $0.extensionPointIdentifiers }.flatMap { $0 },
      [.considering(.keyboard)]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesFromEvents {
        $0.application(
          UIApplication.shared,
          supportedInterfaceOrientationsFor: WindowStub(id: "x")
        )
      }.map { $0.interfaceOrientations }.flatMap { $0 },
      [.considering(WindowStub(id: "x") as UIWindow)]
    )

    XCTAssertEqual(
      SessionTestCase.statesFromEvents {
        let x = $0.application(
          UIApplication.shared,
          viewControllerWithRestorationIdentifierPath: ["x"],
          coder: CoderStub(id: "y")
        )
        return x ?? {}
      }.map { $0.restorationViewControllers }.flatMap { $0 },
      [
        .considering(
          Session.Model.RestorationQuery(
            identifier: "x",
            coder: CoderStub(id: "y") as NSCoder
          )
        )
      ]
    )

  }
  
  func testWillFinishLaunching() {
    let session = Session(.empty)
    let cycle = SessionCycle { events -> Observable<SessionTestCase.SessionCycle.DriverModels> in
      session
      .rendered(events.map { $0.session })
      .map { model -> Session.Model in
        switch model.state {
        case .will(let a):
          switch a {
          case .launched(let _):
            var new = model
            new.shouldLaunch = true
            return new
          default:
            return model
          }
        default:
          return model
        }
      }
      .withLatestFrom(events) { ($0.0, $0.1) }
      .map { model, app in
        var edit = app
        edit.session = model
        return edit
      }
    }
    let delegate = CycledApplicationDelegate(
      filter: cycle,
      session: session
    ) as UIApplicationDelegate
    XCTAssert(
      delegate.application!(
        UIApplication.shared,
        willFinishLaunchingWithOptions: [:]
      )
    )
  }
  
  func testShouldOpenURLs4() {
    let session = Session(.empty)
    let cycle = SessionCycle { events -> Observable<SessionTestCase.SessionCycle.DriverModels> in
      session
      .rendered(events.map { $0.session })
      .map { model -> Session.Model in
        var new = model
        new.shouldLaunch = true
        if case .considering(let query) = model.URL {
          switch query {
          case .ios4(let URL, let app, let annotation):
            new.URL = .allowing(URL)
          default: break
          }
        }
        return new
      }
      .withLatestFrom(events) { ($0.0, $0.1) }
      .map { model, app in
        var edit = app
        edit.session = model
        return edit
      }
    }
    let delegate = CycledApplicationDelegate(
      filter: cycle,
      session: session
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
    let session = Session(.empty)
    let cycle = SessionCycle { events -> Observable<SessionTestCase.SessionCycle.DriverModels> in
      session
      .rendered(events.map { $0.session })
      .map { model -> Session.Model in
        var new = model
        new.shouldLaunch = true
        if case .considering(let query) = model.URL {
          switch query {
          case .ios9(let URL, let options):
            new.URL = .allowing(URL)
          default: break
          }
        }
        return new
      }
      .withLatestFrom(events) { ($0.0, $0.1) }
      .map { model, app in
        var edit = app
        edit.session = model
        return edit
      }
    }
    let delegate = CycledApplicationDelegate(
      filter: cycle,
      session: session
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
    let session = Session(.empty)
    let cycle = SessionCycle { events -> Observable<SessionTestCase.SessionCycle.DriverModels> in
      session
      .rendered(events.map { $0.session })
      .map { model -> Session.Model in
        var new = model
        new.shouldLaunch = true
        new.interfaceOrientations = model.interfaceOrientations
        .map {
          switch $0 {
          case .considering(let window):
            return .allowing(
              Session.Model.WindowResponse(
                window: window,
                orientation: .portraitUpsideDown
              )
            )
          default: return $0
          }
        }
        return new
      }
      .withLatestFrom(events) { ($0.0, $0.1) }
      .map { model, app in
        var edit = app
        edit.session = model
        return edit
      }
    }
    let delegate = CycledApplicationDelegate(
      filter: cycle,
      session: session
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
  
  func testExtensionPointIdentifiers() {
    let session = Session(.empty)
    let cycle = SessionCycle { events -> Observable<SessionTestCase.SessionCycle.DriverModels> in
      session
      .rendered(events.map { $0.session })
      .map { model -> Session.Model in
        var new = model
        new.shouldLaunch = true
        new.extensionPointIdentifiers = model.extensionPointIdentifiers.map {
          switch $0 {
          case .considering(let ID):
            return .allowing(ID)
          default: return $0
          }
        }
        return new
      }
      .withLatestFrom(events) { ($0.0, $0.1) }
      .map { model, app in
        var edit = app
        edit.session = model
        return edit
      }
    }
    let delegate = CycledApplicationDelegate(
      filter: cycle,
      session: session
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
  
  func testViewControllerWithRestorationIdentifierPath() {
    let session = Session(.empty)
    let cycle = SessionCycle { events -> Observable<SessionTestCase.SessionCycle.DriverModels> in
      session
        .rendered(events.map { $0.session })
        .map { model -> Session.Model in
          var new = model
          new.shouldLaunch = true
          new.restorationViewControllers = new.restorationViewControllers.map {
            switch $0 {
            case .considering(let query):
              return .allowing(
                Session.Model.RestorationResponse(
                  identifier: query.identifier,
                  view: ViewControllerStub(id: "x")
                )
              )
            default: return $0
            }
          }
          return new
        }
        .withLatestFrom(events) { ($0.0, $0.1) }
        .map { model, app in
          var edit = app
          edit.session = model
          return edit
      }
    }
    let delegate = CycledApplicationDelegate(
      filter: cycle,
      session: session
      ) as UIApplicationDelegate
    
    delegate.application!(
      UIApplication.shared,
      willFinishLaunchingWithOptions: [:]
    )
    
    XCTAssert(
      delegate.application!(
        UIApplication.shared,
        viewControllerWithRestorationIdentifierPath: ["y"],
        coder: CoderStub(id: "")
      )
      ==
      ViewControllerStub(id: "x")
    )
  }
  
  func testShouldSaveApplicationState() {
    let session = Session(.empty)
    let cycle = SessionCycle { events -> Observable<SessionTestCase.SessionCycle.DriverModels> in
      session
      .rendered(events.map { $0.session })
      .map { model -> Session.Model in
        var new = model
        new.shouldLaunch = true
        switch model.shouldSaveApplicationState {
        case .considering(let coder):
          new.shouldSaveApplicationState = .allowing(true)
        default:
          break
        }
        return new
      }
      .withLatestFrom(events) { ($0.0, $0.1) }
      .map { model, app in
        var edit = app
        edit.session = model
        return edit
      }
    }
    let delegate = CycledApplicationDelegate(
      filter: cycle,
      session: session
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
  
  func testShouldRestoreApplicationState() {
    let session = Session(.empty)
    let cycle = SessionCycle { events -> Observable<SessionTestCase.SessionCycle.DriverModels> in
      session
        .rendered(events.map { $0.session })
        .map { model -> Session.Model in
          var new = model
          new.shouldLaunch = true
          switch model.shouldRestoreApplicationState {
          case .considering(let coder):
            new.shouldRestoreApplicationState = .allowing(true)
          default:
            break
          }
          return new
        }
        .withLatestFrom(events) { ($0.0, $0.1) }
        .map { model, app in
          var edit = app
          edit.session = model
          return edit
      }
    }
    let delegate = CycledApplicationDelegate(
      filter: cycle,
      session: session
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
    let session = Session(.empty)
    let cycle = SessionCycle { events -> Observable<SessionTestCase.SessionCycle.DriverModels> in
      session
      .rendered(events.map { $0.session })
      .map { model -> Session.Model in
        var new = model
        new.shouldLaunch = true
        switch model.userActivityState {
        case .willContinue(let type):
          new.shouldNotifyUserActivitiesWithTypes += [type]
        default:
          break
        }
        return new
      }
      .withLatestFrom(events) { ($0.0, $0.1) }
      .map { model, app in
        var edit = app
        edit.session = model
        return edit
      }
    }
    let delegate = CycledApplicationDelegate(
      filter: cycle,
      session: session
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
    let session = Session(.empty)
    let cycle = SessionCycle { events -> Observable<SessionTestCase.SessionCycle.DriverModels> in
      session
      .rendered(events.map { $0.session })
      .map { model -> Session.Model in
        var new = model
        new.shouldLaunch = true
        switch model.userActivityState {
          case .isContinuing(let activity):
          new.activitiesWithAvaliableData += [activity]
        default:
          break
        }
        return new
      }
      .withLatestFrom(events) { ($0.0, $0.1) }
      .map { model, app in
        var edit = app
        edit.session = model
        return edit
      }
    }
    let delegate = CycledApplicationDelegate(
      filter: cycle,
      session: session
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
  
  class SessionCycle: SinkSourceConverting {
    struct DriverModels {
      var session: Session.Model
    }
    let filter: (Observable<DriverModels>) -> Observable<DriverModels>
    init(filter: @escaping (Observable<DriverModels>) -> Observable<DriverModels>) {
      self.filter = filter
    }
    func effectsFrom(events: Observable<DriverModels>) -> Observable<DriverModels> {
      return filter(events)
    }
    func start() -> DriverModels { return
      DriverModels(
        session: Session.Model.empty
      )
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
