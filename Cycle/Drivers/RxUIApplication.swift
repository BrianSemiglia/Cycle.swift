//
//  Session.swift
//  Cycle
//
//  Created by Brian Semiglia on 1/26/17.
//  Copyright © 2017 Brian Semiglia. All rights reserved.
//

import Foundation
import RxSwift

extension Session {
  struct Model {
    var shouldSaveApplicationState: Bool
    var shouldRestoreApplicationState: Bool
    var willContinueUserActivityWithType: Bool
    var continueUserActivity: Bool
    var shouldLaunch: Bool
    var state: State
    
    enum State {
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
      case awaitingLaunch
      case willEnterForeground
      case didEnterBackground
      case willFinishLaunching
      case didFinishLaunching
      case didFinishLaunchingWith(External)
      case didBecomeActive
      case willResignActive
      case willTerminate
      case significantTimeChange
      case didReceiveMemoryWarning
      case shouldSaveApplicationState(NSCoder)
      case shouldRestoreApplicationState(NSCoder)
      case willEncodeRestorableStateWith(NSCoder)
      case didDecodeRestorableStateWith(NSCoder)
      case shouldRequestHealthAuthorization
      case protectedDataDidBecomeAvailable
      case protectedDataWillBecomeUnavailable
      case didReceiveRemoteNotification([AnyHashable : Any])
      case didRegisterNotificationSettings(UIUserNotificationSettings)
      case didFailToRegisterForRemoteNotificationsWith(Error)
      case didRegisterForRemoteNotificationsWithDeviceToken(Data)
      case willContinueUserActivityWith(String)
      case didFailToContinueUserActivityWith(String, Error)
      case didUpdateUserActivity(NSUserActivity)
      case continueUserActivity(NSUserActivity)
    }
  }
}

class Session: NSObject, UIApplicationDelegate {
  
  init(_ input: Model) {
    output = BehaviorSubject<Model>(value: input)
  }
  
  static let shared = Session(Session.Model.empty)
  fileprivate var disposable: Disposable?
  fileprivate let output: BehaviorSubject<Model>
  fileprivate var model: Model?
  
  func rendered(_ input: Observable<Model>) -> Observable<Model> { return
    input
    .distinctUntilChanged(==)
    .flatMap { model in
      Observable.create { [weak self] observer in
        self?.model = model
        if self?.disposable == nil {
          self?.disposable = self?.output.subscribe {
            if let new = $0.element {
              observer.on(.next(new))
            }
          }
        }
        return Disposables.create()
      }
    }
  }
  
  func applicationWillTerminate(_ application: UIApplication) {
    if var edit = model {
      edit.state = .willTerminate
      output.on(.next(edit))
    }
  }
  func applicationDidBecomeActive(_ application: UIApplication) {
    if var edit = model {
      edit.state = .didBecomeActive
      output.on(.next(edit))
    }
  }
  func applicationWillResignActive(_ application: UIApplication) {
    if var edit = model {
      edit.state = .willResignActive
      output.on(.next(edit))
    }
  }
  func applicationDidEnterBackground(_ application: UIApplication) {
    if var edit = model {
      edit.state = .didEnterBackground
      output.on(.next(edit))
    }
  }
  func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
    if var edit = model {
      edit.state = .willFinishLaunching
      output.on(.next(edit))
    }
    return model?.shouldLaunch ?? false
  }
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
    if var edit = model {
      edit.state = .didFinishLaunching
      output.on(.next(edit))
    }
    return model?.shouldLaunch ?? false
  }
  func applicationWillEnterForeground(_ application: UIApplication) {
    if var edit = model {
      edit.state = .willEnterForeground
      output.on(.next(edit))
    }
  }
  func applicationSignificantTimeChange(_ application: UIApplication) {
    if var edit = model {
      edit.state = .significantTimeChange
      output.on(.next(edit))
    }
  }
  func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
    if var edit = model {
      edit.state = .didReceiveMemoryWarning
      output.on(.next(edit))
    }
  }
  func applicationShouldRequestHealthAuthorization(_ application: UIApplication) {
    if var edit = model {
      edit.state = .shouldRequestHealthAuthorization
      output.on(.next(edit))
    }
  }
  func applicationProtectedDataDidBecomeAvailable(_ application: UIApplication) {
    if var edit = model {
      edit.state = .protectedDataDidBecomeAvailable
      output.on(.next(edit))
    }
  }
  func applicationProtectedDataWillBecomeUnavailable(_ application: UIApplication) {
    if var edit = model {
      edit.state = .protectedDataWillBecomeUnavailable
      output.on(.next(edit))
    }
  }
  func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable : Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    if var edit = model {
      edit.state = .didReceiveRemoteNotification(userInfo)
      output.on(.next(edit))
    }
  }
  func application(
    _ application: UIApplication,
    didRegister notificationSettings: UIUserNotificationSettings
  ) {
    if var edit = model {
      edit.state = .didRegisterNotificationSettings(notificationSettings)
      output.on(.next(edit))
    }
  }
  func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    if var edit = model {
      edit.state = .didFailToRegisterForRemoteNotificationsWith(error)
      output.on(.next(edit))
    }
  }
  func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken token: Data
  ) {
    if var edit = model {
      edit.state = .didRegisterForRemoteNotificationsWithDeviceToken(token)
      output.on(.next(edit))
    }
  }
  func application(
    _ application: UIApplication,
    didDecodeRestorableStateWith coder: NSCoder
  ) {
    if var edit = model {
      edit.state = .didDecodeRestorableStateWith(coder)
      output.on(.next(edit))
    }
  }
  func application(
    _ application: UIApplication,
    willEncodeRestorableStateWith coder: NSCoder
  ) {
    if var edit = model {
      edit.state = .willEncodeRestorableStateWith(coder)
      output.on(.next(edit))
    }
  }
  func application(
    _ application: UIApplication,
    shouldSaveApplicationState coder: NSCoder
  ) -> Bool {
    if var edit = model {
      edit.state = .shouldSaveApplicationState(coder)
      output.on(.next(edit))
    }
    return model?.shouldSaveApplicationState ?? false
  }
  func application(
    _ application: UIApplication,
    shouldRestoreApplicationState coder: NSCoder
  ) -> Bool {
    if var edit = model {
      edit.state = .shouldRestoreApplicationState(coder)
      output.on(.next(edit))
    }
    return model?.shouldRestoreApplicationState ?? false
  }
  func application(
    _ application: UIApplication,
    willContinueUserActivityWithType userActivityType: String
  ) -> Bool {
    if var edit = model {
      edit.state = .willContinueUserActivityWith(userActivityType)
      output.on(.next(edit))
    }
    return model?.willContinueUserActivityWithType ?? false
  }
  func application(
    _ application: UIApplication,
    didFailToContinueUserActivityWithType userActivityType: String,
    error: Error
  ) {
    if var edit = model {
      edit.state = .didFailToContinueUserActivityWith(userActivityType, error)
      output.on(.next(edit))
    }
  }
  func application(
    _ application: UIApplication,
    didUpdate userActivity: NSUserActivity
  ) {
    if var edit = model {
      edit.state = .didUpdateUserActivity(userActivity)
      output.on(.next(edit))
    }
  }
  func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([Any]?) -> Void
  ) -> Bool {
    if var edit = model {
      edit.state = .continueUserActivity(userActivity)
      output.on(.next(edit))
    }
    return model?.continueUserActivity ?? false
  }
}

