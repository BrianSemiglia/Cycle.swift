//
//  Session.swift
//  Cycle
//
//  Created by Brian Semiglia on 1/26/17.
//  Copyright © 2017 Brian Semiglia. All rights reserved.
//

import Foundation
import CloudKit
import RxSwift
import Changeset

extension Session {
  struct Model {
    var isIgnoringUserEvents: Bool
    var isIdleTimerDisabled: Bool
    var openingURL: URL?
    var sendingEvent: UIEvent?
    var sendingAction: TargetAction?
    var isNetworkActivityIndicatorVisible: Bool
    var iconBadgeNumber: Int
    var supportsShakeToEdit: Bool
    var pendingBackgroundTasks: [BackgroundTask] // input
    var runningBackgroundTasksIdentifiers: [UIBackgroundTaskIdentifier] // output
    var minimumBackgroundFetchInterval: FetchInterval
    var typesRegisteredForRemoteNotifications: [UIRemoteNotificationType]
    var presentedLocalNotification: UILocalNotification?
    var scheduledLocalNotifications: [UILocalNotification]
    var registeredUserNotificationSettings: UIUserNotificationSettings?
    var isReceivingRemoteControlEvents: Bool
    var newsStandIconImage: UIImage?
    var shortcutItems: [UIApplicationShortcutItem]
    var shouldSaveApplicationState: Bool
    var shouldRestoreApplicationState: Bool
    var shouldNotifyUserActivitiesWithTypes: [String]
    var activitiesWithAvaliableData: [NSUserActivity]
    var shouldLaunch: Bool
    var allowedURLs: [URL]
    var state: State
    var allowedExtensionPointIdentifiers: [UIApplicationExtensionPointIdentifier]
    var supportedInterfaceOrientations: [UIWindow: UIInterfaceOrientationMask]
    var restorationViewControllers: [String: UIViewController]
    
