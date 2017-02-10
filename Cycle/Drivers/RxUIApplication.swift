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

enum Change<T: Equatable> {
  case none(T)
  case will(T)
  case did(T)
}

extension Change: Equatable {
  static func ==(left: Change, right: Change) -> Bool {
    switch (left, right) {
    case (.none(let a), .none(let b)): return a == b
    case (.will(let a), .will(let b)): return a == b
    case (.did(let a), .did(let b)): return a == b
    default: return false
    }
  }
}

enum Result<T: Equatable> {
  case none
  case some(T)
  case error(Error)
}

enum Filtered<T: Equatable, U: Equatable> {
  case idle
  case considering(T)
  case allowing(U)
  
  func allowed() -> U? {
    switch self {
    case .allowing(let a): return a
    default: return nil
    }
  }
}

extension AsyncAction {
  func isProgressing() -> Bool {
    switch self {
    case .progressing: return true
    default: return false
    }
  }
}

extension Filtered: Equatable {
  static func ==(left: Filtered, right: Filtered) -> Bool {
    switch (left, right) {
    case (.idle, .idle): return
      true
    case (.considering(let a), .considering(let b)): return
      a == b
    case (.allowing(let a), .allowing(let b)): return
      a == b
    default: return
      false
    }
  }
}

enum AsyncAction<Handler: Equatable> {
  case idle
  case progressing(Handler)
  case complete(Handler)
}

extension Session {
  struct Model {
    var backgroundURLSessionAction: AsyncAction<BackgroundURLSessionAction>
    var fetch: AsyncAction<FetchAction>
    var remoteAction: AsyncAction<ActionRemote>
    var localAction: AsyncAction<ActionLocal>
//    var cloudKitShare: CKShareMetadata?
    var userActivityState: UserActivityState
    var stateRestoration: StateRestoration
    var userActivityContinuation: UserActivityState
    var watchKitExtensionRequest: AsyncAction<WatchKitExtensionRequest>
    var localNotification: UILocalNotification?
    var remoteNotification: AsyncAction<RemoteNofiticationAction>
    var notificationSettings: UIUserNotificationSettings?
    var isObservingSignificantTimeChange: Bool
    var isExperiencingMemoryWarning: Bool
    var state: Change<State>
    var statusBarFrame: Change<CGRect>
    var isProtectedDataAvailable: Change<Bool>
    var deviceToken: Result<Data>
    var statusBarOrientation: Change<UIInterfaceOrientation>
    var runningBackgroundTasksIdentifiers: [UIBackgroundTaskIdentifier]
    var isExperiencingHealthAuthorizationRequest: Bool
    var isIgnoringUserEvents: Bool
    var isIdleTimerDisabled: Bool
    var urlAction: Filtered<URL, URLActionResponse>
    var sendingEvent: UIEvent?
    var sendingAction: TargetAction?
    var isNetworkActivityIndicatorVisible: Bool
    var iconBadgeNumber: Int
    var supportsShakeToEdit: Bool
    var pendingBackgroundTasks: [Session.Model.BackgroundTask]
    var minimumBackgroundFetchInterval: FetchInterval
    var typesRegisteredForRemoteNotifications: [UIRemoteNotificationType]
    var presentedLocalNotification: UILocalNotification?
    var scheduledLocalNotifications: [UILocalNotification]
    var registeredUserNotificationSettings: UIUserNotificationSettings?
    var isReceivingRemoteControlEvents: Bool
    var newsStandIconImage: UIImage?
    var shortcutItems: [ShortcutItem]
    var shouldSaveApplicationState: Filtered<NSCoder, Bool>
    var shouldRestoreApplicationState: Filtered<NSCoder, Bool>
    var shouldNotifyUserActivitiesWithTypes: [String]
    var activitiesWithAvaliableData: [NSUserActivity]
    var shouldLaunch: Bool
    var URL: Filtered<Session.Model.URLLaunch, URL>
    var extensionPointIdentifier: Filtered<UIApplicationExtensionPointIdentifier, UIApplicationExtensionPointIdentifier>
    var interfaceOrientations: [Filtered<UIWindow, WindowResponse>]
    var viewControllerRestoration: Filtered<RestorationQuery, RestorationResponse>
    
