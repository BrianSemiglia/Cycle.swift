//
//  Session.swift
//  Cycle
//
//  Created by Brian Semiglia on 1/26/17.
//  Copyright © 2017 Brian Semiglia. All rights reserved.
//

import Foundation
import RxSwift
import Changeset

class Session: NSObject, UIApplicationDelegate {
  
  struct Model {
    var backgroundURLSessions: Set<BackgroundURLSessionAction>
    var fetch: BackgroundFetch
    var remoteAction: AsyncAction<ActionRemote>
    var localAction: AsyncAction<ActionLocal>
    var userActivityState: UserActivityState
    var stateRestoration: StateRestoration
    var userActivityContinuation: UserActivityState
    var watchKitExtensionRequest: AsyncAction<WatchKitExtensionRequest>
    var localNotification: UILocalNotification?
    var remoteNotifications: [RemoteNofitication]
    var notificationSettings: UIUserNotificationSettings?
    var isObservingSignificantTimeChange: Bool
    var isExperiencingMemoryWarning: Bool
    var state: Change<State>
    var statusBarFrame: Change<CGRect>
    var isProtectedDataAvailable: Change<Bool>
    var remoteNotificationRegistration: RemoteNotificationRegistration
    var statusBarOrientation: Change<UIInterfaceOrientation>
    var backgroundTasks: Set<BackgroundTask>
    var isExperiencingHealthAuthorizationRequest: Bool
    var isIgnoringUserEvents: Bool
    var isIdleTimerDisabled: Bool
    var urlActionOutgoing: URLActionOutgoing
    var sendingEvent: UIEvent?
    var targetAction: TartgetActionProcess
    var isNetworkActivityIndicatorVisible: Bool
    var iconBadgeNumber: Int
    var supportsShakeToEdit: Bool
    var presentedLocalNotification: UILocalNotification?
    var scheduledLocalNotifications: [UILocalNotification]
    var registeredUserNotificationSettings: UIUserNotificationSettings?
    var isReceivingRemoteControlEvents: Bool
    var newsStandIconImage: UIImage?
    var shortcutActions: [ShortcutAction]
    var shouldSaveApplicationState: Filtered<NSCoder, Bool>
    var shouldRestoreApplicationState: Filtered<NSCoder, Bool>
    var shouldLaunch: Bool
    var urlActionIncoming: Filtered<Session.Model.URLLaunch, URL>
    var extensionPointIdentifier: Filtered<UIApplicationExtensionPointIdentifier, UIApplicationExtensionPointIdentifier>
    var interfaceOrientations: [Filtered<UIWindow, WindowResponse>]
    var viewControllerRestoration: Filtered<RestorationQuery, RestorationResponse>
    
    enum RemoteNotificationRegistration {
      case none
      case attempting
      case some(token: Data)
      case error(Error)
    }
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
    enum URLActionOutgoing {
      case idle
      case attempting(URL)
      case opening(URL)
      case failing(URL)
    }
    struct BackgroundURLSessionAction {
      let id: String // Readonly
      let completion: (Void) -> Void // Readonly
      var state: State
      enum State {
        case progressing // Readonly
        case complete
      }
    }
    struct BackgroundFetch {
      var minimumInterval: Interval
      var state: State
      enum State {
        case idle // Readonly
        case progressing((UIBackgroundFetchResult) -> Void) // Readonly
        case complete(UIBackgroundFetchResult, (UIBackgroundFetchResult) -> Void)
      }
      enum Interval {
        case minimum
        case some(TimeInterval)
        case never
      }
    }
    struct ShortcutAction {
      var item: UIApplicationShortcutItem
      var state: State
      enum State {
        case idle
        case progressing((Bool) -> Void) // Readonly
        case complete(Bool, (Bool) -> Void)
      }
    }
    struct RemoteNofitication {
      var notification: [AnyHashable : Any] // Readonly
      var state: State
      enum State {
        case progressing((UIBackgroundFetchResult) -> Void) // Readonly
        case complete(UIBackgroundFetchResult, (UIBackgroundFetchResult) -> Void)
      }
    }
    struct WatchKitExtensionRequest {
      var userInfo: [AnyHashable: Any]? // Readonly
      var reply: ([AnyHashable : Any]?) -> Void // Readonly
    }
    enum BackgroundURLSessionDataAvailability {
      case none // Readonly
      case some (String, (Void) -> Void) // Readonly
      case ending ((Void) -> Void)
    }
    enum UserActivityState { // Readonly
      case idle
      case willContinue(String)
      case isContinuing(NSUserActivity)
      case hasAvailableData(NSUserActivity)
      case shouldNotifyUserActivitiesWithType(String)
      case didContinue(NSUserActivity)
      case didFail(String, Error)
    }
    enum StateRestoration { // Readonly
      case idle
      case willEncode(NSCoder)
      case didDecode(NSCoder)
    }
    enum State { // Readonly
      case awaitingLaunch
      case launched([UIApplicationLaunchOptionsKey: Any]?)
      case active
      case resigned
      case terminated
    }
    