    enum FetchInterval {
      case minimum
      case some(TimeInterval)
      case never
    }
    struct BackgroundTask {
      let name: String
      let expiration: ((Void) -> Void)?
    }
    struct TargetAction {
      let action: Selector
      let target: Any?
      let sender: Any?
      let event: UIEvent?
    }
    enum State {
      enum External {
        enum Query {
          case ios4(URL, String?, Any)
          case ios9(URL, [UIApplicationOpenURLOptionsKey : Any])
        }
        enum Notification {
          case local(UILocalNotification)
          case remote([AnyHashable: Any])
        }
        case query(Query)
        case location(Bool)
        case notification(Notification)
      }
      enum ActionID {
        case some(String)
        case defaultAction
      }
      enum ActionRemote {
        case ios8(ActionID, [AnyHashable: Any], () -> Void)
        case ios9(ActionID, [AnyHashable: Any], [AnyHashable: Any], () -> Void)
      }
      enum ActionLocal {
        case ios8(ActionID, UILocalNotification, () -> Void)
        case ios9(ActionID, UILocalNotification, [AnyHashable: Any], () -> Void)
      }
      case awaitingLaunch
      case willEnterForeground
      case didEnterBackground
      case willFinishLaunching
      case didFinishLaunching
      case didFinishLaunchingWith(External)
      case didBecomeActive
      case willResignActive
      case handleOpenURL(External.Query)
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
      case didReceiveRemoteNotification([AnyHashable : Any], (UIBackgroundFetchResult) -> Void)
      case didReceiveLocalNotification(UILocalNotification)
      case didRegisterNotificationSettings(UIUserNotificationSettings)
      case didFailToRegisterForRemoteNotificationsWith(Error)
      case didRegisterForRemoteNotificationsWithDeviceToken(Data)
      case willContinueUserActivityWith(String)
      case didFailToContinueUserActivityWith(String, Error)
      case didUpdateUserActivity(NSUserActivity)
      case continueUserActivity(NSUserActivity)
      case userDidAcceptCloudKitShareWith(CKShareMetadata)
      case willChangeStatusBarOrientation(UIInterfaceOrientation, TimeInterval)
      case didChangeStatusBarOrientation(UIInterfaceOrientation)
      case willChangeStatusBarFrame(CGRect)
      case didChangeStatusBarFrame(CGRect)
      case handleActionLocal(ActionLocal)
      case handleActionRemote(ActionRemote)
      case performActionFor(UIApplicationShortcutItem)
      case handleEventsForBackgroundURLSession(String)
      case performFetchWithCompletionHandler((UIBackgroundFetchResult) -> Void)
      case handleWatchKitExtensionRequest([AnyHashable: Any])
      case shouldAllowExtensionPointIdentifier(UIApplicationExtensionPointIdentifier)
      case supportedInterfaceOrientationsFor(UIWindow)
      case viewControllerWithRestorationIdentifierPath(String, NSCoder)
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
  fileprivate var model: Model? {
    didSet {
      if let new = model {
        
        if new.isIgnoringUserEvents != oldValue?.isIgnoringUserEvents {
          if new.isIgnoringUserEvents {
            UIApplication.shared.beginIgnoringInteractionEvents()
          } else {
            UIApplication.shared.endIgnoringInteractionEvents()
          }
        }
        
        UIApplication.shared.isIdleTimerDisabled = new.isIdleTimerDisabled
        
        if let url = new.openingURL, url != oldValue?.openingURL {
          UIApplication.shared.openURL(url)
        }
        
        if let new = new.sendingEvent {
          UIApplication.shared.sendEvent(new)
        }
        
        if let new = new.sendingAction {
          UIApplication.shared.sendAction(
            new.action,
            to: new.target,
            from: new.sender,
            for: new.event
          )
        }
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = new.isNetworkActivityIndicatorVisible
        UIApplication.shared.applicationIconBadgeNumber = new.iconBadgeNumber
        UIApplication.shared.applicationSupportsShakeToEdit = new.supportsShakeToEdit
        
        Session.additions(
          new: new.pendingBackgroundTasks,
          old: oldValue?.pendingBackgroundTasks
        ).forEach {
          // need to add these ID to output model's running tasks
          UIApplication.shared.beginBackgroundTask(
            withName: $0.name,
            expirationHandler: $0.expiration
          )
        }
        
        Session.deletions(
          new: new.runningBackgroundTasksIdentifiers,
          old: oldValue?.runningBackgroundTasksIdentifiers
        ).forEach {
          // needs to be delta of old vs new
          UIApplication.shared.endBackgroundTask($0)
        }
        
        switch new.minimumBackgroundFetchInterval {
        case .minimum:
          UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        case .never:
          UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalNever)
        case .some(let value):
          UIApplication.shared.setMinimumBackgroundFetchInterval(value)
        }
        
        let deletionsTypesRegistered = oldValue.flatMap {
          Changeset(
            source: $0.typesRegisteredForRemoteNotifications,
            target: new.typesRegisteredForRemoteNotifications
            ).edits
        }
        
        if deletionsTypesRegistered?.count != 0 {
          UIApplication.shared.unregisterForRemoteNotifications()
          new.typesRegisteredForRemoteNotifications.forEach {
            UIApplication.shared.registerForRemoteNotifications(matching: $0)
          }
        }
        
        if
          let new = new.presentedLocalNotification,
          oldValue?.presentedLocalNotification != new {
          UIApplication.shared.presentLocalNotificationNow(new)
        }
        
        Session.additions(
          new: new.scheduledLocalNotifications,
          old: oldValue?.scheduledLocalNotifications
          ).forEach {
            UIApplication.shared.scheduleLocalNotification($0)
        }
        
        Session.deletions(
          new: new.scheduledLocalNotifications,
          old: oldValue?.scheduledLocalNotifications
          ).forEach {
            UIApplication.shared.cancelLocalNotification($0)
        }
        
        if
          let new = new.registeredUserNotificationSettings,
          oldValue?.registeredUserNotificationSettings != new {
          UIApplication.shared.registerUserNotificationSettings(new)
        }
        
        if oldValue?.isReceivingRemoteControlEvents != new.isReceivingRemoteControlEvents {
          if new.isReceivingRemoteControlEvents {
            UIApplication.shared.beginReceivingRemoteControlEvents()
          } else {
            UIApplication.shared.endReceivingRemoteControlEvents()
          }
        }
        
        if oldValue?.newsStandIconImage != new.newsStandIconImage {
          UIApplication.shared.setNewsstandIconImage(new.newsStandIconImage)
        }
        
        if let old = oldValue, old.shortcutItems != new.shortcutItems {
          UIApplication.shared.shortcutItems = new.shortcutItems
        }
        
      }
    }
  }
  
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
  
