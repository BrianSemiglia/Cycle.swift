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
  
  static func statesForEvents(call: (Session) -> Any) -> [Session.Model.State] {
    var output: [Session.Model.State] = []
    let session = Session(Session.Model.empty)
    _ = session
      .rendered(Observable<Session.Model>.just(Session.Model.empty))
      .subscribe {
        if let new = $0.element?.state {
          output += [new]
        }
      }
    _ = call(session)
    return output
  }
  
  func testConversionCallbacks() {
    
    XCTAssertEqual(
      SessionTestCase.statesForEvents {
        $0.applicationWillTerminate(UIApplication.shared)
      },
      [.awaitingLaunch, .willTerminate]
    )

    XCTAssertEqual(
      SessionTestCase.statesForEvents {
        $0.applicationDidBecomeActive(UIApplication.shared)
      },
      [.awaitingLaunch, .didBecomeActive]
    )

    XCTAssertEqual(
      SessionTestCase.statesForEvents {
        $0.applicationWillResignActive(UIApplication.shared)
      },
      [.awaitingLaunch, .willResignActive]
    )

    XCTAssertEqual(
      SessionTestCase.statesForEvents {
        $0.applicationDidEnterBackground(UIApplication.shared)
      },
      [.awaitingLaunch, .didEnterBackground]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesForEvents {
        $0.application(
          UIApplication.shared,
          willFinishLaunchingWithOptions: nil
        )
      },
      [.awaitingLaunch, .willFinishLaunching]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesForEvents {
        $0.applicationDidFinishLaunching(UIApplication.shared)
      },
      [.awaitingLaunch, .didFinishLaunching]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesForEvents {
        $0.application(
          UIApplication.shared,
          didFinishLaunchingWithOptions: nil
        )
      },
      [.awaitingLaunch, .didFinishLaunching]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesForEvents {
        $0.applicationWillEnterForeground(UIApplication.shared)
      },
      [.awaitingLaunch, .willEnterForeground]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesForEvents {
        $0.applicationSignificantTimeChange(UIApplication.shared)
      },
      [.awaitingLaunch, .significantTimeChange]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesForEvents {
        $0.applicationDidReceiveMemoryWarning(UIApplication.shared)
      },
      [.awaitingLaunch, .didReceiveMemoryWarning]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesForEvents {
        $0.applicationShouldRequestHealthAuthorization(UIApplication.shared)
      },
      [.awaitingLaunch, .shouldRequestHealthAuthorization]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesForEvents {
        $0.applicationProtectedDataDidBecomeAvailable(UIApplication.shared)
      },
      [.awaitingLaunch, .protectedDataDidBecomeAvailable]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesForEvents {
        $0.applicationProtectedDataWillBecomeUnavailable(UIApplication.shared)
      },
      [.awaitingLaunch, .protectedDataWillBecomeUnavailable]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesForEvents {
        $0.application(
          UIApplication.shared,
          didRegister: UIUserNotificationSettingsStub(id: "x")
        )
      },
      [.awaitingLaunch,
       .didRegisterNotificationSettings(UIUserNotificationSettingsStub(id: "x"))
      ]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesForEvents {
        $0.application(
          UIApplication.shared,
          didFailToRegisterForRemoteNotificationsWithError: ErrorStub(id: "")
        )
      },
      [.awaitingLaunch, .didFailToRegisterForRemoteNotificationsWith(ErrorStub(id: ""))]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesForEvents {
        $0.application(
          UIApplication.shared,
          didRegisterForRemoteNotificationsWithDeviceToken: Data()
        )
      },
      [.awaitingLaunch, .didRegisterForRemoteNotificationsWithDeviceToken(Data())]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesForEvents {
        $0.application(
          UIApplication.shared,
          didDecodeRestorableStateWith: CoderStub(id: "")
        )
      },
      [.awaitingLaunch, .didDecodeRestorableStateWith(CoderStub(id: ""))]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesForEvents {
        $0.application(
          UIApplication.shared,
          willEncodeRestorableStateWith: CoderStub(id: "")
        )
      },
      [.awaitingLaunch, .willEncodeRestorableStateWith(CoderStub(id: ""))]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesForEvents {
        $0.application(
          UIApplication.shared,
          shouldSaveApplicationState: CoderStub(id: "")
        )
      },
      [.awaitingLaunch, .shouldSaveApplicationState(CoderStub(id: ""))]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesForEvents {
        $0.application(
          UIApplication.shared,
          shouldRestoreApplicationState: CoderStub(id: "")
        )
      },
      [.awaitingLaunch, .shouldRestoreApplicationState(CoderStub(id: ""))]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesForEvents {
        $0.application(
          UIApplication.shared,
          willContinueUserActivityWithType: ""
        )
      },
      [.awaitingLaunch, .willContinueUserActivityWith("")]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesForEvents {
        $0.application(
          UIApplication.shared,
          didFailToContinueUserActivityWithType: "",
          error: ErrorStub(id: "")
        )
      },
      [.awaitingLaunch, .didFailToContinueUserActivityWith("", ErrorStub(id: ""))]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesForEvents {
        $0.application(
          UIApplication.shared,
          didFailToContinueUserActivityWithType: "",
          error: ErrorStub(id: "")
        )
      },
      [.awaitingLaunch, .didFailToContinueUserActivityWith("", ErrorStub(id: ""))]
    )
    
    let activity = NSUserActivity(activityType: "x")
    XCTAssertEqual(
      SessionTestCase.statesForEvents {
        $0.application(
          UIApplication.shared,
          didUpdate: activity
        )
      },
      [.awaitingLaunch, .didUpdateUserActivity(activity)]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesForEvents {
        $0.application(
          UIApplication.shared,
          continue: activity,
          restorationHandler: { _ in }
        )
      },
      [.awaitingLaunch, .continueUserActivity(activity)]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesForEvents {
        $0.applicationWillResignActive(UIApplication.shared)
      },
      [.awaitingLaunch, .willResignActive]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesForEvents {
        $0.application(
          UIApplication.shared,
          willChangeStatusBarOrientation: .landscapeLeft,
          duration: 0.0
        )
      },
      [.awaitingLaunch, .willChangeStatusBarOrientation(.landscapeLeft, 0.0)]
    )
    
    XCTAssertNotEqual(
      SessionTestCase.statesForEvents {
        $0.application(
          UIApplication.shared,
          willChangeStatusBarOrientation: .landscapeLeft,
          duration: 0.0
        )
      },
      [.awaitingLaunch, .willChangeStatusBarOrientation(.landscapeLeft, 1.0)]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesForEvents {
        $0.application(
          UIApplication.shared,
          didChangeStatusBarOrientation: .landscapeLeft
        )
      },
      [.awaitingLaunch, .didChangeStatusBarOrientation(.landscapeLeft)]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesForEvents {
        $0.application(
          UIApplication.shared,
          willChangeStatusBarFrame: .zero
        )
      },
      [.awaitingLaunch, .willChangeStatusBarFrame(.zero)]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesForEvents {
        $0.application(
          UIApplication.shared,
          didChangeStatusBarFrame: .zero
        )
      },
      [.awaitingLaunch, .didChangeStatusBarFrame(.zero)]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesForEvents {
        $0.application(
          UIApplication.shared,
          handleActionWithIdentifier: "x",
          for: UILocalNotification(),
          completionHandler: {}
        )
      },
      [.awaitingLaunch,
       .handleActionLocal(.ios8(.some("x"), UILocalNotification(), {}))
      ]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesForEvents {
        $0.application(
          UIApplication.shared,
          handleActionWithIdentifier: "x",
          forRemoteNotification: ["":""],
          withResponseInfo: ["":""],
          completionHandler: {}
        )
      },
      [.awaitingLaunch,
       .handleActionRemote(.ios9(.some("x"), ["":""], ["":""], {}))
      ]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesForEvents {
        $0.application(
          UIApplication.shared,
          handleActionWithIdentifier: "x",
          forRemoteNotification: ["":""],
          completionHandler: {}
        )
      },
      [.awaitingLaunch,
       .handleActionRemote(.ios8(.some("x"), ["":""], {}))
      ]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesForEvents {
        $0.application(
          UIApplication.shared,
          handleActionWithIdentifier: "x",
          for: UILocalNotification(),
          withResponseInfo: ["":""],
          completionHandler: {}
        )
      },
      [.awaitingLaunch,
       .handleActionLocal(.ios9(.some("x"), UILocalNotification(), ["":""], {}))
      ]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesForEvents {
        $0.application(
          UIApplication.shared,
          performActionFor: UIApplicationShortcutItem(type: "", localizedTitle: ""),
          completionHandler: { _ in }
        )
      },
      [.awaitingLaunch,
       .performActionFor(UIApplicationShortcutItem(type: "", localizedTitle: ""))
      ]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesForEvents {
        $0.application(
          UIApplication.shared,
          handleEventsForBackgroundURLSession: "x",
          completionHandler: {}
        )
      },
      [.awaitingLaunch,
       .handleEventsForBackgroundURLSession("x")
      ]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesForEvents {
        $0.application(
          UIApplication.shared,
          didReceiveRemoteNotification: ["":""],
          fetchCompletionHandler: { _ in }
        )
      },
      [.awaitingLaunch,
       .didReceiveRemoteNotification(["":""], { _ in })
      ]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesForEvents {
        $0.application(
          UIApplication.shared,
          performFetchWithCompletionHandler: { _ in }
        )
      },
      [.awaitingLaunch,
       .performFetchWithCompletionHandler({ _ in })
      ]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesForEvents {
        $0.application(
          UIApplication.shared,
          handleWatchKitExtensionRequest: ["":""],
          reply: { _ in }
        )
      },
      [.awaitingLaunch,
       .handleWatchKitExtensionRequest(["":""])
      ]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesForEvents {
        $0.application(
          UIApplication.shared,
          shouldAllowExtensionPointIdentifier: .keyboard
        )
      },
      [.awaitingLaunch,
       .shouldAllowExtensionPointIdentifier(.keyboard)
      ]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesForEvents {
        $0.application(
          UIApplication.shared,
          supportedInterfaceOrientationsFor: WindowStub(id: "x")
        )
      },
      [.awaitingLaunch,
       .supportedInterfaceOrientationsFor(WindowStub(id: "x"))
      ]
    )
    
    XCTAssertEqual(
      SessionTestCase.statesForEvents {
        let x = $0.application(
          UIApplication.shared,
          viewControllerWithRestorationIdentifierPath: ["x"],
          coder: CoderStub(id: "y")
        )
        return x ?? {}
      },
      [.awaitingLaunch,
       .viewControllerWithRestorationIdentifierPath("x", CoderStub(id: "y"))
      ]
    )

  }
  
  func testWillFinishLaunching() {
    let session = Session(SessionCycle.empty)
    let cycle = SessionCycle { events -> Observable<SessionTestCase.SessionCycle.DriverModels> in
      session
      .rendered(events.map { $0.session })
      .map { model -> Session.Model in
        switch model.state {
        case .willFinishLaunching:
          var new = model
          new.shouldLaunch = true
          return new
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
    let session = Session(SessionCycle.empty)
    let cycle = SessionCycle { events -> Observable<SessionTestCase.SessionCycle.DriverModels> in
      session
      .rendered(events.map { $0.session })
      .map { model -> Session.Model in
        var new = model
        new.shouldLaunch = true
        switch model.state {
        case .handleOpenURL(let query):
          switch query {
          case .ios4(let URL, let app, let annotation):
            new.allowedURLs += [URL]
          default: break
          }
          return new
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
    let session = Session(SessionCycle.empty)
    let cycle = SessionCycle { events -> Observable<SessionTestCase.SessionCycle.DriverModels> in
      session
      .rendered(events.map { $0.session })
      .map { model -> Session.Model in
        var new = model
        new.shouldLaunch = true
        switch model.state {
        case .handleOpenURL(let query):
          switch query {
          case .ios9(let URL, let options):
            new.allowedURLs += [URL]
          default: break
          }
          return new
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
    let session = Session(SessionCycle.empty)
    let cycle = SessionCycle { events -> Observable<SessionTestCase.SessionCycle.DriverModels> in
      session
      .rendered(events.map { $0.session })
      .map { model -> Session.Model in
        var new = model
        new.shouldLaunch = true
        switch model.state {
        case .supportedInterfaceOrientationsFor(let window):
          new.supportedInterfaceOrientations += [window: .portraitUpsideDown]
          return new
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
    let session = Session(SessionCycle.empty)
    let cycle = SessionCycle { events -> Observable<SessionTestCase.SessionCycle.DriverModels> in
      session
      .rendered(events.map { $0.session })
      .map { model -> Session.Model in
        var new = model
        new.shouldLaunch = true
        switch model.state {
        case .shouldAllowExtensionPointIdentifier(let ID):
          new.allowedExtensionPointIdentifiers += [ID]
          return new
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
    let session = Session(SessionCycle.empty)
    let cycle = SessionCycle { events -> Observable<SessionTestCase.SessionCycle.DriverModels> in
      session
        .rendered(events.map { $0.session })
        .map { model -> Session.Model in
          var new = model
          new.shouldLaunch = true
          switch model.state {
          case .viewControllerWithRestorationIdentifierPath(let ID, let coder):
            new.restorationViewControllers += [ID: ViewControllerStub(id: "x")]
            return new
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
    let session = Session(SessionCycle.empty)
    let cycle = SessionCycle { events -> Observable<SessionTestCase.SessionCycle.DriverModels> in
      session
      .rendered(events.map { $0.session })
      .map { model -> Session.Model in
        var new = model
        new.shouldLaunch = true
        switch model.state {
        case .shouldSaveApplicationState(let coder):
          new.shouldSaveApplicationState = true
          return new
        case .shouldRestoreApplicationState(let coder):
          new.shouldRestoreApplicationState = true
          return new
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
    
    XCTAssert(
      delegate.application!(
        UIApplication.shared,
        shouldRestoreApplicationState: CoderStub(id: "x")
      )
      ==
      true
    )
  }
  
  func testShouldRestoreApplicationState() {
    let session = Session(SessionCycle.empty)
    let cycle = SessionCycle { events -> Observable<SessionTestCase.SessionCycle.DriverModels> in
      session
        .rendered(events.map { $0.session })
        .map { model -> Session.Model in
          var new = model
          new.shouldLaunch = true
          switch model.state {
          case .shouldRestoreApplicationState(let coder):
            new.shouldRestoreApplicationState = true
            return new
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
    let session = Session(SessionCycle.empty)
    let cycle = SessionCycle { events -> Observable<SessionTestCase.SessionCycle.DriverModels> in
      session
      .rendered(events.map { $0.session })
      .map { model -> Session.Model in
        var new = model
        new.shouldLaunch = true
        switch model.state {
        case .willContinueUserActivityWith(let type):
          new.shouldNotifyUserActivitiesWithTypes += [type]
          return new
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
    let session = Session(SessionCycle.empty)
    let cycle = SessionCycle { events -> Observable<SessionTestCase.SessionCycle.DriverModels> in
      session
      .rendered(events.map { $0.session })
      .map { model -> Session.Model in
        var new = model
        new.shouldLaunch = true
        switch model.state {
        case .continueUserActivity(let activity):
          new.activitiesWithAvaliableData += [activity]
          return new
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
        session: SessionCycle.empty
      )
    }
    static var empty: Session.Model { return
      Session.Model(
        shouldSaveApplicationState: false,
        shouldRestoreApplicationState: false,
        shouldNotifyUserActivitiesWithTypes: [],
        activitiesWithAvaliableData: [],
        shouldLaunch: false,
        allowedURLs: [],
        state: .awaitingLaunch,
        allowedExtensionPointIdentifiers: [],
        supportedInterfaceOrientations: [:],
        restorationViewControllers: [:]
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