    enum URLLaunch {
      case ios4(url: URL, app: String?, annotation: Any)
      case ios9(url: URL, options: [UIApplicationOpenURLOptionsKey : Any])
    }
    enum Notification {
      case local(value: UILocalNotification)
      case remote(value: [AnyHashable: Any])
    }
    enum ActionID {
      case some( String)
      case defaultAction
    }
    enum ActionRemote {
      case ios8(
        id: ActionID,
        userInfo: [AnyHashable: Any],
        completion: () -> Void
      )
      case ios9(
        id: ActionID,
        userInfo: [AnyHashable: Any],
        responseInfo: [AnyHashable: Any],
        completion: () -> Void
      )
    }
    enum ActionLocal {
      case ios8(ActionID, UILocalNotification, () -> Void)
      case ios9(ActionID, UILocalNotification, [AnyHashable: Any], () -> Void)
    }
    struct URLActionResponse {
      let url: URL
      let success: Bool
    }
    struct BackgroundURLSessionAction {
      var identifier: String
      var completion: (Void) -> Void
    }
    struct FetchAction {
      var hash: Int
      var completion: (UIBackgroundFetchResult) -> Void
    }
    struct ShortcutItem {
      var value: UIApplicationShortcutItem
      var action: AsyncAction<Action>
      struct Action {
        var id: UIApplicationShortcutItem
        var completion: (Bool) -> Void
      }
    }
    struct RemoteNofiticationAction {
      var notification: [AnyHashable : Any]
      var completion: (UIBackgroundFetchResult) -> Void
    }
    struct WatchKitExtensionRequest {
      var userInfo: [AnyHashable: Any]?
      var reply: ([AnyHashable : Any]?) -> Void
    }
    enum BackgroundURLSessionDataAvailability {
      case none
      case some (String, (Void) -> Void)
      case ending ((Void) -> Void)
    }
    enum UserActivityState {
      case idle
      case willContinue(String)
      case isContinuing(NSUserActivity)
      case didContinue(NSUserActivity)
      case didFail(String, Error)
    }
    enum StateRestoration {
      case idle
      case willEncode(NSCoder)
      case didDecode(NSCoder)
    }
    enum State {
      case awaitingLaunch
      case launched([UIApplicationLaunchOptionsKey: Any]?)
      case active
      case resigned
      case terminated
    }
    
    // IDEA: prevent transitioning between enum states with pattern matched conversion methods and private intializer
    
    struct WindowResponse {
      var window: UIWindow
      var orientation: UIInterfaceOrientationMask
    }
    struct RestorationQuery {
      var identifier: String
      var coder: NSCoder
    }
    
    struct RestorationResponse {
      var identifier: String
      var view: UIViewController
    }
    
    enum FetchInterval {
      case minimum
      case some(TimeInterval)
      case never
    }
    struct BackgroundTask {
      var name: String
      var expiration: ((Void) -> Void)?
    }
    struct TargetAction {
      var action: Selector
      var target: Any?
      var sender: Any?
      var event: UIEvent?
    }
  }
}

extension Session.Model {
  static var empty: Session.Model { return
    Session.Model(
      backgroundURLSessionAction: .idle,
      fetch: .idle,
      remoteAction: .idle,
      localAction: .idle,
//      cloudKitShare: nil,
      userActivityState: .idle,
      stateRestoration: .idle,
      userActivityContinuation: .idle,
      watchKitExtensionRequest: .idle,
      localNotification: nil,
      remoteNotification: .idle,
      notificationSettings: nil,
      isObservingSignificantTimeChange: false,
      isExperiencingMemoryWarning: false,
      state: .none(.awaitingLaunch),
      statusBarFrame: .none(.zero),
      isProtectedDataAvailable: .none(false),
      deviceToken: .none,
      statusBarOrientation: .none(.unknown),
      runningBackgroundTasksIdentifiers: [],
      isExperiencingHealthAuthorizationRequest: false,
      isIgnoringUserEvents: false,
      isIdleTimerDisabled: false,
      urlAction: .idle,
      sendingEvent: nil,
      sendingAction: nil,
      isNetworkActivityIndicatorVisible: false,
      iconBadgeNumber: 0,
      supportsShakeToEdit: true,
      pendingBackgroundTasks: [],
      minimumBackgroundFetchInterval: .never,
      typesRegisteredForRemoteNotifications: [],
      presentedLocalNotification: nil,
      scheduledLocalNotifications: [],
      registeredUserNotificationSettings: nil,
      isReceivingRemoteControlEvents: true,
      newsStandIconImage: nil,
      shortcutItems: [],
      shouldSaveApplicationState: .allowing(true),
      shouldRestoreApplicationState: .allowing(true),
      shouldNotifyUserActivitiesWithTypes: [],
      activitiesWithAvaliableData: [],
      shouldLaunch: true,
      URL: .idle,
      extensionPointIdentifier: .idle,
      interfaceOrientations: [],
      viewControllerRestoration: .idle
    )
  }
}