extension Session.Model: Equatable {
  static func ==(left: Session.Model, right: Session.Model) -> Bool { return
    left.continueUserActivity == right.continueUserActivity
    && left.shouldLaunch == right.shouldLaunch
    && left.shouldRestoreApplicationState == right.shouldRestoreApplicationState
    && left.shouldSaveApplicationState == right.shouldSaveApplicationState
    && left.willContinueUserActivityWithType == right.willContinueUserActivityWithType
    && left.state == right.state
  }
}

extension Session.Model.State: Equatable {
  static func ==(left: Session.Model.State, right: Session.Model.State) -> Bool {
    switch (left, right) {
    case (.awaitingLaunch, .awaitingLaunch): return true
    case (.willEnterForeground, .willEnterForeground): return true
    case (.didEnterBackground, .didEnterBackground): return true
    case (.willFinishLaunching, .willFinishLaunching): return true
    case (.didFinishLaunching, .didFinishLaunching): return true
    case (.didFinishLaunchingWith(let a), .didFinishLaunchingWith(let b)): return true
    case (.didBecomeActive, .didBecomeActive): return true
    case (.willResignActive, .willResignActive): return true
    case (.willTerminate, .willTerminate): return true
    case (.significantTimeChange, .significantTimeChange): return true
    case (.didReceiveMemoryWarning, .didReceiveMemoryWarning): return true
    case (.shouldSaveApplicationState(let a), .shouldSaveApplicationState(let b)): return true
    case (.shouldRestoreApplicationState(let a), .shouldRestoreApplicationState(let b)): return true
    case (.willEncodeRestorableStateWith(let a), .willEncodeRestorableStateWith(let b)): return true
    case (.didDecodeRestorableStateWith(let a), .didDecodeRestorableStateWith(let b)): return true
    case (.shouldRequestHealthAuthorization, .shouldRequestHealthAuthorization): return true
    case (.protectedDataDidBecomeAvailable, .protectedDataDidBecomeAvailable): return true
    case (.protectedDataWillBecomeUnavailable, .protectedDataWillBecomeUnavailable): return true
    case (.didReceiveRemoteNotification(let a), .didReceiveRemoteNotification(let b)): return true
    case (.didRegisterNotificationSettings(let a), .didRegisterNotificationSettings(let b)): return true
    case (.didFailToRegisterForRemoteNotificationsWith(let a), .didFailToRegisterForRemoteNotificationsWith(let b)): return true
    case (.didRegisterForRemoteNotificationsWithDeviceToken(let a), .didRegisterForRemoteNotificationsWithDeviceToken(let b)): return true
    case (.willContinueUserActivityWith(let a), .willContinueUserActivityWith(let b)): return true
    case (.didFailToContinueUserActivityWith(let a), .didFailToContinueUserActivityWith(let b)): return true
    case (.didUpdateUserActivity(let a), .didUpdateUserActivity(let b)): return true
    case (.continueUserActivity(let a), .continueUserActivity(let b)): return true
    default:
      return false
    }
  }
}
