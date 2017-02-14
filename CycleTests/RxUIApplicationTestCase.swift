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
  
  static func statesFrom(model: Session.Model = .empty, call: (Session) -> Any) -> [Session.Model] {
    var output: [Session.Model] = []
    let session = Session(intitial: model, application: UIApplication.shared)
    _ = session
      .rendered(Observable<Session.Model>.just(model))
      .subscribe {
        if let new = $0.element {
          output += [new]
        }
      }
    _ = call(session)
    return output
  }
  
  static func statesFromStream(stream: Observable<Session.Model>) -> [Session.Model] {
    var output: [Session.Model] = []
    let session = Session(intitial: .empty, application: UIApplication.shared)
    _ = session
      .rendered(stream)
      .subscribe {
        if let new = $0.element {
          output += [new]
        }
    }
    return output
  }
  
  func testConversionCallbacks() {
    
    XCTAssert(
      SessionTestCase
      .statesFrom { $0.applicationWillTerminate(UIApplication.shared) }
      .map { $0.state }
      ==
      [.none(.awaitingLaunch), .will(.terminated)]
    )

    XCTAssert(
      SessionTestCase
      .statesFrom { $0.applicationDidBecomeActive(UIApplication.shared) }
      .map { $0.state }
      ==
      [.none(.awaitingLaunch), .did(.active), .none(.active)]
    )

    XCTAssert(
      SessionTestCase
      .statesFrom { $0.applicationWillResignActive(UIApplication.shared) }
      .map { $0.state }
      ==
      [.none(.awaitingLaunch), .will(.resigned)]
    )

    XCTAssert(
      SessionTestCase
      .statesFrom { $0.applicationDidEnterBackground(UIApplication.shared) }
      .map { $0.state }
      ==
      [.none(.awaitingLaunch), .did(.resigned), .none(.resigned)]
    )
    
    XCTAssert(
      SessionTestCase
      .statesFrom {
        $0.application(
          UIApplication.shared,
          willFinishLaunchingWithOptions: nil
        )
      }
      .map { $0.state }
      ==
      [.none(.awaitingLaunch), .will(.launched(nil))]
    )
    
    XCTAssert(
      SessionTestCase
      .statesFrom {
        $0.application(
          UIApplication.shared,
          didFinishLaunchingWithOptions: nil
        )
      }
      .map { $0.state }
      ==
      [.none(.awaitingLaunch), .did(.launched(nil)), .none(.launched(nil))]
    )
    
    XCTAssert(
      SessionTestCase
      .statesFrom { $0.applicationWillEnterForeground(UIApplication.shared) }
      .map { $0.state }
      ==
      [.none(.awaitingLaunch), .will(.active)]
    )
    
    XCTAssert(
      SessionTestCase
      .statesFrom { $0.applicationSignificantTimeChange(UIApplication.shared) }
      .map { $0.isObservingSignificantTimeChange }
      ==
      [false, true, false]
    )
    
    XCTAssert(
      SessionTestCase
      .statesFrom { $0.applicationDidReceiveMemoryWarning(UIApplication.shared) }
      .map { $0.isExperiencingMemoryWarning }
      ==
      [false, true, false]
    )
    
    XCTAssert(
      SessionTestCase
      .statesFrom { $0.applicationShouldRequestHealthAuthorization(UIApplication.shared) }
      .map { $0.isExperiencingHealthAuthorizationRequest }
      ==
      [false, true, false]
    )
    
    XCTAssert(
      SessionTestCase
      .statesFrom { $0.applicationProtectedDataDidBecomeAvailable(UIApplication.shared) }
      .map { $0.isProtectedDataAvailable }
      ==
      [.none(false), .did(true), .none(true)]
    )
    
    XCTAssert(
      SessionTestCase
      .statesFrom { $0.applicationProtectedDataWillBecomeUnavailable(UIApplication.shared) }
      .map { $0.isProtectedDataAvailable }
      ==
      [.none(false), .will(false), .none(false)]
    )
    
    print(SessionTestCase
      .statesFrom {
        $0.application(
          UIApplication.shared,
          didRegister: UIUserNotificationSettingsStub(id: "x")
        )
      }
      .map { $0.registeredUserNotificationSettings })
    
    XCTAssert(
      SessionTestCase
      .statesFrom {
        $0.application(
          UIApplication.shared,
          didRegister: UIUserNotificationSettingsStub(id: "x")
        )
      }
      .map { $0.registeredUserNotificationSettings }
      ==
      [
        .none,
        .some(UIUserNotificationSettingsStub(id: "x") as UIUserNotificationSettings)
      ]
    )
    
    XCTAssert(
      SessionTestCase
      .statesFrom {
        $0.application(
          UIApplication.shared,
          didFailToRegisterForRemoteNotificationsWithError: ErrorStub(id: "x")
        )
      }
      .map { $0.remoteNotificationRegistration }
      ==
      [.idle, .error(ErrorStub(id: "x") as Error)]
    )
    
    XCTAssert(
      SessionTestCase
      .statesFrom {
        $0.application(
          UIApplication.shared,
          didRegisterForRemoteNotificationsWithDeviceToken: Data()
        )
      }
      .map { $0.remoteNotificationRegistration }
      ==
      [.idle, .token(Data())]
    )
    
    XCTAssert(
      SessionTestCase
      .statesFrom {
        $0.application(
          UIApplication.shared,
          didDecodeRestorableStateWith: CoderStub(id: "x")
        )
      }
      .map { $0.stateRestoration }
      ==
      [.idle, .didDecode(CoderStub(id: "x")), .idle]
    )

    XCTAssert(
      SessionTestCase
      .statesFrom {
        $0.application(
          UIApplication.shared,
          willEncodeRestorableStateWith: CoderStub(id: "x")
        )
      }
      .map { $0.stateRestoration }
      ==
      [.idle, .willEncode(CoderStub(id: "x")), .idle]
    )

    XCTAssert(
      SessionTestCase
      .statesFrom {
        $0.application(
          UIApplication.shared,
          shouldSaveApplicationState: CoderStub(id: "x")
        )
      }
      .map { $0.shouldSaveApplicationState }
      ==
      [.idle, .considering(CoderStub(id: "x") as NSCoder)]
    ) // might want to refactor to bool or change default to .allow(true)
    
    XCTAssert(
      SessionTestCase
      .statesFrom {
        $0.application(
          UIApplication.shared,
          shouldRestoreApplicationState: CoderStub(id: "x")
        )
      }
      .map { $0.shouldRestoreApplicationState }
      ==
      [.idle, .considering(CoderStub(id: "x") as NSCoder)]
    ) // might want to refactor to bool or change default to .allow(true)
    
    XCTAssert(
      SessionTestCase
      .statesFrom {
        $0.application(
          UIApplication.shared,
          willContinueUserActivityWithType: "x"
        )
      }
      .map { $0.userActivityState }
      ==
      [.idle, .willContinue("x")]
    )
    
    XCTAssert(
      SessionTestCase
      .statesFrom {
        $0.application(
          UIApplication.shared,
          didFailToContinueUserActivityWithType: "x",
          error: ErrorStub(id: "y")
        )
      }
      .map { $0.userActivityState }
      ==
      [.idle, .didFail("x", ErrorStub(id: "y")), .idle]
    )
    
    let activity = NSUserActivity(activityType: "x")
    XCTAssert(
      SessionTestCase
      .statesFrom {
        $0.application(
          UIApplication.shared,
          didUpdate: activity
        )
      }
      .map { $0.userActivityState }
      ==
      [.idle, .didContinue(activity), .idle]
    )
    
    XCTAssert(
      SessionTestCase
      .statesFrom {
        $0.application(
          UIApplication.shared,
          continue: activity,
          restorationHandler: { _ in }
        )
      }
      .map { $0.userActivityState }
      ==
      [.idle, .isContinuing(activity)]
    )
    
    XCTAssert(
      SessionTestCase
      .statesFrom { $0.applicationWillResignActive(UIApplication.shared) }
      .map { $0.state }
      ==
      [.none(.awaitingLaunch), .will(.resigned)]
    )
    
    XCTAssert(
      SessionTestCase
      .statesFrom {
        $0.application(
          UIApplication.shared,
          willChangeStatusBarOrientation: .landscapeLeft,
          duration: 0.0
        )
      }
      .map { $0.statusBarOrientation }
      ==
      [.none(.unknown), .will(.landscapeLeft)]
    )
    
    XCTAssert(
      SessionTestCase
      .statesFrom {
        $0.application(
          UIApplication.shared,
          didChangeStatusBarOrientation: .landscapeLeft
        )
      }
      .map { $0.statusBarOrientation }
      ==
      [.none(.unknown), .did(.landscapeLeft), .none(.landscapeLeft)]
    )
    
    XCTAssert(
      SessionTestCase
      .statesFrom {
        $0.application(
          UIApplication.shared,
          willChangeStatusBarFrame: CGRect(x: 1, y: 2, width: 3, height: 4)
        )
      }
      .map { $0.statusBarFrame }
      ==
      [.none(.zero), .will(CGRect(x: 1, y: 2, width: 3, height: 4))]
    )

    // Consider adding beginState to -willChange enum option .will(from: to:)
    // Or firing changes for every frame of animation
    
//    XCTAssert(
//      SessionTestCase
//      .statesFrom {
//        $0.application(
//          UIApplication.shared,
//          didChangeStatusBarFrame: CGRect(x: 1, y: 2, width: 3, height: 4)
//        )
//      }
//      .map { $0.statusBarFrame }
//      ==
//      [.none(.zero), .did(CGRect(x: 0, y: 0, width: 320, height: 20))]
//    )

    XCTAssert(
      SessionTestCase
      .statesFrom {
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
        .progressing(.ios8(.some( "x"), UILocalNotification(), {}))
      ]
    )
    
    XCTAssert(
      SessionTestCase
      .statesFrom {
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

    XCTAssert(
      SessionTestCase
      .statesFrom {
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
    
    XCTAssert(
      SessionTestCase
      .statesFrom {
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
            .some( "x"),
            UILocalNotification(),
            ["y":"z"],
            {}
          )
        )
      ]
    )
    
    XCTAssert(
      SessionTestCase.statesFrom(
        model: Session.Model.empty.with(
          shortcutItem: Session.Model.ShortcutItem(
            value: .stub,
            action: .idle
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
      .map { $0.shortcutItems }
      .flatMap { $0 }
      ==
      [
        Session.Model.ShortcutItem(
          value: .stub,
          action: .idle
        ),
        Session.Model.ShortcutItem(
          value: .stub,
          action: .progressing(
            Session.Model.ShortcutItem.Action(
              id: .stub,
              completion: { _ in }
            )
          )
        )
      ]
    )
    
    XCTAssert(
      SessionTestCase
      .statesFrom {
        $0.application(
          UIApplication.shared,
          handleEventsForBackgroundURLSession: "x",
          completionHandler: {}
        )
      }
      .map { $0.backgroundURLSessionAction }
      ==
      [
        .idle,
        .progressing("x", {})
      ]
    )
    
    XCTAssert(
      SessionTestCase
      .statesFrom {
        $0.application(
          UIApplication.shared,
          didReceiveRemoteNotification: ["x":"y"],
          fetchCompletionHandler: { _ in }
        )
      }
      .map { $0.remoteNotification }
      ==
      [
        .idle,
        .progressing(
          Session.Model.RemoteNofiticationAction(
            notification: ["x":"y"],
            completion: { _ in }
          )
        )
      ]
    )
    
//    XCTAssert(
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
    
    XCTAssert(
      SessionTestCase
      .statesFrom {
        $0.application(
          UIApplication.shared,
          handleWatchKitExtensionRequest: ["x":"y"],
          reply: { _ in }
        )
      }
      .map { $0.watchKitExtensionRequest }
      ==
      [
        .idle,
        .progressing(
          Session.Model.WatchKitExtensionRequest(
            userInfo: ["x":"y"],
            reply: { _ in }
          )
        )
      ]
    )
    
    XCTAssert(
      SessionTestCase
      .statesFrom {
        $0.application(
          UIApplication.shared,
          shouldAllowExtensionPointIdentifier: .keyboard
        )
      }
      .map { $0.extensionPointIdentifier }
      ==
      [.idle, .considering(.keyboard)]
    )
    
    XCTAssert(
      SessionTestCase
      .statesFrom {
        $0.application(
          UIApplication.shared,
          supportedInterfaceOrientationsFor: WindowStub(id: "x")
        )
      }
      .map { $0.interfaceOrientations }.flatMap { $0 }
      ==
      [.considering(WindowStub(id: "x") as UIWindow)]
    )

    XCTAssert(
      SessionTestCase
      .statesFrom {
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
          Session.Model.RestorationQuery(
            identifier: "x",
            coder: CoderStub(id: "y") as NSCoder
          )
        )
      ]
    )

  }
  
  func testWillFinishLaunching() {
    let cycle = SessionCycle { events, session -> Observable<SessionTestCase.SessionCycle.DriverModels> in
      session
      .rendered(events.map { $0.session })
      .map { model -> Session.Model in
        switch model.state {
        case .will(let a):
          switch a {
          case .launched(let _):
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
        edit.session = model
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
    let cycle = SessionCycle { events, session -> Observable<SessionTestCase.SessionCycle.DriverModels> in
      session
      .rendered(events.map { $0.session })
      .map { model -> Session.Model in
        var new = model
        new.shouldLaunch = true
        if case .considering(let query) = model.urlActionIncoming {
          switch query {
          case .ios4(let URL, let app, let annotation):
            new.urlActionIncoming = .allowing(URL)
          default: break
          }
        }
        return new
      }
      .withLatestFrom(events) { model, app in
        var edit = app
        edit.session = model
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
    let cycle = SessionCycle { events, session -> Observable<SessionTestCase.SessionCycle.DriverModels> in
      session
      .rendered(events.map { $0.session })
      .map { model -> Session.Model in
        var new = model
        new.shouldLaunch = true
        if case .considering(let query) = model.urlActionIncoming {
          switch query {
          case .ios9(let URL, let options):
            new.urlActionIncoming = .allowing(URL)
          default: break
          }
        }
        return new
      }
      .withLatestFrom(events) { model, app in
        var edit = app
        edit.session = model
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
    let cycle = SessionCycle { events, session -> Observable<SessionTestCase.SessionCycle.DriverModels> in
      session
      .rendered(events.map { $0.session })
      .map { model -> Session.Model in
        var new = model
        new.shouldLaunch = true
        new.interfaceOrientations = model.interfaceOrientations.map {
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
      .withLatestFrom(events) { model, app in
        var edit = app
        edit.session = model
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
    let cycle = SessionCycle { events, session -> Observable<SessionTestCase.SessionCycle.DriverModels> in
      session
      .rendered(events.map { $0.session })
      .map { model -> Session.Model in
        var new = model
        new.shouldLaunch = true
        if case .considering(let ID) = model.extensionPointIdentifier {
          new.extensionPointIdentifier = .allowing(ID)
        }
        return new
      }
      .withLatestFrom(events) { model, app in
        var edit = app
        edit.session = model
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
  
  func testViewControllerWithRestorationIdentifierPath() {
    let cycle = SessionCycle { events, session -> Observable<SessionTestCase.SessionCycle.DriverModels> in
      session
      .rendered(events.map { $0.session })
      .map { model -> Session.Model in
        var new = model
        new.shouldLaunch = true
        if case .considering(let query) = new.viewControllerRestoration {
          new.viewControllerRestoration = .allowing(
            Session.Model.RestorationResponse(
              identifier: query.identifier,
              view: ViewControllerStub(id: "x")
            )
          )
        }
        return new
      }
      .withLatestFrom(events) { model, app in
        var edit = app
        edit.session = model
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
  
  func testShouldSaveApplicationState() {
    let cycle = SessionCycle { events, session -> Observable<SessionTestCase.SessionCycle.DriverModels> in
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
      .withLatestFrom(events) { model, app in
        var edit = app
        edit.session = model
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
  
  func testShouldRestoreApplicationState() {
    let cycle = SessionCycle { events, session -> Observable<SessionTestCase.SessionCycle.DriverModels> in
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
      .withLatestFrom(events) { model, app in
        var edit = app
        edit.session = model
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
    let cycle = SessionCycle { events, session -> Observable<SessionTestCase.SessionCycle.DriverModels> in
      session
      .rendered(events.map { $0.session })
      .map { model -> Session.Model in
        var new = model
        new.shouldLaunch = true
        switch model.userActivityState {
        case .willContinue(let type):
          new.userActivityState = .shouldNotifyUserActivitiesWithType(type)
        default:
          break
        }
        return new
      }
      .withLatestFrom(events) { model, app in
        var edit = app
        edit.session = model
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
    let cycle = SessionCycle { events, session -> Observable<SessionTestCase.SessionCycle.DriverModels> in
      session
      .rendered(events.map { $0.session })
      .map { model -> Session.Model in
        var new = model
        new.shouldLaunch = true
        switch model.userActivityState {
          case .isContinuing(let activity):
          new.userActivityState = .hasAvailableData(activity)
        default:
          break
        }
        return new
      }
      .withLatestFrom(events) { model, app in
        var edit = app
        edit.session = model
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
  
  func testRenderingIsIgnoringUserEvents() {

    let x = Session.Model.empty
    var y = x; y.isIgnoringUserEvents = true
    var z = y; z.isIgnoringUserEvents = false
    
    XCTAssert(
      SessionTestCase.statesFromStream(stream: Observable.of(x, y, x))
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
    
    let x = Session.Model.empty
    var y = x; y.isIdleTimerDisabled = true
    var z = y; z.isIdleTimerDisabled = false
    
    XCTAssert(
      SessionTestCase.statesFromStream(stream: Observable.of(x, y, x))
      .map { $0.isIdleTimerDisabled }
      ==
      [
        false,
        true,
        false
      ]
    )
  }
  
  func testRenderingURLActionOutgoing() {
    
    let asyncCallbacks = expectation(description: "...")
    let empty = Session.Model.empty
    var y = empty; y.urlActionOutgoing = .attempting(URL(string: "https://www.duckduckgo.com")!)
    let delegate = SessionTestDelegate(start: y)
    delegate.application(
      UIApplication.shared,
      willFinishLaunchingWithOptions: nil
    )
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      XCTAssert(
        delegate.events.map { $0.urlActionOutgoing }
          ==
          [
            .attempting(URL(string: "https://www.duckduckgo.com")!),
            .opening(URL(string: "https://www.duckduckgo.com")!), // .will(.launched)
            .opening(URL(string: "https://www.duckduckgo.com")!),
            .idle
        ]
      )
      asyncCallbacks.fulfill()
      let _ = delegate
    }
    waitForExpectations(timeout: 30)
  }
  
  func testRenderingSendAction() {
    
    let action = Session.Model.TargetAction(
      action: #selector(getter: UIApplication.isIdleTimerDisabled),
      target: UIApplication.shared,
      sender: nil,
      event: nil
    )
    let asyncCallbacks = expectation(description: "...")
    let empty = Session.Model.empty
    var y = empty; y.targetAction = .sending(action)
    
    let delegate = SessionTestDelegate(start: y)
    delegate.application(
      UIApplication.shared,
      willFinishLaunchingWithOptions: nil
    )
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      XCTAssert(
        delegate.events.map { $0.targetAction }
          ==
          [
            .sending(action),
            .responding(action, true),
            .responding(action, true), // .will(.launched)
            .idle
        ]
      )
      asyncCallbacks.fulfill()
      let _ = delegate
    }
    waitForExpectations(timeout: 30)
  }
  
  func testRenderingBackgroundTasksMarkInProgress() {
    
    let asyncCallbacks = expectation(description: "...")
    let empty = Session.Model.empty
    var y = empty; y.backgroundTasks = [
      Session.Model.BackgroundTask(name: "x", state: .pending)
    ]
    
    let delegate = SessionTestDelegate(start: y)
    delegate.application(
      UIApplication.shared,
      willFinishLaunchingWithOptions: nil
    )
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      XCTAssert(
        delegate.events.map { $0.backgroundTasks }.flatMap { $0 }
          ==
          [
            Session.Model.BackgroundTask(name: "x", state: .pending),
            Session.Model.BackgroundTask(name: "x", state: .progressing(2)), // .will(.launch)
            Session.Model.BackgroundTask(name: "x", state: .progressing(2))
        ]
      )
      asyncCallbacks.fulfill()
      let _ = delegate
    }
    waitForExpectations(timeout: 30)
  }
  
  func testRenderingBackgroundTasksMarkComplete() {
    
    let asyncCallbacks = expectation(description: "...")
    let empty = Session.Model.empty
    var y = empty; y.backgroundTasks = [
      Session.Model.BackgroundTask(name: "x", state: .pending)
    ]
    
    let delegate = SessionTestDelegate(start: y) {
      var edit = $0
      edit.backgroundTasks = Set(
        edit.backgroundTasks.map { x in
          var new = x
          if case .progressing(let a) = x.state {
            new.state = .complete(a)
          }
          return new
        }
      )
      return edit
    }
    delegate.application(
      UIApplication.shared,
      willFinishLaunchingWithOptions: nil
    )
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      XCTAssert(
        delegate.events.map { $0.backgroundTasks }.flatMap { $0 }
          ==
          [
            Session.Model.BackgroundTask(name: "x", state: .pending),
            Session.Model.BackgroundTask(name: "x", state: .complete(1)), // .will(.launch)
            Session.Model.BackgroundTask(name: "x", state: .complete(1))
        ]
      )
      asyncCallbacks.fulfill()
      let _ = delegate
    }
    waitForExpectations(timeout: 30)
  }
  
  func testRenderingBackgroundURLSessionAction() {
    /* .complete is a read-only selection and is normally set internally.
     Session should follow .complete callbacks with state of .idle */
    let x = Session.Model.empty
    var y = x; y.backgroundURLSessionAction = .progressing("id", {})
    var z = y; z.backgroundURLSessionAction = .complete
    
    XCTAssert(
      SessionTestCase.statesFromStream(stream: Observable.of(x, y, z))
      .map { $0.backgroundURLSessionAction }
      ==
      [
        .idle,
        .progressing("id", {}),
        .idle
      ]
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
    let z = Session.additions(new: x, old: y)
    XCTAssert(z.count == 1)
  }
  
  func testDeletions() {
    let x = ["x"]
    let y: [String] = []
    let z = Session.deletions(old: x, new: y)
    XCTAssert(z.count == 1)
  }
  
  func testCompletedBackgroundIDs() {
    let x = [Session.Model.BackgroundTask(name: "x", state: .complete(2017))]
    let z = x.flatMap { $0.ID }
    XCTAssert(z == [2017])
  }
  
  func testDeletedBackgroundTaskIDs() {
    let x = [Session.Model.BackgroundTask(name: "x", state: .progressing(2017))]
    let y: [Session.Model.BackgroundTask] = []
    let z = Session.deletions(old: x, new: y).flatMap { $0.ID }
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
  
  class SessionCycle: SinkSourceConverting {
    struct DriverModels {
      var session: Session.Model
    }
    let filter: (Observable<DriverModels>, Session) -> Observable<DriverModels>
    init(filter: @escaping (Observable<DriverModels>, Session) -> Observable<DriverModels>) {
      self.filter = filter
    }
    func effectsFrom(events: Observable<DriverModels>, session: Session) -> Observable<DriverModels> { return
      filter(events, session)
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

extension Session.Model {
  func with(shortcutItem: Session.Model.ShortcutItem) -> Session.Model {
    var edit = self
    edit.shortcutItems += [shortcutItem]
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