extension Session.Model.State: Equatable {
  static func ==(left: Session.Model.State, right: Session.Model.State) -> Bool {
    switch (left, right) {
    case (.awaitingLaunch, .awaitingLaunch): return
      true
    case (.launched(let a), .launched(let b)): return
      a.map { NSDictionary(dictionary: $0) } ==
      b.map { NSDictionary(dictionary: $0) }
    case (.active, .active): return
      true
    case (.resigned, .resigned): return
      true
    case (.terminated, .terminated): return
      true
    default: return
      false
    }
  }
}

extension Session.Model.BackgroundURLSessionAction: Equatable {
  static func ==(
    left: Session.Model.BackgroundURLSessionAction,
    right: Session.Model.BackgroundURLSessionAction
  ) -> Bool {
    return left.identifier == right.identifier
  }
}

extension Session.Model.URLLaunch: Equatable {
  static func ==(left: Session.Model.URLLaunch, right: Session.Model.URLLaunch) -> Bool {
    switch (left, right) {
    case (.ios4(let a), .ios4(let b)): return
      a.url == b.url &&
      a.app == b.app &&
      (a.annotation as? NSObject) == (b.annotation as? NSObject)
    case (.ios9(let a), .ios9(let b)): return
      a.url == b.url &&
      NSDictionary(dictionary: a.options) == NSDictionary(dictionary: b.options)
    default: return
      false
    }
  }
}

extension AsyncAction: Equatable {
  static func ==(left: AsyncAction, right: AsyncAction) -> Bool {
    switch (left, right) {
    case (.idle, .idle): return true
    case (.progressing(let a), .progressing(let b)): return a == b
    case (.complete(let a), .complete(let b)): return a == b
    default: return false
    }
  }
}

extension Session.Model.RestorationQuery: Equatable {
  static func ==(left: Session.Model.RestorationQuery, right: Session.Model.RestorationQuery) -> Bool { return
    left.identifier == right.identifier &&
    left.coder == right.coder
  }
}

extension Session.Model.RestorationResponse: Equatable {
  static func ==(left: Session.Model.RestorationResponse, right: Session.Model.RestorationResponse) -> Bool { return
    left.identifier == right.identifier &&
    left.view == right.view
  }
}

class Session: NSObject, UIApplicationDelegate {
  
  init(_ input: Model) {
    model = input
    output = BehaviorSubject<Model>(value: input)
  }
  