    // IDEA: prevent transitioning between certain enum states with pattern matched conversion methods and private intializer
    
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
    struct BackgroundTask {
      var name: String // Readonly
      var state: State
      enum State {
        case pending
        case progressing(UIBackgroundTaskIdentifier) // Readonly
        case complete(UIBackgroundTaskIdentifier)
        case expired // Readonly
      }
    }
    enum TartgetActionProcess {
      case idle
      case sending(TargetAction)
      case responding(TargetAction, Bool) // Readonly
    }
    struct TargetAction {
      var action: Selector
      var target: Any?
      var sender: Any?
      var event: UIEvent?
    }
  }
  
  fileprivate let application: UIApplication
  fileprivate var disposable: Disposable?
  fileprivate let output: BehaviorSubject<Model>
  fileprivate var model: Model

  init(intitial: Model, application: UIApplication) {
    self.application = application
    model = intitial
    output = BehaviorSubject<Model>(value: intitial)
  }
  
  func render(new: Model, old: Model) {
    model = new
    if model.isIgnoringUserEvents != old.isIgnoringUserEvents {
      model.isIgnoringUserEvents
        ? application.beginIgnoringInteractionEvents()
        : application.endIgnoringInteractionEvents()
    }
    
    application.isIdleTimerDisabled = model.isIdleTimerDisabled
    
    switch model.urlActionOutgoing {
    case .attempting(let url):
      model.urlActionOutgoing = .opening(url)
      DispatchQueue.main.async { self.application.openURL(url) }
    case .opening:
      model.urlActionOutgoing = .idle
    default:
      break
    }
    
    if let new = model.sendingEvent {
      application.sendEvent(new)
      model.sendingEvent = nil
    }
    
    if case .sending(let new) = model.targetAction {
      let didSend = application.sendAction(
        new.action,
        to: new.target,
        from: new.sender,
        for: new.event
      )
      model.targetAction = .responding(new, didSend)
      DispatchQueue.main.async { [weak self] in
        if let strong = self {
          if case .responding(let action, _) = strong.model.targetAction, action == new {
            strong.model.targetAction = .idle
            strong.output.on(.next(strong.model))
          }
        }
      }
    }
    
    application.isNetworkActivityIndicatorVisible = model.isNetworkActivityIndicatorVisible
    application.applicationIconBadgeNumber = model.iconBadgeNumber
    application.applicationSupportsShakeToEdit = model.supportsShakeToEdit
    
    /*
     Tasks marked in-progress are begun.
     Tasks begun are marked expired and output on expiration.
     */
    model.backgroundTasks = Set(
      Session.additions(
        new: Array(model.backgroundTasks),
        old: Array(old.backgroundTasks)
      )
      .filter {
        $0.state == .pending
      }
      .map { task in
        var ID: UIBackgroundTaskIdentifier = 0
        ID = application.beginBackgroundTask( // SIDE EFFECT!
          withName: task.name,
          expirationHandler: { [weak self] in
            if let strong = self {
              strong.application.endBackgroundTask(ID) // SIDE EFFECT!
              strong.model.backgroundTasks = Set(
                strong.model.backgroundTasks
                .filter { $0.name == task.name }
                .map {
                  var edit = $0
                  edit.state = .expired
                  return edit
                }
              )
              strong.output.on(.next(strong.model))
            }
          }
        )
        var edit = task
        edit.state = .progressing(ID)
        return edit
      }
    )
    
    /* 
     Tasks marked completed are ended.
     Tasks marked in-progress that were removed are considered canceled and are removed.
     */
    let complete = model.backgroundTasks.complete().flatMap { $0.ID }
    let deletions = Session.deletions(
      old: Array(old.backgroundTasks),
      new: Array(model.backgroundTasks)
    )
    .progressing()
    .flatMap { $0.ID }
    
    (complete + deletions).forEach {
      application.endBackgroundTask($0)
    }
    
    application.setMinimumBackgroundFetchInterval(
      model.fetch.minimumInterval.asUIApplicationBackgroundFetchInterval()
    )
    
    if
    case .complete(let result, let handler) = model.fetch.state,
    model.fetch != old.fetch {
      handler(result)
      model.fetch.state = .idle
    }
    
    if model.remoteNotificationRegistration != old.remoteNotificationRegistration {
      switch model.remoteNotificationRegistration {
      case .attempting:
        application.registerForRemoteNotifications()
      case .none:
        application.unregisterForRemoteNotifications()
      default:
        break
      }
    }
    
    Session.deletions(
      old: old.remoteNotifications,
      new: model.remoteNotifications
    )
    .flatMap { x -> ((UIBackgroundFetchResult) -> Void)? in
      if case .progressing(let a) = x.state { return a }
      else { return nil }
    }
    .forEach {
      $0(.noData)
    }
    
    model.remoteNotifications =  model.remoteNotifications.flatMap {
      if case .complete(let result, let completion) = $0.state {
        completion(result) // SIDE EFFECT!
        return nil
      } else {
        return $0
      }
    }
    
    if
    let new = model.presentedLocalNotification,
    old.presentedLocalNotification != new {
      application.presentLocalNotificationNow(new)
    }
    
    Session.additions(
      new: model.scheduledLocalNotifications,
      old: old.scheduledLocalNotifications
    )
    .forEach {
      application.scheduleLocalNotification($0)
    }
    
    Session.deletions(
      old: old.scheduledLocalNotifications,
      new: model.scheduledLocalNotifications
    )
    .forEach {
      application.cancelLocalNotification($0)
    }
    
    if
    let new = model.registeredUserNotificationSettings,
    old.registeredUserNotificationSettings != new {
      application.registerUserNotificationSettings(new)
    }
    
    if old.isReceivingRemoteControlEvents != model.isReceivingRemoteControlEvents {
      model.isReceivingRemoteControlEvents
        ? application.beginReceivingRemoteControlEvents()
        : application.endReceivingRemoteControlEvents()
    }
    
    if old.newsStandIconImage != model.newsStandIconImage {
      application.setNewsstandIconImage(model.newsStandIconImage)
    }
    
    application.shortcutItems = model.shortcutActions.map { $0.item }
    
    let shortcutActionChanges = Changeset(
      source: old.shortcutActions,
      target: model.shortcutActions
    )
    
    shortcutActionChanges
    .edits
    .forEach {
      if case .deletion = $0.operation,
         case .progressing(let handler) = $0.value.state {
        return handler(false)
      }
    }

    shortcutActionChanges
    .edits
    .forEach {
      if case .insertion = $0.operation,
         case .complete(let x) = $0.value.state {
        return x.1(x.0)
      }
    }

    Session.deletions(
      old: Array(old.backgroundURLSessions),
      new: Array(model.backgroundURLSessions)
    )
    .forEach {
      if case .progressing = $0.state {
        $0.completion()
      }
    }
    
    model.backgroundURLSessions = Set(
      model.backgroundURLSessions.flatMap {
        if case .complete = $0.state {
          $0.completion() // SIDE EFFECT!
          return nil
        } else {
          return $0
        }
      }
    )
    
    output.on(.next(model))
  }
  