  func applicationDidFinishLaunching(_ application: UIApplication) {
    if var edit = model {
      edit.state = .didFinishLaunching
      output.on(.next(edit))
    }
  }

  func application(
    _ application: UIApplication,
    willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil
  ) -> Bool {
    if var edit = model {
      edit.state = .willFinishLaunching
      output.on(.next(edit))
    }
    return model?.shouldLaunch == true
  }

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil
  ) -> Bool {
    if var edit = model {
      edit.state = .didFinishLaunching
      output.on(.next(edit))
    }
    return model?.shouldLaunch == true
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

  func application(
    _ application: UIApplication,
    open url: URL,
    sourceApplication: String?,
    annotation: Any
  ) -> Bool {
    if var edit = model {
      edit.state = .handleOpenURL(.ios4(url, sourceApplication, annotation))
      output.on(.next(edit))
    }
    return model?.allowedURLs.contains(url) ?? false
  }

  func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplicationOpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    if var edit = model {
      edit.state = .handleOpenURL(.ios9(url, options))
      output.on(.next(edit))
    }
    return model?.allowedURLs.contains(url) ?? false
  }

  func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
    if var edit = model {
      edit.state = .didReceiveMemoryWarning
      output.on(.next(edit))
    }
  }

  func applicationWillTerminate(_ application: UIApplication) {
    if var edit = model {
      edit.state = .willTerminate
      output.on(.next(edit))
    }
  }

  func applicationSignificantTimeChange(_ application: UIApplication) {
    if var edit = model {
      edit.state = .significantTimeChange
      output.on(.next(edit))
    }
  }

  func application(
    _ application: UIApplication,
    willChangeStatusBarOrientation newStatusBarOrientation: UIInterfaceOrientation,
    duration: TimeInterval
  ) {
    if var edit = model {
      edit.state = .willChangeStatusBarOrientation(newStatusBarOrientation, duration)
      output.on(.next(edit))
    }
  }

  func application(
    _ application: UIApplication,
    didChangeStatusBarOrientation oldStatusBarOrientation: UIInterfaceOrientation
  ) {
    if var edit = model {
      edit.state = .didChangeStatusBarOrientation(oldStatusBarOrientation)
      output.on(.next(edit))
    }
  }

  func application(
    _ application: UIApplication,
    willChangeStatusBarFrame newStatusBarFrame: CGRect
  ) {
    if var edit = model {
      edit.state = .willChangeStatusBarFrame(newStatusBarFrame)
      output.on(.next(edit))
    }
  }

  func application(
    _ application: UIApplication,
    didChangeStatusBarFrame oldStatusBarFrame: CGRect
  ) {
    if var edit = model {
      edit.state = .didChangeStatusBarFrame(oldStatusBarFrame)
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
    didRegisterForRemoteNotificationsWithDeviceToken token: Data
  ) {
    if var edit = model {
      edit.state = .didRegisterForRemoteNotificationsWithDeviceToken(token)
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
    didReceive notification: UILocalNotification
  ) {
    if var edit = model {
      edit.state = .didReceiveLocalNotification(notification)
      output.on(.next(edit))
    }
  }

  func application(
    _ application: UIApplication,
    handleActionWithIdentifier identifier: String?,
    for notification: UILocalNotification,
    completionHandler: @escaping () -> Void
  ) {
    if var edit = model {
      edit.state = .handleActionLocal(
        .ios8(
          identifier.map {.some($0)} ?? .defaultAction,
          notification,
          completionHandler
        )
      )
      output.on(.next(edit))
    }
  }

  func application(
    _ application: UIApplication,
    handleActionWithIdentifier identifier: String?,
    forRemoteNotification userInfo: [AnyHashable : Any],
    withResponseInfo responseInfo: [AnyHashable : Any],
    completionHandler: @escaping () -> Void
  ) {
    if var edit = model {
      edit.state = .handleActionRemote(
        .ios9(
          identifier.map {.some($0)} ?? .defaultAction,
          userInfo,
          responseInfo,
          completionHandler
        )
      )
      output.on(.next(edit))
    }
  }

  func application(
    _ application: UIApplication,
    handleActionWithIdentifier identifier: String?,
    forRemoteNotification userInfo: [AnyHashable : Any],
    completionHandler: @escaping () -> Void
  ) {
    if var edit = model {
      edit.state = .handleActionRemote(
        .ios8(
          identifier.map {.some($0)} ?? .defaultAction,
          userInfo,
          completionHandler
        )
      )
      output.on(.next(edit))
    }
  }

  func application(
    _ application: UIApplication,
    handleActionWithIdentifier identifier: String?,
    for notification: UILocalNotification,
    withResponseInfo responseInfo: [AnyHashable : Any],
    completionHandler: @escaping () -> Void
  ) {
    if var edit = model {
      edit.state = .handleActionLocal(
        .ios9(
          identifier.map {.some($0)} ?? .defaultAction,
          notification,
          responseInfo,
          completionHandler
        )
      )
      output.on(.next(edit))
    }
  }

  func application(
    _ application: UIApplication,
    didReceiveRemoteNotification info: [AnyHashable : Any],
    fetchCompletionHandler completion: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    if var edit = model {
      edit.state = .didReceiveRemoteNotification(
        info,
        completion
      )
      output.on(.next(edit))
    }
  }

  func application(
    _ application: UIApplication,
    performFetchWithCompletionHandler completion: @escaping (UIBackgroundFetchResult
  ) -> Void) {
    if var edit = model {
      edit.state = .performFetchWithCompletionHandler(completion)
      output.on(.next(edit))
    }
  }

  func application(
    _ application: UIApplication,
    performActionFor shortcutItem: UIApplicationShortcutItem,
    completionHandler: @escaping (Bool) -> Void
  ) {
    if var edit = model {
      edit.state = .performActionFor(shortcutItem)
      output.on(.next(edit))
    }
  }

  func application(
    _ application: UIApplication,
    handleEventsForBackgroundURLSession identifier: String,
    completionHandler: @escaping () -> Void
  ) {
    if var edit = model {
      edit.state = .handleEventsForBackgroundURLSession(identifier)
      output.on(.next(edit))
    }
  }

  func application(
    _ application: UIApplication,
    handleWatchKitExtensionRequest userInfo: [AnyHashable : Any]?,
    reply: @escaping ([AnyHashable : Any]?) -> Void
  ) {
    if var edit = model {
      edit.state = .handleWatchKitExtensionRequest(userInfo ?? [:])
      output.on(.next(edit))
    }
  }

  func applicationShouldRequestHealthAuthorization(_ application: UIApplication) {
    if var edit = model {
      edit.state = .shouldRequestHealthAuthorization
      output.on(.next(edit))
    }
  }

  func applicationDidEnterBackground(_ application: UIApplication) {
    if var edit = model {
      edit.state = .didEnterBackground
      output.on(.next(edit))
    }
  }

  func applicationWillEnterForeground(_ application: UIApplication) {
    if var edit = model {
      edit.state = .willEnterForeground
      output.on(.next(edit))
    }
  }

  func applicationProtectedDataWillBecomeUnavailable(_ application: UIApplication) {
    if var edit = model {
      edit.state = .protectedDataWillBecomeUnavailable
      output.on(.next(edit))
    }
  }

  func applicationProtectedDataDidBecomeAvailable(_ application: UIApplication) {
    if var edit = model {
      edit.state = .protectedDataDidBecomeAvailable
      output.on(.next(edit))
    }
  }

  func application(
    _ application: UIApplication,
    supportedInterfaceOrientationsFor window: UIWindow?
  ) -> UIInterfaceOrientationMask {
    if var edit = model, let window = window {
      edit.state = .supportedInterfaceOrientationsFor(window)
      output.on(.next(edit))
      return model?.supportedInterfaceOrientations[window] ?? .allButUpsideDown
    } else {
      return .allButUpsideDown
    }
  }

  func application(
    _ application: UIApplication,
    shouldAllowExtensionPointIdentifier ID: UIApplicationExtensionPointIdentifier
  ) -> Bool {
    if var edit = model {
      edit.state = .shouldAllowExtensionPointIdentifier(ID)
      output.on(.next(edit))
    }
    return model?.allowedExtensionPointIdentifiers.contains(ID) == true
  }

  func application(
    _ application: UIApplication,
    viewControllerWithRestorationIdentifierPath components: [Any],
    coder: NSCoder
  ) -> UIViewController? {
    if var edit = model, let component = components.last as? String {
      edit.state = .viewControllerWithRestorationIdentifierPath(component, coder)
      output.on(.next(edit))
      return model?.restorationViewControllers[component]
    } else {
      return nil
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
    return model?.shouldSaveApplicationState == true
  }

  func application(
    _ application: UIApplication,
    shouldRestoreApplicationState coder: NSCoder
  ) -> Bool {
    if var edit = model {
      edit.state = .shouldRestoreApplicationState(coder)
      output.on(.next(edit))
    }
    return model?.shouldRestoreApplicationState == true
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
    didDecodeRestorableStateWith coder: NSCoder
  ) {
    if var edit = model {
      edit.state = .didDecodeRestorableStateWith(coder)
      output.on(.next(edit))
    }
  }

  func application(
    _ application: UIApplication,
    willContinueUserActivityWithType type: String
  ) -> Bool {
    if var edit = model {
      edit.state = .willContinueUserActivityWith(type)
      output.on(.next(edit))
    }
    return model?.shouldNotifyUserActivitiesWithTypes.contains(type) == true
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
    return model?.activitiesWithAvaliableData.contains(userActivity) == true
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
    userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShareMetadata
    ) {
    if var edit = model {
      edit.state = .userDidAcceptCloudKitShareWith(cloudKitShareMetadata)
      output.on(.next(edit))
    }
  }
}

extension Session.Model: Equatable {
  static func ==(left: Session.Model, right: Session.Model) -> Bool { return
    left.isIgnoringUserEvents == right.isIgnoringUserEvents
    && left.isIdleTimerDisabled == right.isIdleTimerDisabled
    && left.openingURL == right.openingURL
    && left.sendingEvent == right.sendingEvent
    && left.sendingAction == right.sendingAction
    && left.isNetworkActivityIndicatorVisible == right.isNetworkActivityIndicatorVisible
    && left.iconBadgeNumber == right.iconBadgeNumber
    && left.supportsShakeToEdit == right.supportsShakeToEdit
    && left.pendingBackgroundTasks == right.pendingBackgroundTasks
    && left.runningBackgroundTasksIdentifiers == right.runningBackgroundTasksIdentifiers
    && left.minimumBackgroundFetchInterval == right.minimumBackgroundFetchInterval
    && left.typesRegisteredForRemoteNotifications == right.typesRegisteredForRemoteNotifications
    && left.presentedLocalNotification == right.presentedLocalNotification
    && left.scheduledLocalNotifications == right.scheduledLocalNotifications
    && left.registeredUserNotificationSettings == right.registeredUserNotificationSettings
    && left.isReceivingRemoteControlEvents == right.isReceivingRemoteControlEvents
    && left.newsStandIconImage == right.newsStandIconImage
    && left.shortcutItems == right.shortcutItems
    && left.shouldSaveApplicationState == right.shouldSaveApplicationState
    && left.shouldRestoreApplicationState == right.shouldRestoreApplicationState
    && left.shouldNotifyUserActivitiesWithTypes == right.shouldNotifyUserActivitiesWithTypes
    && left.activitiesWithAvaliableData == right.activitiesWithAvaliableData
    && left.shouldLaunch == right.shouldLaunch
    && left.allowedURLs == right.allowedURLs
    && left.state == right.state
    && left.allowedExtensionPointIdentifiers == right.allowedExtensionPointIdentifiers
    && left.supportedInterfaceOrientations == right.supportedInterfaceOrientations
    && left.restorationViewControllers == right.restorationViewControllers  }
}

extension Session.Model.TargetAction: Equatable {
  static func ==(
    left: Session.Model.TargetAction,
    right: Session.Model.TargetAction
  ) -> Bool { return
    left.action == right.action
    && left.event === right.event
    && (left.sender as? NSObject) === (right.sender as? NSObject)
    && (left.target as? NSObject) === (right.target as? NSObject)
  }
}

extension Session.Model.FetchInterval: Equatable {
  static func ==(
    left: Session.Model.FetchInterval,
    right: Session.Model.FetchInterval
  ) -> Bool {
    switch (left, right) {
    case (.minimum, .minimum): return
      true
    case (.never, .never): return
      true
    case (.some(let a), .some(let b)): return
      a == b
    default: return
      false
    }
  }
}

extension Session.Model.State: Equatable {
  static func ==(
    left: Session.Model.State,
    right: Session.Model.State
  ) -> Bool {
    switch (left, right) {
    case (.awaitingLaunch, .awaitingLaunch): return
      true
    case (.willEnterForeground, .willEnterForeground): return
      true
    case (.didEnterBackground, .didEnterBackground): return
      true
    case (.willFinishLaunching, .willFinishLaunching): return
      true
    case (.didFinishLaunching, .didFinishLaunching): return
      true
    case (.didFinishLaunchingWith(let a), .didFinishLaunchingWith(let b)): return
      a == b
    case (.didBecomeActive, .didBecomeActive): return
      true
    case (.willResignActive, .willResignActive): return
      true
    case (.willTerminate, .willTerminate): return
      true
    case (.significantTimeChange, .significantTimeChange): return
      true
    case (.didReceiveMemoryWarning, .didReceiveMemoryWarning): return
      true
    case (.shouldSaveApplicationState(let a), .shouldSaveApplicationState(let b)): return
      a == b
    case (.shouldRestoreApplicationState(let a), .shouldRestoreApplicationState(let b)): return
      a == b
    case (.willEncodeRestorableStateWith(let a), .willEncodeRestorableStateWith(let b)): return
      a == b
    case (.didDecodeRestorableStateWith(let a), .didDecodeRestorableStateWith(let b)): return
      a == b
    case (.shouldRequestHealthAuthorization, .shouldRequestHealthAuthorization): return
      true
    case (.protectedDataDidBecomeAvailable, .protectedDataDidBecomeAvailable): return
      true
    case (.protectedDataWillBecomeUnavailable, .protectedDataWillBecomeUnavailable): return
      true
    case (.didReceiveRemoteNotification(let a), .didReceiveRemoteNotification(let b)): return
      NSDictionary(dictionary: a.0) == NSDictionary(dictionary: b.0)
    case (.didRegisterNotificationSettings(let a), .didRegisterNotificationSettings(let b)): return
      a == b
    case (.didFailToRegisterForRemoteNotificationsWith(let a), .didFailToRegisterForRemoteNotificationsWith(let b)): return
      true
    case (.didRegisterForRemoteNotificationsWithDeviceToken(let a), .didRegisterForRemoteNotificationsWithDeviceToken(let b)): return
      a == b
    case (.willContinueUserActivityWith(let a), .willContinueUserActivityWith(let b)): return
      a == b
    case (.didFailToContinueUserActivityWith(let a), .didFailToContinueUserActivityWith(let b)): return
      true
    case (.didUpdateUserActivity(let a), .didUpdateUserActivity(let b)): return
      a == b
    case (.continueUserActivity(let a), .continueUserActivity(let b)): return
      a == b
    case (.willChangeStatusBarOrientation(let a), .willChangeStatusBarOrientation(let b)): return
      a == b
    case (.didChangeStatusBarOrientation(let a), .didChangeStatusBarOrientation(let b)): return
      a == b
    case (.willChangeStatusBarFrame(let a), .willChangeStatusBarFrame(let b)): return
      a == b
    case (.didChangeStatusBarFrame(let a), .didChangeStatusBarFrame(let b)): return
      a == b
    case (.handleActionLocal(let a), .handleActionLocal(let b)): return
      a == b
    case (.handleActionRemote(let a), .handleActionRemote(let b)): return
      a == b
    case (.performActionFor(let a), .performActionFor(let b)): return
      a == b
    case (.handleEventsForBackgroundURLSession(let a), .handleEventsForBackgroundURLSession(let b)): return
      a == b
    case (.performFetchWithCompletionHandler, .performFetchWithCompletionHandler): return
      true
    case (.handleWatchKitExtensionRequest(let a), .handleWatchKitExtensionRequest(let b)): return
      NSDictionary(dictionary: a) == NSDictionary(dictionary: b)
    case (.shouldAllowExtensionPointIdentifier(let a), shouldAllowExtensionPointIdentifier(let b)): return
      a == b
    case (.supportedInterfaceOrientationsFor(let a), .supportedInterfaceOrientationsFor(let b)): return
      a == b
    case (.viewControllerWithRestorationIdentifierPath(let a), .viewControllerWithRestorationIdentifierPath(let b)): return 
      a == b
    default: return 
      false
    }
  }
}

extension Session.Model {
  static var empty: Session.Model { return
    Session.Model(
      isIgnoringUserEvents: false,
      isIdleTimerDisabled: false,
      openingURL: nil,
      sendingEvent: nil,
      sendingAction: nil,
      isNetworkActivityIndicatorVisible: false,
      iconBadgeNumber: 0,
      supportsShakeToEdit: true,
      pendingBackgroundTasks: [],
      runningBackgroundTasksIdentifiers: [],
      minimumBackgroundFetchInterval: .never,
      typesRegisteredForRemoteNotifications: [],
      presentedLocalNotification: nil,
      scheduledLocalNotifications: [],
      registeredUserNotificationSettings: nil,
      isReceivingRemoteControlEvents: false,
      newsStandIconImage: nil,
      shortcutItems: [],
      shouldSaveApplicationState: false,
      shouldRestoreApplicationState: false,
      shouldNotifyUserActivitiesWithTypes: [],
      activitiesWithAvaliableData: [],
      shouldLaunch: true,
      allowedURLs: [],
      state: .awaitingLaunch,
      allowedExtensionPointIdentifiers: [],
      supportedInterfaceOrientations: [:],
      restorationViewControllers: [:]
    )
  }
}

extension Session.Model.State.ActionID: Equatable {
  static func ==(
    left: Session.Model.State.ActionID,
    right: Session.Model.State.ActionID
  ) -> Bool {
    switch (left, right) {
    case (.some(let a), .some(let b)): return
      a == b
    case (.defaultAction, .defaultAction): return
      true
    default: return
      false
    }
  }
}

extension Session.Model.State.ActionRemote: Equatable {
  static func ==(
    left: Session.Model.State.ActionRemote,
    right: Session.Model.State.ActionRemote
  ) -> Bool {
    switch (left, right) {
    case (.ios9(let a), ios9(let b)): return
      NSDictionary(dictionary: a.1) == NSDictionary(dictionary: b.1) &&
      NSDictionary(dictionary: a.2) == NSDictionary(dictionary: b.2) &&
      a.0 == b.0
    case (.ios8(let a), .ios8(let b)): return
      NSDictionary(dictionary: a.1) == NSDictionary(dictionary: b.1) &&
      a.0 == b.0
    default: return
      false
    }
  }
}

extension Session.Model.State.ActionLocal: Equatable {
  static func ==(
    left: Session.Model.State.ActionLocal,
    right: Session.Model.State.ActionLocal
  ) -> Bool {
    switch (left, right) {
    case (.ios9(let a), ios9(let b)): return
      a.0 == b.0 &&
      a.1 == b.1 &&
      NSDictionary(dictionary: a.2) == NSDictionary(dictionary: b.2)
    case (.ios8(let a), .ios8(let b)): return
      a.0 == b.0 &&
      a.1 == b.1
    default: return
      false
    }
  }
}

extension Session.Model.State.External: Equatable {
  static func ==(
    left: Session.Model.State.External,
    right: Session.Model.State.External
  ) -> Bool {
    switch (left, right) {
    case (.query(let a), .query(let b)): return
      a == b
    case (.location(let a), .location(let b)): return
      a == b
    case (.notification(let a), .notification(let b)): return
      a == b
    default: return
      false
    }
  }
}

extension Session.Model.State.External.Query: Equatable {
  static func ==(
    left: Session.Model.State.External.Query,
    right: Session.Model.State.External.Query
  ) -> Bool {
    switch (left, right) {
    case (.ios4(let a), .ios4(let b)): return
      a.0 == b.0 && a.1 == b.1
    case (.ios9(let a), .ios9(let b)): return
      a.0 == b.0 &&
      NSDictionary(dictionary: a.1) == NSDictionary(dictionary: b.1)
    default: return
      false
    }
  }
}

extension Session.Model.State.External.Notification: Equatable {
  static func ==(
    left: Session.Model.State.External.Notification,
    right: Session.Model.State.External.Notification
  ) -> Bool {
    switch (left, right) {
    case (.local(let a), .local(let b)): return
      a == b
    case (.remote(let a), .remote(let b)): return
      NSDictionary(dictionary: a) == NSDictionary(dictionary: b)
    default: return
      false
    }
  }
}

func +=<Key, Value> (left: inout [Key: Value], right: [Key: Value]) {
  left = left + right
}

func +<Key, Value> (left: [Key: Value], right: [Key: Value]) -> [Key: Value] {
  var x = right
  left.forEach{ x[$0] = $1 }
  return x
}

extension Session.Model.BackgroundTask: Equatable {
  static func ==(
    left: Session.Model.BackgroundTask,
    right: Session.Model.BackgroundTask
  ) -> Bool { return
    left.name == right.name
  }
}

extension Session {
  static func deletions<T: Equatable>(
    new: [T],
    old: [T]?
  ) -> [T] { return
    old.flatMap {
      Changeset<[T]>(
        source: $0,
        target: new
      ).edits
    }
    .map {
      $0.filter {
        switch $0.operation {
        case .deletion: return true
        default: return false
        }
      }
      .map { $0.value }
    } ?? []
  }
}

extension Session {
  static func additions<T: Equatable>(
    new: [T],
    old: [T]?
    ) -> [T] { return
    old.flatMap {
      Changeset<[T]>(
        source: $0,
        target: new
        ).edits
      }
      .map {
        $0.filter {
          switch $0.operation {
          case .insertion: return true
          default: return false
          }
        }
        .map {
          $0.value
        }
      } ?? []
  }
}