  static let shared = Session(.empty)
  fileprivate var disposable: Disposable?
  fileprivate let output: BehaviorSubject<Model>
  fileprivate var model: Model {
    didSet {
      if model.isIgnoringUserEvents != oldValue.isIgnoringUserEvents {
        if model.isIgnoringUserEvents {
          UIApplication.shared.beginIgnoringInteractionEvents()
        } else {
          UIApplication.shared.endIgnoringInteractionEvents()
        }
      }
      
      UIApplication.shared.isIdleTimerDisabled = model.isIdleTimerDisabled
      
      if case .considering(let url) = model.urlAction {
        let didOpen = UIApplication.shared.openURL(url)
        var edit = model
        edit.urlAction = .allowing(
          Session.Model.URLActionResponse(url: url, success: didOpen)
        )
        output.on(.next(edit))
        // Model may change in response to output. Reevaluate before sending further output.
        if case .allowing(let x) = model.urlAction, x.url == url {
          var edit = model
          edit.urlAction = .idle
          output.on(.next(edit))
        }
      }
      
      if let new = model.sendingEvent {
        UIApplication.shared.sendEvent(new)
        var edit = model
        edit.sendingEvent = nil
        output.on(.next(edit))
      }
      
      if let new = model.sendingAction {
        UIApplication.shared.sendAction(
          new.action,
          to: new.target,
          from: new.sender,
          for: new.event
        )
      }
      
      UIApplication.shared.isNetworkActivityIndicatorVisible = model.isNetworkActivityIndicatorVisible
      UIApplication.shared.applicationIconBadgeNumber = model.iconBadgeNumber
      UIApplication.shared.applicationSupportsShakeToEdit = model.supportsShakeToEdit
      
      Session.additions(
        new: model.pendingBackgroundTasks,
        old: oldValue.pendingBackgroundTasks
      ).forEach {
        // need to add these ID to output model's running tasks
        let ID = UIApplication.shared.beginBackgroundTask(
          withName: $0.name,
          expirationHandler: $0.expiration
        )
        var edit = model
        edit.runningBackgroundTasksIdentifiers += [ID]
        output.on(.next(edit))
        // don't have event currently. reconsider output schema.
      }
      
      Session.deletions(
        new: model.runningBackgroundTasksIdentifiers,
        old: oldValue.runningBackgroundTasksIdentifiers
      ).forEach {
        UIApplication.shared.endBackgroundTask($0)
      }
      
      switch model.minimumBackgroundFetchInterval {
      case .minimum:
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
      case .never:
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalNever)
      case .some(let value):
        UIApplication.shared.setMinimumBackgroundFetchInterval(value)
      }
      
      let deletionsTypesRegistered = Changeset(
        source: oldValue.typesRegisteredForRemoteNotifications,
        target: model.typesRegisteredForRemoteNotifications
      ).edits
      
      if deletionsTypesRegistered.count != 0 {
        UIApplication.shared.unregisterForRemoteNotifications()
        model.typesRegisteredForRemoteNotifications.forEach {
          UIApplication.shared.registerForRemoteNotifications(matching: $0)
        }
      }
      
      if
      let new = model.presentedLocalNotification,
      oldValue.presentedLocalNotification != new {
        UIApplication.shared.presentLocalNotificationNow(new)
      }
      
      Session.additions(
        new: model.scheduledLocalNotifications,
        old: oldValue.scheduledLocalNotifications
      ).forEach {
          UIApplication.shared.scheduleLocalNotification($0)
      }
      
      Session.deletions(
        new: model.scheduledLocalNotifications,
        old: oldValue.scheduledLocalNotifications
      ).forEach {
          UIApplication.shared.cancelLocalNotification($0)
      }
      
      if
        let new = model.registeredUserNotificationSettings,
        oldValue.registeredUserNotificationSettings != new {
        UIApplication.shared.registerUserNotificationSettings(new)
      }
      
      if oldValue.isReceivingRemoteControlEvents != model.isReceivingRemoteControlEvents {
        model.isReceivingRemoteControlEvents
          ? UIApplication.shared.beginReceivingRemoteControlEvents()
          : UIApplication.shared.endReceivingRemoteControlEvents()
      }
      
      if oldValue.newsStandIconImage != model.newsStandIconImage {
        UIApplication.shared.setNewsstandIconImage(model.newsStandIconImage)
      }
      
      UIApplication.shared.shortcutItems = model.shortcutItems.map { $0.value }
      
      let change = Changeset(source: oldValue.shortcutItems, target: model.shortcutItems)
        
      change
      .edits
      .flatMap { completionHandler(type: .deletion, edit: $0) }
      .forEach { $0(false) }

      change
      .edits
      .flatMap { completionHandler(type: .substitution, edit: $0) }
      .forEach { $0(true) }

    }
  }
  
  func rendered(_ input: Observable<Model>) -> Observable<Model> { return
    input.flatMap { model in
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

  func application(
    _ application: UIApplication,
    willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil
  ) -> Bool {
    var edit = model
    edit.state = .will(.launched(launchOptions))
    output.on(.next(edit))
    return model.shouldLaunch == true
  }

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil
  ) -> Bool {
    var edit = model
    edit.state = .did(.launched(launchOptions))
    output.on(.next(edit))
    return model.shouldLaunch == true
  }

  func applicationDidBecomeActive(_ application: UIApplication) {
    var edit = model
    edit.state = .did(.active)
    output.on(.next(edit))
  }

  func applicationWillResignActive(_ application: UIApplication) {
    var edit = model
    edit.state = .will(.resigned)
    output.on(.next(edit))
  }

  func application(
    _ application: UIApplication,
    open url: URL,
    sourceApplication: String?,
    annotation: Any
  ) -> Bool {
    var edit = model
    edit.URL = .considering(
      .ios4(
        url: url,
        app: sourceApplication,
        annotation: annotation
      )
    )
    output.on(.next(edit))
    if case .allowing(let allowed) = model.URL {
      return url == allowed
    } else {
      return false
    }
  }

  func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplicationOpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    var edit = model
    edit.URL = .considering(.ios9(url: url, options: options))
    output.on(.next(edit))
    if case .allowing(let allowed) = model.URL {
      return url == allowed
    } else {
      return false
    }
  }

  func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
    var edit = model
    edit.isExperiencingMemoryWarning = true
    output.on(.next(edit))
    edit.isExperiencingMemoryWarning = false
    output.on(.next(edit))
  }

  func applicationWillTerminate(_ application: UIApplication) {
    var edit = model
    edit.state = Change.will(.terminated)
    output.on(.next(edit))
  }

  func applicationSignificantTimeChange(_ application: UIApplication) {
    var edit = model
    edit.isObservingSignificantTimeChange = true
    output.on(.next(edit))
    edit.isObservingSignificantTimeChange = false
    output.on(.next(edit))
  }

  func application(
    _ application: UIApplication,
    willChangeStatusBarOrientation newStatusBarOrientation: UIInterfaceOrientation,
    duration: TimeInterval
  ) {
    var edit = model
    edit.statusBarOrientation = .will(newStatusBarOrientation)
    output.on(.next(edit))
  }

  func application(
    _ application: UIApplication,
    didChangeStatusBarOrientation oldStatusBarOrientation: UIInterfaceOrientation
  ) {
    var edit = model
    edit.statusBarOrientation = .did(oldStatusBarOrientation)
    output.on(.next(edit))
  }

  func application(
    _ application: UIApplication,
    willChangeStatusBarFrame new: CGRect
  ) {
    var edit = model
    edit.statusBarFrame = Change.will(new)
    output.on(.next(edit))
  }

  func application(
    _ application: UIApplication,
    didChangeStatusBarFrame old: CGRect
  ) {
    var edit = model
    edit.statusBarFrame = Change.did(UIApplication.shared.statusBarFrame)
    output.on(.next(edit))
  }

  func application(
    _ application: UIApplication,
    didRegister notificationSettings: UIUserNotificationSettings
  ) {
    var edit = model
    edit.registeredUserNotificationSettings = notificationSettings
    output.on(.next(edit))
  }

  func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken token: Data
  ) {
    var edit = model
    edit.deviceToken = .some(token)
    output.on(.next(edit))
  }

  func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    var edit = model
    edit.deviceToken = .error(error)
    output.on(.next(edit))
  }

  func application(
    _ application: UIApplication,
    didReceive notification: UILocalNotification
  ) {
    var edit = model
    edit.localNotification = notification
    output.on(.next(edit))
  }

  func application(
    _ application: UIApplication,
    handleActionWithIdentifier identifier: String?,
    for notification: UILocalNotification,
    completionHandler: @escaping () -> Void
  ) {
    var edit = model
    edit.localAction = .progressing(
      .ios8(
        identifier.map {.some( $0)} ?? .defaultAction,
        notification,
        completionHandler
      )
    )
    output.on(.next(edit))
  }

  func application(
    _ application: UIApplication,
    handleActionWithIdentifier identifier: String?,
    forRemoteNotification userInfo: [AnyHashable : Any],
    withResponseInfo responseInfo: [AnyHashable : Any],
    completionHandler: @escaping () -> Void
  ) {
    var edit = model
    edit.remoteAction = .progressing(
      .ios9(
        id: identifier.map {.some($0)} ?? .defaultAction,
        userInfo: userInfo,
        responseInfo: responseInfo,
        completion: completionHandler
      )
    )
    output.on(.next(edit))
  }

  func application(
    _ application: UIApplication,
    handleActionWithIdentifier identifier: String?,
    forRemoteNotification userInfo: [AnyHashable : Any],
    completionHandler: @escaping () -> Void
  ) {
    var edit = model
    edit.remoteAction = .progressing(
      .ios8(
        id: identifier.map {.some( $0)} ?? .defaultAction,
        userInfo: userInfo,
        completion: completionHandler
      )
    )
    output.on(.next(edit))
  }

  func application(
    _ application: UIApplication,
    handleActionWithIdentifier identifier: String?,
    for notification: UILocalNotification,
    withResponseInfo responseInfo: [AnyHashable : Any],
    completionHandler: @escaping () -> Void
  ) {
    var edit = model
    edit.localAction = .progressing(
      .ios9(
        identifier.map {.some( $0)} ?? .defaultAction,
        notification,
        responseInfo,
        completionHandler
      )
    )
    output.on(.next(edit))
  }

  func application(
    _ application: UIApplication,
    didReceiveRemoteNotification info: [AnyHashable : Any],
    fetchCompletionHandler completion: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    var edit = model
    edit.remoteNotification = .progressing(
      Session.Model.RemoteNofiticationAction(
        notification: info,
        completion: completion
      )
    )
    output.on(.next(edit))
  }

  func application(
    _ application: UIApplication,
    performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult
  ) -> Void) {
    var edit = model
    edit.fetch = .progressing(
      Session.Model.FetchAction(
        hash: Date().hashValue,
        completion: completionHandler
      )
    )
    output.on(.next(edit))
  }

  func application(
    _ application: UIApplication,
    performActionFor shortcutItem: UIApplicationShortcutItem,
    completionHandler: @escaping (Bool) -> Void
  ) {
    var edit = model
    edit.shortcutItems = edit.shortcutItems.map {
      if $0.value.type == shortcutItem.type {
        return Session.Model.ShortcutItem(
          value: shortcutItem,
          action: .progressing(
            Session.Model.ShortcutItem.Action(
              id: shortcutItem,
              completion: completionHandler
            )
          )
        )
      } else {
        return $0
      }
    }
    output.on(.next(edit))
  }

  func application(
    _ application: UIApplication,
    handleEventsForBackgroundURLSession identifier: String,
    completionHandler: @escaping () -> Void
  ) {
    var edit = model
    edit.backgroundURLSessionAction = .progressing(
      Session.Model.BackgroundURLSessionAction(
        identifier: identifier,
        completion: completionHandler
      )
    )
    output.on(.next(edit))
  }

  func application(
    _ application: UIApplication,
    handleWatchKitExtensionRequest userInfo: [AnyHashable : Any]?,
    reply: @escaping ([AnyHashable : Any]?) -> Void
  ) {
    var edit = model
    edit.watchKitExtensionRequest = .progressing(
      Session.Model.WatchKitExtensionRequest(
        userInfo: userInfo,
        reply: reply
      )
    )
    output.on(.next(edit))
  }

  func applicationShouldRequestHealthAuthorization(_ application: UIApplication) {
    var edit = model
    edit.isExperiencingHealthAuthorizationRequest = true
    output.on(.next(edit))
    edit.isExperiencingHealthAuthorizationRequest = false
    output.on(.next(edit))
  }

  func applicationDidEnterBackground(_ application: UIApplication) {
    var edit = model
    edit.state = .did(.resigned)
    output.on(.next(edit))
  }

  func applicationWillEnterForeground(_ application: UIApplication) {
    var edit = model
    edit.state = .will(.active)
    output.on(.next(edit))
  }

  func applicationProtectedDataWillBecomeUnavailable(_ application: UIApplication) {
    var edit = model
    edit.isProtectedDataAvailable = .will(false)
    output.on(.next(edit))
  }

  func applicationProtectedDataDidBecomeAvailable(_ application: UIApplication) {
    var edit = model
    edit.isProtectedDataAvailable = .did(true)
    output.on(.next(edit))
  }

  func application(
    _ application: UIApplication,
    supportedInterfaceOrientationsFor window: UIWindow?
  ) -> UIInterfaceOrientationMask {
    if let window = window {
      var edit = model
      edit.interfaceOrientations += [.considering(window)]
      output.on(.next(edit))
      return self.model.interfaceOrientations
        .flatMap { $0.allowed() }
        .filter { $0.window == window }
        .first
        .map { $0.orientation }
        ?? .allButUpsideDown
    } else {
      return .allButUpsideDown
    }
  }

  func application(
    _ application: UIApplication,
    shouldAllowExtensionPointIdentifier ID: UIApplicationExtensionPointIdentifier
  ) -> Bool {
    var edit = model
    edit.extensionPointIdentifier = .considering(ID)
    output.on(.next(edit))
    if case .allowing(let allowed) = model.extensionPointIdentifier {
      return ID == allowed
    } else {
      return false
    }
  }

  func application(
    _ application: UIApplication,
    viewControllerWithRestorationIdentifierPath components: [Any],
    coder: NSCoder
  ) -> UIViewController? {
    if let component = components.last as? String {
      var edit = model
      edit.viewControllerRestoration = .considering(
        Session.Model.RestorationQuery(
          identifier: component,
          coder: coder
        )
      )
      output.on(.next(edit))
      if case .allowing(let allowed) = model.viewControllerRestoration, allowed.identifier == component {
        return allowed.view
      } else {
        return nil
      }
    } else {
      return nil
    }
  }

  func application(
    _ application: UIApplication,
    shouldSaveApplicationState coder: NSCoder
  ) -> Bool {
    var edit = model
    edit.shouldSaveApplicationState = .considering(coder)
    output.on(.next(edit))
    return model.shouldSaveApplicationState == .allowing(true)
  }

  func application(
    _ application: UIApplication,
    shouldRestoreApplicationState coder: NSCoder
  ) -> Bool {
    var edit = model
    edit.shouldRestoreApplicationState = .considering(coder)
    output.on(.next(edit))
    return model.shouldRestoreApplicationState.allowed() == true
  }

  func application(
    _ application: UIApplication,
    willEncodeRestorableStateWith coder: NSCoder
  ) {
    var edit = model
    edit.stateRestoration = .willEncode(coder)
    output.on(.next(edit))
  }

  func application(
    _ application: UIApplication,
    didDecodeRestorableStateWith coder: NSCoder
  ) {
    var edit = model
    edit.stateRestoration = .didDecode(coder)
    output.on(.next(edit))
  }

  func application(
    _ application: UIApplication,
    willContinueUserActivityWithType type: String
  ) -> Bool {
    var edit = model
    edit.userActivityState = .willContinue(type)
    output.on(.next(edit))
    return model.shouldNotifyUserActivitiesWithTypes.contains(type) == true
  }

  func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([Any]?) -> Void
  ) -> Bool {
    var edit = model
    edit.userActivityState = .isContinuing(userActivity)
    output.on(.next(edit))
    return model.activitiesWithAvaliableData.contains(userActivity) == true
  }

  func application(
    _ application: UIApplication,
    didFailToContinueUserActivityWithType userActivityType: String,
    error: Error
  ) {
    var edit = model
    edit.userActivityState = .didFail(userActivityType, error)
    output.on(.next(edit))
  }

  func application(
    _ application: UIApplication,
    didUpdate userActivity: NSUserActivity
  ) {
    var edit = model
    edit.userActivityState = .didContinue(userActivity)
    output.on(.next(edit))
  }