  func rendered(_ input: Observable<Model>) -> Observable<Model> { return
    input.distinctUntilChanged().flatMap { model in
      Observable.create { [weak self] observer in
        if let strong = self {
          strong.render(new: model, old: strong.model)
          if strong.disposable == nil {
            strong.disposable = strong.output.distinctUntilChanged().subscribe {
              if let new = $0.element {
                observer.on(.next(new))
              }
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
    model.state = .pre(.launched(launchOptions))
    output.on(.next(model))
    return model.shouldLaunch == true
  }

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil
  ) -> Bool {
    model.state = .currently(.launched(launchOptions))
    output.on(.next(model))
    return model.shouldLaunch == true
  }

  func applicationDidBecomeActive(_ application: UIApplication) {
    model.state = .currently(.active)
    output.on(.next(model))
  }

  func applicationWillResignActive(_ application: UIApplication) {
    model.state = .pre(.resigned)
    output.on(.next(model))
  }

  func application(
    _ application: UIApplication,
    open url: URL,
    sourceApplication: String?,
    annotation: Any
  ) -> Bool {
    model.urlActionIncoming = .considering(
      .ios4(
        url: url,
        app: sourceApplication,
        annotation: annotation
      )
    )
    output.on(.next(model))
    if case .allowing(let allowed) = model.urlActionIncoming {
      return url == allowed
    } else {
      return false
    }
  }

  func application(
    _ application: UIApplication,
    open url: URL,
    options: [UIApplicationOpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    model.urlActionIncoming = .considering(.ios9(url: url, options: options))
    output.on(.next(model))
    if case .allowing(let allowed) = model.urlActionIncoming {
      return url == allowed
    } else {
      return false
    }
  }

  func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
    model.isExperiencingMemoryWarning = true
    output.on(.next(model))
    model.isExperiencingMemoryWarning = false
    output.on(.next(model))
  }

  func applicationWillTerminate(_ application: UIApplication) {
    model.state = .pre(.terminated)
    output.on(.next(model))
  }

  func applicationSignificantTimeChange(_ application: UIApplication) {
    model.isObservingSignificantTimeChange = true
    output.on(.next(model))
    model.isObservingSignificantTimeChange = false
    output.on(.next(model))
  }

  func application(
    _ application: UIApplication,
    willChangeStatusBarOrientation newStatusBarOrientation: UIInterfaceOrientation,
    duration: TimeInterval
  ) {
    model.statusBarOrientation = .pre(newStatusBarOrientation)
    output.on(.next(model))
  }

  func application(
    _ application: UIApplication,
    didChangeStatusBarOrientation oldStatusBarOrientation: UIInterfaceOrientation
  ) {
    model.statusBarOrientation = .currently(oldStatusBarOrientation)
    output.on(.next(model))
  }

  func application(
    _ application: UIApplication,
    willChangeStatusBarFrame new: CGRect
  ) {
    model.statusBarFrame = .pre(new)
    output.on(.next(model))
  }

  func application(
    _ application: UIApplication,
    didChangeStatusBarFrame old: CGRect
  ) {
    model.statusBarFrame = .currently(application.statusBarFrame)
    output.on(.next(model))
  }

  func application(
    _ application: UIApplication,
    didRegister notificationSettings: UIUserNotificationSettings
  ) {
    model.registeredUserNotificationSettings = notificationSettings
    output.on(.next(model))
  }

  func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken token: Data
  ) {
    model.remoteNotificationRegistration = .some(token: token)
    output.on(.next(model))
  }

  func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    model.remoteNotificationRegistration = .error(error)
    output.on(.next(model))
  }

  func application(
    _ application: UIApplication,
    didReceive notification: UILocalNotification
  ) {
    model.localNotification = notification
    output.on(.next(model))
  }

  func application(
    _ application: UIApplication,
    handleActionWithIdentifier identifier: String?,
    for notification: UILocalNotification,
    completionHandler: @escaping () -> Void
  ) {
    model.localAction = .progressing(
      .ios8(
        identifier.map {.some( $0)} ?? .defaultAction,
        notification,
        completionHandler
      )
    )
    output.on(.next(model))
  }

  func application(
    _ application: UIApplication,
    handleActionWithIdentifier identifier: String?,
    forRemoteNotification userInfo: [AnyHashable : Any],
    withResponseInfo responseInfo: [AnyHashable : Any],
    completionHandler: @escaping () -> Void
  ) {
    model.remoteAction = .progressing(
      .ios9(
        id: identifier.map {.some($0)} ?? .defaultAction,
        userInfo: userInfo,
        responseInfo: responseInfo,
        completion: completionHandler
      )
    )
    output.on(.next(model))
  }

  func application(
    _ application: UIApplication,
    handleActionWithIdentifier identifier: String?,
    forRemoteNotification userInfo: [AnyHashable : Any],
    completionHandler: @escaping () -> Void
  ) {
    model.remoteAction = .progressing(
      .ios8(
        id: identifier.map {.some( $0)} ?? .defaultAction,
        userInfo: userInfo,
        completion: completionHandler
      )
    )
    output.on(.next(model))
  }

  func application(
    _ application: UIApplication,
    handleActionWithIdentifier identifier: String?,
    for notification: UILocalNotification,
    withResponseInfo responseInfo: [AnyHashable : Any],
    completionHandler: @escaping () -> Void
  ) {
    model.localAction = .progressing(
      .ios9(
        identifier.map {.some( $0)} ?? .defaultAction,
        notification,
        responseInfo,
        completionHandler
      )
    )
    output.on(.next(model))
  }

  func application(
    _ application: UIApplication,
    didReceiveRemoteNotification info: [AnyHashable : Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    model.remoteNotifications += [
      Session.Model.RemoteNofitication(
        notification: info,
        state: .progressing(completionHandler)
      )
    ]
    output.on(.next(model))
  }

  func application(
    _ application: UIApplication,
    performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult
  ) -> Void) {
    model.fetch.state = .progressing(completionHandler)
    output.on(.next(model))
  }

  func application(
    _ application: UIApplication,
    performActionFor shortcutItem: UIApplicationShortcutItem,
    completionHandler: @escaping (Bool) -> Void
  ) {
    model.shortcutActions = model.shortcutActions.map {
      if $0.item.type == shortcutItem.type {
        return Session.Model.ShortcutAction(
          item: shortcutItem,
          state: .progressing(completionHandler)
        )
      } else {
        return $0
      }
    }
    output.on(.next(model))
  }

  func application(
    _ application: UIApplication,
    handleEventsForBackgroundURLSession identifier: String,
    completionHandler: @escaping () -> Void
  ) {
    model.backgroundURLSessions = Set(
      Array(model.backgroundURLSessions)
      + [
        Session.Model.BackgroundURLSessionAction(
          id: identifier,
          completion: completionHandler,
          state: .progressing
        )
      ]
    )
    output.on(.next(model))
  }

  func application(
    _ application: UIApplication,
    handleWatchKitExtensionRequest userInfo: [AnyHashable : Any]?,
    reply: @escaping ([AnyHashable : Any]?) -> Void
  ) {
    model.watchKitExtensionRequest = .progressing(
      Session.Model.WatchKitExtensionRequest(
        userInfo: userInfo,
        reply: reply
      )
    )
    output.on(.next(model))
  }

  func applicationShouldRequestHealthAuthorization(_ application: UIApplication) {
    model.isExperiencingHealthAuthorizationRequest = true
    output.on(.next(model))
    model.isExperiencingHealthAuthorizationRequest = false
    output.on(.next(model))
  }

  func applicationDidEnterBackground(_ application: UIApplication) {
    model.state = .currently(.resigned)
    output.on(.next(model))
  }

  func applicationWillEnterForeground(_ application: UIApplication) {
    model.state = .pre(.active)
    output.on(.next(model))
  }

  func applicationProtectedDataWillBecomeUnavailable(_ application: UIApplication) {
    model.isProtectedDataAvailable = .pre(false)
    output.on(.next(model))
  }

  func applicationProtectedDataDidBecomeAvailable(_ application: UIApplication) {
    model.isProtectedDataAvailable = .currently(true)
    output.on(.next(model))
  }

  func application(
    _ application: UIApplication,
    supportedInterfaceOrientationsFor window: UIWindow?
  ) -> UIInterfaceOrientationMask {
    if let window = window {
      model.interfaceOrientations += [.considering(window)]
      output.on(.next(model))
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
    model.extensionPointIdentifier = .considering(ID)
    output.on(.next(model))
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
      model.viewControllerRestoration = .considering(
        Session.Model.RestorationQuery(
          identifier: component,
          coder: coder
        )
      )
      output.on(.next(model))
      if
      case .allowing(let allowed) = model.viewControllerRestoration,
      allowed.identifier == component {
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
    model.shouldSaveApplicationState = .considering(coder)
    output.on(.next(model))
    return model.shouldSaveApplicationState == .allowing(true)
  }

  func application(
    _ application: UIApplication,
    shouldRestoreApplicationState coder: NSCoder
  ) -> Bool {
    model.shouldRestoreApplicationState = .considering(coder)
    output.on(.next(model))
    return model.shouldRestoreApplicationState.allowed() == true
  }

  func application(
    _ application: UIApplication,
    willEncodeRestorableStateWith coder: NSCoder
  ) {
    model.stateRestoration = .willEncode(coder)
    output.on(.next(model))
    model.stateRestoration = .idle
    output.on(.next(model))
  }

  func application(
    _ application: UIApplication,
    didDecodeRestorableStateWith coder: NSCoder
  ) {
    model.stateRestoration = .didDecode(coder)
    output.on(.next(model))
    model.stateRestoration = .idle
    output.on(.next(model))
  }

  func application(
    _ application: UIApplication,
    willContinueUserActivityWithType type: String
  ) -> Bool {
    model.userActivityState = .willContinue(type)
    output.on(.next(model))
    if case .shouldNotifyUserActivitiesWithType(let allowed) = model.userActivityState {
      return type == allowed
    } else {
      return false
    }
  }

  func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([Any]?) -> Void
  ) -> Bool {
    model.userActivityState = .isContinuing(userActivity)
    output.on(.next(model))
    if case .hasAvailableData(let confirmed) = model.userActivityState {
      return userActivity == confirmed
    } else {
      return true
    }
  }

  func application(
    _ application: UIApplication,
    didFailToContinueUserActivityWithType userActivityType: String,
    error: Error
  ) {
    model.userActivityState = .didFail(userActivityType, error)
    output.on(.next(model))
    model.userActivityState = .idle
    output.on(.next(model))
  }

  func application(
    _ application: UIApplication,
    didUpdate userActivity: NSUserActivity
  ) {
    model.userActivityState = .didContinue(userActivity)
    output.on(.next(model))
    model.userActivityState = .idle
    output.on(.next(model))
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

extension Session {
  static func deletions<T: Equatable>(
    old: [T]?,
    new: [T]
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
    left.backgroundURLSessions == right.backgroundURLSessions &&
    left.fetch == right.fetch &&
    left.remoteAction == right.remoteAction &&
    left.localAction == right.localAction &&
    left.userActivityState == right.userActivityState &&
    left.stateRestoration == right.stateRestoration &&
    left.userActivityContinuation == right.userActivityContinuation &&
    left.watchKitExtensionRequest == right.watchKitExtensionRequest &&
    left.localNotification == right.localNotification &&
    left.remoteNotifications == right.remoteNotifications &&
    left.notificationSettings == right.notificationSettings &&
    left.isObservingSignificantTimeChange == right.isObservingSignificantTimeChange &&
    left.isExperiencingMemoryWarning == right.isExperiencingMemoryWarning &&
    left.state == right.state &&
    left.statusBarFrame == right.statusBarFrame &&
    left.isProtectedDataAvailable == right.isProtectedDataAvailable &&
    left.remoteNotificationRegistration == right.remoteNotificationRegistration &&
    left.statusBarOrientation == right.statusBarOrientation &&
    left.backgroundTasks == right.backgroundTasks &&
    left.isExperiencingHealthAuthorizationRequest == right.isExperiencingHealthAuthorizationRequest &&
    left.isIgnoringUserEvents == right.isIgnoringUserEvents &&
    left.isIdleTimerDisabled == right.isIdleTimerDisabled &&
    left.urlActionOutgoing == right.urlActionOutgoing &&
    left.sendingEvent == right.sendingEvent &&
    left.targetAction == right.targetAction &&
    left.isNetworkActivityIndicatorVisible == right.isNetworkActivityIndicatorVisible &&
    left.iconBadgeNumber == right.iconBadgeNumber &&
    left.supportsShakeToEdit == right.supportsShakeToEdit &&
    left.presentedLocalNotification == right.presentedLocalNotification &&
    left.scheduledLocalNotifications == right.scheduledLocalNotifications &&
    left.registeredUserNotificationSettings == right.registeredUserNotificationSettings &&
    left.isReceivingRemoteControlEvents == right.isReceivingRemoteControlEvents &&
    left.newsStandIconImage == right.newsStandIconImage &&
    left.shortcutActions == right.shortcutActions &&
    left.shouldSaveApplicationState == right.shouldSaveApplicationState &&
    left.shouldRestoreApplicationState == right.shouldRestoreApplicationState &&
    left.shouldLaunch == right.shouldLaunch &&
    left.urlActionIncoming == right.urlActionIncoming &&
    left.extensionPointIdentifier == right.extensionPointIdentifier &&
    left.interfaceOrientations == right.interfaceOrientations &&
    left.viewControllerRestoration == right.viewControllerRestoration
  }
}

extension Edit {
  func possible(_ input: EditOperation) -> Edit? { return
    input == operation ? self : nil
  }
}

extension Session.Model.ShortcutAction: CustomDebugStringConvertible {
  var debugDescription: String { return
    item.type + " " + String(describing: state)
  }
}

extension AsyncAction: CustomDebugStringConvertible {
  var debugDescription: String {
    switch self {
    case .complete: return
      ".complete"
    case .idle: return
      ".idle"
    case .progressing: return
      ".progressing"
    }
  }
}

enum Change<T: Equatable> {
  case pre(T)
  case currently(T)
}

extension Change: Equatable {
  static func ==(left: Change, right: Change) -> Bool {
    switch (left, right) {
    case (.pre(let a), .pre(let b)): return
      a == b
    case (.currently(let a), .currently(let b)): return
      a == b
    default: return
      false
    }
  }
}

enum Filtered<T: Equatable, U: Equatable> {
  case idle
  case considering(T)
  case allowing(U)
  
  func allowed() -> U? {
    switch self {
    case .allowing(let a): return
      a
    default: return
      nil
    }
  }
}

extension AsyncAction {
  func isProgressing() -> Bool {
    switch self {
    case .progressing: return
      true
    default: return
      false
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

extension Session.Model {
  static var empty: Session.Model { return
    Session.Model(
      backgroundURLSessions: [],
      fetch: Session.Model.BackgroundFetch(
        minimumInterval: .never,
        state: .idle
      ),
      remoteAction: .idle,
      localAction: .idle,
      userActivityState: .idle,
      stateRestoration: .idle,
      userActivityContinuation: .idle,
      watchKitExtensionRequest: .idle,
      localNotification: nil,
      remoteNotifications: [],
      notificationSettings: nil,
      isObservingSignificantTimeChange: false,
      isExperiencingMemoryWarning: false,
      state: .currently(.awaitingLaunch),
      statusBarFrame: .currently(.zero),
      isProtectedDataAvailable: .currently(false),
      remoteNotificationRegistration: .none,
      statusBarOrientation: .currently(.unknown),
      backgroundTasks: Set(),
      isExperiencingHealthAuthorizationRequest: false,
      isIgnoringUserEvents: false,
      isIdleTimerDisabled: false,
      urlActionOutgoing: .idle,
      sendingEvent: nil,
      targetAction: .idle,
      isNetworkActivityIndicatorVisible: false,
      iconBadgeNumber: 0,
      supportsShakeToEdit: true,
      presentedLocalNotification: nil,
      scheduledLocalNotifications: [],
      registeredUserNotificationSettings: nil,
      isReceivingRemoteControlEvents: false,
      newsStandIconImage: nil,
      shortcutActions: [],
      shouldSaveApplicationState: .idle,
      shouldRestoreApplicationState: .idle,
      shouldLaunch: true,
      urlActionIncoming: .idle,
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

extension Session.Model.BackgroundURLSessionAction: Hashable {
  var hashValue: Int { return
    id.hashValue
  }
  static func ==(
    left: Session.Model.BackgroundURLSessionAction,
    right: Session.Model.BackgroundURLSessionAction
  ) -> Bool { return
    left.id == right.id &&
    left.state == right.state
  }
}

extension Session.Model.BackgroundURLSessionAction.State: Equatable {
  static func ==(
    left: Session.Model.BackgroundURLSessionAction.State,
    right: Session.Model.BackgroundURLSessionAction.State
  ) -> Bool {
    switch (left, right) {
    case (.progressing, .progressing): return
      true
    case (.complete, .complete): return
      true
    default: return
      false
    }
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
  static func ==(
    left: Session.Model.RestorationQuery,
    right: Session.Model.RestorationQuery
  ) -> Bool { return
    left.identifier == right.identifier &&
    left.coder == right.coder
  }
}

extension Session.Model.RestorationResponse: Equatable {
  static func ==(
    left: Session.Model.RestorationResponse,
    right: Session.Model.RestorationResponse
  ) -> Bool { return
    left.identifier == right.identifier &&
    left.view == right.view
  }
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

extension Session.Model.BackgroundFetch.Interval: Equatable {
  static func ==(
    left: Session.Model.BackgroundFetch.Interval,
    right: Session.Model.BackgroundFetch.Interval
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

extension Session.Model.BackgroundFetch: Equatable {
  static func == (
    left: Session.Model.BackgroundFetch,
    right: Session.Model.BackgroundFetch
  ) -> Bool { return
    left.minimumInterval == right.minimumInterval &&
    left.state == right.state
  }
}

extension Session.Model.BackgroundFetch.State: Equatable {
  static func ==(
    left: Session.Model.BackgroundFetch.State,
    right: Session.Model.BackgroundFetch.State
  ) -> Bool {
    switch (left, right) {
    case (.idle, .idle): return
      true
    case (.progressing, .progressing): return
      true
    case (.complete, .complete): return
      true
    default: return
      false
    }
  }
}

extension Session.Model.RemoteNofitication: Equatable {
  static func == (
    left: Session.Model.RemoteNofitication,
    right: Session.Model.RemoteNofitication
  ) -> Bool { return
    left.state == right.state &&
    NSDictionary(dictionary: left.notification) == NSDictionary(dictionary: right.notification)
  }
}

extension Session.Model.RemoteNofitication.State: Equatable {
  static func ==(
    left: Session.Model.RemoteNofitication.State,
    right: Session.Model.RemoteNofitication.State
  ) -> Bool {
    switch (left, right) {
    case (.progressing, .progressing): return
      true
    case (.complete(let a, _), .complete(let b, _)): return
      a == b
    default: return
      false
    }
  }
}

extension Session.Model.UserActivityState: Equatable {
  static func ==(
    left: Session.Model.UserActivityState,
    right: Session.Model.UserActivityState
  ) -> Bool {
    switch (left, right) {
    case (.idle, .idle): return
      true
    case (.willContinue(let a), .willContinue(let b)): return
      a == b
    case (.isContinuing(let a), .isContinuing(let b)): return
      a == b
    case (.hasAvailableData(let a), .hasAvailableData(let b)): return
      a == b
    case (.shouldNotifyUserActivitiesWithType(let a), .shouldNotifyUserActivitiesWithType(let b)): return
      a == b
    case (.didContinue(let a), .didContinue(let b)): return
      a == b
    case (.didFail(let a), .didFail(let b)): return
      a.0 == b.0 // Need to compare errors too
    default: return
      false
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
  static func ==(
    left: Session.Model.WindowResponse,
    right: Session.Model.WindowResponse
  ) -> Bool { return
    left.window == right.window &&
    left.orientation == left.orientation
  }
}

extension Session.Model.RemoteNotificationRegistration: Equatable {
  static func ==(
    left: Session.Model.RemoteNotificationRegistration,
    right: Session.Model.RemoteNotificationRegistration
  ) -> Bool {
    switch (left, right) {
    case (.none, .none): return true
    case (.attempting, .attempting): return true
    case (.some(let a), .some(let b)): return a == b
    case (.error, .error): return true // Needs to compare errors
    default: return false
    }
  }
}

extension Session.Model.ShortcutAction.State: Equatable {
  static func ==(
    left: Session.Model.ShortcutAction.State,
    right: Session.Model.ShortcutAction.State
  ) -> Bool {
    switch (left, right) {
    case (.idle, .idle): return
      true
    case (.progressing, .progressing): return
      true
    case (.complete, .complete): return
      true
    default: return
      false
    }
  }
}

extension Session.Model.ShortcutAction: Equatable {
  static func ==(
    left: Session.Model.ShortcutAction,
    right: Session.Model.ShortcutAction
  ) -> Bool { return
    left.item == right.item &&
    left.state == right.state
  }
}

extension EditOperation: Equatable {
  public static func ==(
    left: EditOperation,
    right: EditOperation
  ) -> Bool {
    switch (left, right) {
    case (.insertion, .insertion): return true
    case (.deletion, .deletion): return true
    case (.substitution, .substitution): return true
    case (.move(let a), .move(let b)): return a == b
    default: return false
    }
  }
}

extension Session.Model.URLActionOutgoing: Equatable {
  static func ==(
    left: Session.Model.URLActionOutgoing,
    right: Session.Model.URLActionOutgoing
  ) -> Bool {
    switch (left, right) {
    case (.idle, .idle): return
      true
    case (.attempting(let a), .attempting(let b)): return
      a == b
    case (.opening(let a), .opening(let b)): return
      a == b
    case (.failing(let a), .failing(let b)): return
      a == b
    default: return
      false
    }
  }
}

extension Session.Model.TartgetActionProcess: Equatable {
  static func ==(
    left: Session.Model.TartgetActionProcess,
    right: Session.Model.TartgetActionProcess
  ) -> Bool {
    switch (left, right) {
    case (.idle, .idle): return true
    case (.sending(let a), .sending(let b)): return a == b
    case (.responding(let a, let b), .responding(let c, let d)): return a == c && b == d
    default: return false
    }
  }
}

extension Session.Model.BackgroundTask: Hashable {
  var hashValue: Int { return
    name.hashValue
  }
  static func ==(
    left: Session.Model.BackgroundTask,
    right: Session.Model.BackgroundTask
  ) -> Bool { return
    left.name == right.name &&
    left.state == right.state
  }
}

extension Session.Model.BackgroundTask.State: Equatable {
  static func ==(
    left: Session.Model.BackgroundTask.State,
    right: Session.Model.BackgroundTask.State
  ) -> Bool {
    switch (left, right) {
    case (.pending, .pending): return true
    case (.progressing(let a), .progressing(let b)): return a == b
    case (.complete, .complete): return true
    default: return false
    }
  }
}

extension Session.Model.BackgroundFetch.Interval {
  func asUIApplicationBackgroundFetchInterval() -> TimeInterval {
    switch self {
    case .minimum:
      return UIApplicationBackgroundFetchIntervalMinimum
    case .never:
      return UIApplicationBackgroundFetchIntervalNever
    case .some(let value):
      return value
    }
  }
}

extension Collection where Iterator.Element == Session.Model.BackgroundTask {
  func progressing() -> [Session.Model.BackgroundTask] { return
    flatMap {
      if case .progressing = $0.state { return $0 }
      else { return nil }
    }
  }
  func complete() -> [Session.Model.BackgroundTask] { return
    flatMap {
      if case .complete = $0.state { return $0 }
      else { return nil }
    }
  }
}

extension Session.Model.BackgroundTask {
  var ID: UIBackgroundTaskIdentifier? {
    if case .progressing(let id) = state { return id }
    else if case .complete(let id) = state { return id }
    else { return nil }
  }
}