//  func application(
//    _ application: UIApplication,
//    userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShareMetadata
//    ) {
//    if var model = model {
//      model.cloudKitShare = cloudKitShareMetadata
//      output.on(.next(model))
//    }
//  }
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

extension Session.Model.ActionID: Equatable {
  static func ==(
    left: Session.Model.ActionID,
    right: Session.Model.ActionID
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

extension Session.Model.ActionRemote: Equatable {
  static func ==(
    left: Session.Model.ActionRemote,
    right: Session.Model.ActionRemote
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

extension Session.Model.ActionLocal: Equatable {
  static func ==(
    left: Session.Model.ActionLocal,
    right: Session.Model.ActionLocal
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

extension Session.Model.Notification: Equatable {
  static func ==(
    left: Session.Model.Notification,
    right: Session.Model.Notification
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

extension Session.Model: Equatable {
  static func == (left: Session.Model, right: Session.Model) -> Bool { return
    left.backgroundURLSessionAction == right.backgroundURLSessionAction &&
    left.fetch == right.fetch &&
    left.remoteAction == right.remoteAction &&
    left.localAction == right.localAction &&
//    left.cloudKitShare == right.cloudKitShare &&
    left.userActivityState == right.userActivityState &&
    left.stateRestoration == right.stateRestoration &&
    left.userActivityContinuation == right.userActivityContinuation &&
    left.watchKitExtensionRequest == right.watchKitExtensionRequest &&
    left.localNotification == right.localNotification &&
    left.remoteNotification == right.remoteNotification &&
    left.notificationSettings == right.notificationSettings &&
    left.isObservingSignificantTimeChange == right.isObservingSignificantTimeChange &&
    left.isExperiencingMemoryWarning == right.isExperiencingMemoryWarning &&
    left.state == right.state &&
    left.statusBarFrame == right.statusBarFrame &&
    left.isProtectedDataAvailable == right.isProtectedDataAvailable &&
    left.deviceToken == right.deviceToken &&
    left.statusBarOrientation == right.statusBarOrientation &&
    left.runningBackgroundTasksIdentifiers == right.runningBackgroundTasksIdentifiers &&
    left.isExperiencingHealthAuthorizationRequest == right.isExperiencingHealthAuthorizationRequest &&
    left.isIgnoringUserEvents == right.isIgnoringUserEvents &&
    left.isIdleTimerDisabled == right.isIdleTimerDisabled &&
    left.urlAction == right.urlAction &&
    left.sendingEvent == right.sendingEvent &&
    left.sendingAction == right.sendingAction &&
    left.isNetworkActivityIndicatorVisible == right.isNetworkActivityIndicatorVisible &&
    left.iconBadgeNumber == right.iconBadgeNumber &&
    left.supportsShakeToEdit == right.supportsShakeToEdit &&
    left.pendingBackgroundTasks == right.pendingBackgroundTasks &&
    left.minimumBackgroundFetchInterval == right.minimumBackgroundFetchInterval &&
    left.typesRegisteredForRemoteNotifications == right.typesRegisteredForRemoteNotifications &&
    left.presentedLocalNotification == right.presentedLocalNotification &&
    left.scheduledLocalNotifications == right.scheduledLocalNotifications &&
    left.registeredUserNotificationSettings == right.registeredUserNotificationSettings &&
    left.isReceivingRemoteControlEvents == right.isReceivingRemoteControlEvents &&
    left.newsStandIconImage == right.newsStandIconImage &&
    left.shortcutItems == right.shortcutItems &&
    left.shouldSaveApplicationState == right.shouldSaveApplicationState &&
    left.shouldRestoreApplicationState == right.shouldRestoreApplicationState &&
    left.shouldNotifyUserActivitiesWithTypes == right.shouldNotifyUserActivitiesWithTypes &&
    left.activitiesWithAvaliableData == right.activitiesWithAvaliableData &&
    left.shouldLaunch == right.shouldLaunch &&
    left.URL == right.URL &&
    left.extensionPointIdentifier == right.extensionPointIdentifier &&
    left.interfaceOrientations == right.interfaceOrientations &&
    left.viewControllerRestoration == right.viewControllerRestoration
  }
}

extension Session.Model.FetchAction: Equatable {
  static func == (
    lhs: Session.Model.FetchAction,
    rhs: Session.Model.FetchAction
  ) -> Bool { return
    lhs.hash == rhs.hash
  }
}

extension Session.Model.RemoteNofiticationAction: Equatable {
  static func == (
    lhs: Session.Model.RemoteNofiticationAction,
    rhs: Session.Model.RemoteNofiticationAction
  ) -> Bool { return
    NSDictionary(dictionary: lhs.notification) ==
    NSDictionary(dictionary: rhs.notification)
  }
}

extension Session.Model.UserActivityState: Equatable {
  static func ==(
    left: Session.Model.UserActivityState,
    right: Session.Model.UserActivityState
  ) -> Bool {
    switch (left, right) {
    case (.idle, .idle): return true
    case (.willContinue(let a), .willContinue(let b)): return a == b
    case (.isContinuing(let a), .isContinuing(let b)): return a == b
    case (.didContinue(let a), .didContinue(let b)): return a == b
    case (.didFail(let a), .didFail(let b)): return a.0 == b.0 // Need to compare errors
    default: return false
    }
  }
}

extension Session.Model.StateRestoration: Equatable {
  static func == (
    left: Session.Model.StateRestoration,
    right: Session.Model.StateRestoration
  ) -> Bool {
    switch (left, right) {
    case (.idle, .idle): return true
    case (.willEncode(let a), .willEncode(let b)): return a == b
    case (.didDecode(let a), didDecode(let b)): return a == b
    default: return false
    }
  }
}

extension Session.Model.WatchKitExtensionRequest: Equatable {
  static func ==(
    left: Session.Model.WatchKitExtensionRequest,
    right: Session.Model.WatchKitExtensionRequest
  ) -> Bool { return
    left.userInfo.map { NSDictionary(dictionary: $0) } ==
    right.userInfo.map { NSDictionary(dictionary: $0) }
  }
}

extension Session.Model.WindowResponse: Equatable {
  static func ==(left: Session.Model.WindowResponse, right: Session.Model.WindowResponse) -> Bool { return
    left.window == right.window &&
    left.orientation == left.orientation
  }
}

extension Result: Equatable {
  static func ==(left: Result, right: Result) -> Bool {
    switch (left, right) {
    case (.none, .none): return true
    case (.some(let a), .some(let b)): return a == b
    case (.error, .error): return true // Needs to compare errors
    default: return false
    }
  }
}

extension Session.Model.ShortcutItem.Action: Equatable {
  static func ==(
    left: Session.Model.ShortcutItem.Action,
    right: Session.Model.ShortcutItem.Action
  ) -> Bool { return
    left.id == right.id
  }
}

extension Session.Model.ShortcutItem: Equatable {
  static func ==(
    left: Session.Model.ShortcutItem,
    right: Session.Model.ShortcutItem
  ) -> Bool { return
    left.value == right.value &&
    left.action == right.action
  }
}

extension Edit {
  func possible(_ input: EditOperation) -> Edit? { return
    input == operation ? self : nil
  }
}

extension EditOperation: Equatable {
  public static func ==(left: EditOperation, right: EditOperation) -> Bool {
    switch (left, right) {
    case (.insertion, .insertion): return true
    case (.deletion, .deletion): return true
    case (.substitution, .substitution): return true
    case (.move(let a), .move(let b)): return a == b
    default: return false
    }
  }
}

extension Session.Model.ShortcutItem: CustomDebugStringConvertible {
  var debugDescription: String { return
    value.type + " " + String(describing: action)
  }
}

extension AsyncAction: CustomDebugStringConvertible {
  var debugDescription: String {
    switch self {
    case .complete: return ".complete"
    case .idle: return ".idle"
    case .progressing: return ".progressing"
    }
  }
}

extension Session.Model.URLActionResponse: Equatable {
  static func ==(left: Session.Model.URLActionResponse, right: Session.Model.URLActionResponse) -> Bool { return
    left.url == right.url &&
    left.success == right.success
  }
}

func completionHandler(
  type: EditOperation,
  edit: Edit<Session.Model.ShortcutItem>
  ) -> ((Bool) -> Void)? {
  if let d = edit.possible(type), case .progressing(let a) = d.value.action {
    return a.completion
  } else {
    return nil
  }
}
