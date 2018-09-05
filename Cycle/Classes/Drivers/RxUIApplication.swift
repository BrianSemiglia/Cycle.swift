//
//  RxUIApplication.swift
//  Cycle
//
//  Created by Brian Semiglia on 1/26/17.
//  Copyright © 2017 Brian Semiglia. All rights reserved.
//

import Foundation
import RxSwift
import Changeset

public class RxUIApplication: NSObject, UIApplicationDelegate {
  
  public struct Model {
    public var backgroundURLSessions: Set<BackgroundURLSessionAction>
    public var backgroundFetch: BackgroundFetch
    public var remoteAction: AsyncAction<ActionRemote>
    public var localAction: AsyncAction<ActionLocal>
    public var userActivityState: UserActivityState
    public var stateRestoration: StateRestoration
    public var watchKitExtensionRequests: [watchKitExtensionRequests]
    public var localNotification: UILocalNotification?
    public var remoteNotifications: [RemoteNofitication]
    public var isObservingSignificantTimeChange: Bool
    public var isExperiencingMemoryWarning: Bool
    public var session: Session
    public var statusBarFrame: Change<CGRect>
    public var isProtectedDataAvailable: Change<Bool>
    public var remoteNotificationRegistration: RemoteNotificationRegistration
    public var statusBarOrientation: Change<UIInterfaceOrientation>
    public var backgroundTasks: Set<BackgroundTask>
    public var isExperiencingHealthAuthorizationRequest: Bool
    public var isIgnoringUserEvents: Bool
    public var isIdleTimerDisabled: Bool
    public var urlActionOutgoing: URLActionOutgoing
    public var sendingEvent: UIEvent?
    public var targetAction: TartgetActionProcess
    public var isNetworkActivityIndicatorVisible: Bool
    public var iconBadgeNumber: Int
    public var supportsShakeToEdit: Bool
    public var presentedLocalNotification: UILocalNotification?
    public var scheduledLocalNotifications: [UILocalNotification]
    public var userNotificationSettings: UserNotificationSettingsState
    public var isReceivingRemoteControlEvents: Bool
    public var newsStandIconImage: UIImage?
    public var shortcutActions: [ShortcutAction]
    public var shouldSaveApplicationState: Filtered<NSCoder, Bool>
    public var shouldRestoreApplicationState: Filtered<NSCoder, Bool>
    public var shouldLaunch: Bool
    public var urlActionIncoming: Filtered<RxUIApplication.Model.URLLaunch, URL>
    public var extensionPointIdentifier: Filtered<UIApplicationExtensionPointIdentifier, UIApplicationExtensionPointIdentifier>
    public var interfaceOrientations: [Filtered<UIWindow, WindowResponse>]
    public var viewControllerRestoration: Filtered<RestorationQuery, RestorationResponse>
    
    public enum RemoteNotificationRegistration {
      case idle
      case attempting
      case some(token: Data)
      case error(Error)
    }
    public enum UserNotificationSettingsState {
      case idle
      case attempting(UIUserNotificationSettings)
      case registered(UIUserNotificationSettings)
    }
    public enum URLLaunch {
      case ios4(url: URL, app: String?, annotation: Any)
      case ios9(url: URL, options: [UIApplicationOpenURLOptionsKey : Any])
    }
    public enum Notification {
      case local(value: UILocalNotification)
      case remote(value: [AnyHashable: Any])
    }
    public enum ActionID {
      case some( String)
      case defaultAction
    }
    public enum ActionRemote {
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
    public enum ActionLocal {
      case ios8(
        id: ActionID,
        notification: UILocalNotification,
        completion: () -> Void
      )
      case ios9(
        id: ActionID,
        notification: UILocalNotification,
        response: [AnyHashable: Any],
        completion: () -> Void
      )
    }
    public enum URLActionOutgoing {
      case idle
      case attempting(URL)
      case opening(URL)
      case failing(URL)
    }
    public struct BackgroundURLSessionAction {
      public let id: String // Readonly
      public let completion: () -> Void // Readonly
      public var state: State
      public enum State {
        case progressing // Readonly
        case complete
      }
    }
    public struct BackgroundFetch {
      public var minimumInterval: Interval
      public var state: State
      public enum State {
        case idle // Readonly
        case progressing((UIBackgroundFetchResult) -> Void) // Readonly
        case complete(UIBackgroundFetchResult, (UIBackgroundFetchResult) -> Void)
      }
      public enum Interval {
        case minimum
        case some(TimeInterval)
        case never
      }
    }
    public struct ShortcutAction {
      public var item: UIApplicationShortcutItem
      public var state: State
      public enum State {
        case idle
        case progressing((Bool) -> Void) // Readonly
        case complete(Bool, (Bool) -> Void)
      }
      public init(item: UIApplicationShortcutItem, state: State) {
        self.item = item
        self.state = state
      }
    }
    public struct RemoteNofitication {
      public var notification: [AnyHashable : Any] // Readonly
      public var state: State
      public enum State {
        case progressing((UIBackgroundFetchResult) -> Void) // Readonly
        case complete(UIBackgroundFetchResult, (UIBackgroundFetchResult) -> Void)
      }
    }
    public struct watchKitExtensionRequests {
      public let completion: ([AnyHashable : Any]?) -> Void
      public var state: State
      public enum State {
        case progressing(info: [AnyHashable: Any]?)
        case responding(response: [AnyHashable : Any]?)
      }
    }
    public enum BackgroundURLSessionDataAvailability {
      case none // Readonly
      case some (String, () -> Void) // Readonly
      case ending (() -> Void)
    }
    public enum UserActivityState { // Readonly
      case idle
      case willContinue(String)
      case isContinuing(NSUserActivity, restoration: ([UIResponder]?) -> Void)
      case hasAvailableData(NSUserActivity)
      case shouldNotifyUserActivitiesWithType(String)
      case completing(NSUserActivity)
      case failing(String, Error)
    }
    public enum StateRestoration { // Readonly
      case idle
      case encoding(NSCoder)
      case decoding(NSCoder)
    }
    public struct Session {
      public var shouldLaunch: Bool
      public var state: Change<State>
      public enum State { // Readonly
        case awaitingLaunch
        case active(Count)
        case resigned
        case terminated
        public enum Count {
          case first([UIApplicationLaunchOptionsKey: Any]?)
          case some
        }
      }
    }
    
    // IDEA: prevent transitioning between certain enum states with pattern matched conversion methods and private intializer
    
    public struct WindowResponse {
      public var window: UIWindow
      public var orientation: UIInterfaceOrientationMask
    }
    public struct RestorationQuery {
      public var identifier: String
      public var coder: NSCoder
    }
    public struct RestorationResponse {
      public var identifier: String
      public var view: UIViewController
    }
    public struct BackgroundTask {
      public var name: String // Readonly
      public var state: State
      public enum State {
        case pending
        case progressing(UIBackgroundTaskIdentifier) // Readonly
        case complete(UIBackgroundTaskIdentifier)
        case expiring // Readonly
      }
    }
    public enum TartgetActionProcess {
      case idle
      case sending(TargetAction)
      case responding(TargetAction, Bool) // Readonly
    }
    public struct TargetAction {
      public var action: Selector
      public var target: Any?
      public var sender: Any?
      public var event: UIEvent?
    }
  }
  
  fileprivate let application: UIApplication
  fileprivate let cleanup = DisposeBag()
  fileprivate let output: BehaviorSubject<Model>
  fileprivate var model: Model

  public init(initial: Model) {
    application = UIApplication.shared
    model = initial
    output = BehaviorSubject<Model>(value: initial)
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
      // Momentary
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
    } else if case .responding = model.targetAction {
      model.targetAction = .idle
    }
    
    // Meant to be momentary. Reset if enabled.
    model.isExperiencingMemoryWarning = false
    model.isObservingSignificantTimeChange = false
    model.stateRestoration = .idle
    model.isExperiencingHealthAuthorizationRequest = false
    model.stateRestoration = .idle
    if
    case .completing = model.userActivityState,
    case .failing = model.userActivityState {
      model.userActivityState = .idle
    }

    application.isNetworkActivityIndicatorVisible = model.isNetworkActivityIndicatorVisible
    application.applicationIconBadgeNumber = model.iconBadgeNumber
    application.applicationSupportsShakeToEdit = model.supportsShakeToEdit
    
    if case .complete(let action) = model.remoteAction {
      switch action {
      case .ios8(_, _, let completion), .ios9(_, _, _, let completion):
        completion()
        model.remoteAction = .idle
      }
    }
    
    if case .complete(let action) = model.localAction {
      switch action {
      case .ios8(_, _, let completion), .ios9(_, _, _, let completion):
        completion()
        model.localAction = .idle
      }
    }
    
    /* 
     Deleted requests are left unresponded to.
     Responding requests are removed.
     */
    model.watchKitExtensionRequests = model.watchKitExtensionRequests.compactMap {
      if case .responding(let reply) = $0.state {
        $0.completion(reply)
        return nil
      } else {
        return $0
      }
    }
    
    /*
     Tasks marked in-progress are begun.
     Tasks begun are marked expired and output on expiration.
     */
    model.backgroundTasks = Set(
      RxUIApplication.additions(
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
              strong.model.backgroundTasks = Set(
                strong.model.backgroundTasks.map {
                  if $0.name == task.name {
                    var edit = $0
                    edit.state = .expiring
                    return edit
                  } else {
                    return $0
                  }
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
    let finished = model.backgroundTasks.compactMap { x -> UIBackgroundTaskIdentifier? in
      switch x.state {
      case .complete: return x.ID
      case .expiring: return x.ID
      default: return nil
      }
    }

    let deletions = RxUIApplication.deletions(
      old: Array(old.backgroundTasks),
      new: Array(model.backgroundTasks)
    )
    .progressing()
    .compactMap { $0.ID }
    
    (finished + deletions).forEach {
      application.endBackgroundTask($0)
    }
    
    application.setMinimumBackgroundFetchInterval(
      model.backgroundFetch.minimumInterval.asUIApplicationBackgroundFetchInterval()
    )
    
    if
    case .complete(let result, let handler) = model.backgroundFetch.state,
    model.backgroundFetch != old.backgroundFetch {
      handler(result)
      model.backgroundFetch.state = .idle
    }
    
    if model.remoteNotificationRegistration != old.remoteNotificationRegistration {
      switch model.remoteNotificationRegistration {
      case .attempting:
        application.registerForRemoteNotifications()
      case .idle:
        application.unregisterForRemoteNotifications()
      default:
        break
      }
    }
    
    RxUIApplication.deletions(
      old: old.remoteNotifications,
      new: model.remoteNotifications
    )
    .compactMap { x -> ((UIBackgroundFetchResult) -> Void)? in
      if case .progressing(let a) = x.state { return a }
      else { return nil }
    }
    .forEach {
      $0(.noData)
    }
    
    model.remoteNotifications =  model.remoteNotifications.compactMap {
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
    
    RxUIApplication.additions(
      new: model.scheduledLocalNotifications,
      old: old.scheduledLocalNotifications
    )
    .forEach {
      application.scheduleLocalNotification($0)
    }
    
    RxUIApplication.deletions(
      old: old.scheduledLocalNotifications,
      new: model.scheduledLocalNotifications
    )
    .forEach {
      application.cancelLocalNotification($0)
    }
    
    if
    case .attempting(let settings) = model.userNotificationSettings,
    model.userNotificationSettings != old.userNotificationSettings {
      application.registerUserNotificationSettings(settings)
    }
    
    if old.isReceivingRemoteControlEvents != model.isReceivingRemoteControlEvents {
      model.isReceivingRemoteControlEvents
        ? application.beginReceivingRemoteControlEvents()
        : application.endReceivingRemoteControlEvents()
    }
    
    if #available(iOS 9.0, *) {} else if old.newsStandIconImage != model.newsStandIconImage {
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
         case .complete(let result, let completion) = $0.value.state {
        completion(result)
      }
    }

    RxUIApplication.deletions(
      old: Array(old.backgroundURLSessions),
      new: Array(model.backgroundURLSessions)
    )
    .forEach {
      if case .progressing = $0.state {
        $0.completion()
      }
    }
    
    model.backgroundURLSessions = Set(
      model.backgroundURLSessions.compactMap {
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
  
  public func eventsCapturedAfterRendering(_ input: Observable<Model>) -> Observable<Model> {
    input
      .distinctUntilChanged()
      .subscribe(onNext: { [weak self] new in
        if let strong = self {
          strong.render(
            new: new,
            old: strong.model
          )
        }
      })
      .disposed(by: cleanup)
    return output.distinctUntilChanged()
  }

  public func application(
    _ application: UIApplication,
    willFinishLaunchingWithOptions options: [UIApplicationLaunchOptionsKey : Any]? = nil
  ) -> Bool {
    model.session.state = .pre(.active(.first(options)))
    output.on(.next(model))
    return model.shouldLaunch
  }

  public func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions options: [UIApplicationLaunchOptionsKey : Any]? = nil
  ) -> Bool {
    model.session.state = .currently(.active(.first(options)))
    output.on(.next(model))
    return model.shouldLaunch
  }

  public func applicationDidBecomeActive(_ application: UIApplication) {
    model.session.state = .currently(.active(.some))
    output.on(.next(model))
  }

  public func applicationWillResignActive(_ application: UIApplication) {
    model.session.state = .pre(.resigned)
    output.on(.next(model))
  }

  public func application(
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

  public func application(
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

  public func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
    model.isExperiencingMemoryWarning = true
    output.on(.next(model))
  }

  public func applicationWillTerminate(_ application: UIApplication) {
    model.session.state = .pre(.terminated)
    output.on(.next(model))
  }

  public func applicationSignificantTimeChange(_ application: UIApplication) {
    model.isObservingSignificantTimeChange = true
    output.on(.next(model))
  }

  public func application(
    _ application: UIApplication,
    willChangeStatusBarOrientation newStatusBarOrientation: UIInterfaceOrientation,
    duration: TimeInterval
  ) {
    model.statusBarOrientation = .pre(newStatusBarOrientation)
    output.on(.next(model))
  }

  public func application(
    _ application: UIApplication,
    didChangeStatusBarOrientation oldStatusBarOrientation: UIInterfaceOrientation
  ) {
    model.statusBarOrientation = .currently(UIApplication.shared.statusBarOrientation)
    output.on(.next(model))
  }

  public func application(
    _ application: UIApplication,
    willChangeStatusBarFrame new: CGRect
  ) {
    model.statusBarFrame = .pre(new)
    output.on(.next(model))
  }

  public func application(
    _ application: UIApplication,
    didChangeStatusBarFrame old: CGRect
  ) {
    model.statusBarFrame = .currently(application.statusBarFrame)
    output.on(.next(model))
  }

  public func application(
    _ application: UIApplication,
    didRegister notificationSettings: UIUserNotificationSettings
  ) {
    model.userNotificationSettings = .registered(notificationSettings)
    output.on(.next(model))
  }

  public func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken token: Data
  ) {
    model.remoteNotificationRegistration = .some(token: token)
    output.on(.next(model))
  }

  public func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    model.remoteNotificationRegistration = .error(error)
    output.on(.next(model))
  }

  public func application(
    _ application: UIApplication,
    didReceive notification: UILocalNotification
  ) {
    model.localNotification = notification
    output.on(.next(model))
  }

  public func application(
    _ application: UIApplication,
    handleActionWithIdentifier identifier: String?,
    for notification: UILocalNotification,
    completionHandler: @escaping () -> Void
  ) {
    model.localAction = .progressing(
      .ios8(
        id: identifier.map {.some( $0)} ?? .defaultAction,
        notification: notification,
        completion: completionHandler
      )
    )
    output.on(.next(model))
  }

  public func application(
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

  public func application(
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

  public func application(
    _ application: UIApplication,
    handleActionWithIdentifier identifier: String?,
    for notification: UILocalNotification,
    withResponseInfo responseInfo: [AnyHashable : Any],
    completionHandler: @escaping () -> Void
  ) {
    model.localAction = .progressing(
      .ios9(
        id: identifier.map {.some( $0)} ?? .defaultAction,
        notification: notification,
        response: responseInfo,
        completion: completionHandler
      )
    )
    output.on(.next(model))
  }

  public func application(
    _ application: UIApplication,
    didReceiveRemoteNotification info: [AnyHashable : Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    model.remoteNotifications += [
      RxUIApplication.Model.RemoteNofitication(
        notification: info,
        state: .progressing(completionHandler)
      )
    ]
    output.on(.next(model))
  }

  public func application(
    _ application: UIApplication,
    performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult
  ) -> Void) {
    model.backgroundFetch.state = .progressing(completionHandler)
    output.on(.next(model))
  }

  public func application(
    _ application: UIApplication,
    performActionFor shortcutItem: UIApplicationShortcutItem,
    completionHandler: @escaping (Bool) -> Void
  ) {
    model.shortcutActions = model.shortcutActions.map {
      if $0.item.type == shortcutItem.type {
        return RxUIApplication.Model.ShortcutAction(
          item: shortcutItem,
          state: .progressing(completionHandler)
        )
      } else {
        return $0
      }
    }
    output.on(.next(model))
  }

  public func application(
    _ application: UIApplication,
    handleEventsForBackgroundURLSession identifier: String,
    completionHandler: @escaping () -> Void
  ) {
    model.backgroundURLSessions = Set(
      Array(model.backgroundURLSessions)
      + [
        RxUIApplication.Model.BackgroundURLSessionAction(
          id: identifier,
          completion: completionHandler,
          state: .progressing
        )
      ]
    )
    output.on(.next(model))
  }
  
  public func application(
    _ application: UIApplication,
    handleWatchKitExtensionRequest userInfo: [AnyHashable : Any]?,
    reply: @escaping ([AnyHashable : Any]?) -> Void
  ) {
    model.watchKitExtensionRequests += [
      RxUIApplication.Model.watchKitExtensionRequests(
        completion: reply,
        state: .progressing(
          info: userInfo
        )
      )
    ]
    output.on(.next(model))
  }

  public func applicationShouldRequestHealthAuthorization(_ application: UIApplication) {
    model.isExperiencingHealthAuthorizationRequest = true
    output.on(.next(model))
  }

  public func applicationDidEnterBackground(_ application: UIApplication) {
    model.session.state = .currently(.resigned)
    output.on(.next(model))
  }

  public func applicationWillEnterForeground(_ application: UIApplication) {
    model.session.state = .pre(.active(.some))
    output.on(.next(model))
  }

  public func applicationProtectedDataWillBecomeUnavailable(_ application: UIApplication) {
    model.isProtectedDataAvailable = .pre(false)
    output.on(.next(model))
  }

  public func applicationProtectedDataDidBecomeAvailable(_ application: UIApplication) {
    model.isProtectedDataAvailable = .currently(true)
    output.on(.next(model))
  }

  public func application(
    _ application: UIApplication,
    supportedInterfaceOrientationsFor window: UIWindow?
  ) -> UIInterfaceOrientationMask {
    if let window = window {
      model.interfaceOrientations += [.considering(window)]
      output.on(.next(model))
      return self.model.interfaceOrientations
        .compactMap { $0.allowed() }
        .filter { $0.window == window }
        .first
        .map { $0.orientation }
        ?? .allButUpsideDown
    } else {
      return .allButUpsideDown
    }
  }

  public func application(
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

  public func application(
    _ application: UIApplication,
    viewControllerWithRestorationIdentifierPath components: [Any],
    coder: NSCoder
  ) -> UIViewController? {
    if let component = components.last as? String {
      model.viewControllerRestoration = .considering(
        RxUIApplication.Model.RestorationQuery(
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

  public func application(
    _ application: UIApplication,
    shouldSaveApplicationState coder: NSCoder
  ) -> Bool {
    model.shouldSaveApplicationState = .considering(coder)
    output.on(.next(model))
    return model.shouldSaveApplicationState == .allowing(true)
  }

  public func application(
    _ application: UIApplication,
    shouldRestoreApplicationState coder: NSCoder
  ) -> Bool {
    model.shouldRestoreApplicationState = .considering(coder)
    output.on(.next(model))
    return model.shouldRestoreApplicationState.allowed() == true
  }

  public func application(
    _ application: UIApplication,
    willEncodeRestorableStateWith coder: NSCoder
  ) {
    model.stateRestoration = .encoding(coder)
    output.on(.next(model))
  }

  public func application(
    _ application: UIApplication,
    didDecodeRestorableStateWith coder: NSCoder
  ) {
    model.stateRestoration = .decoding(coder)
    output.on(.next(model))
  }

  public func application(
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

  public func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([Any]?) -> Void
  ) -> Bool {
    model.userActivityState = .isContinuing(
      userActivity,
      restoration: { restorationHandler($0.map { [$0 as Any] }) }
    )
    output.on(.next(model))
    if case .hasAvailableData(let confirmed) = model.userActivityState {
      return userActivity == confirmed
    } else {
      return true
    }
  }

  public func application(
    _ application: UIApplication,
    didFailToContinueUserActivityWithType userActivityType: String,
    error: Error
  ) {
    model.userActivityState = .failing(userActivityType, error)
    output.on(.next(model))
  }

  public func application(
    _ application: UIApplication,
    didUpdate userActivity: NSUserActivity
  ) {
    model.userActivityState = .completing(userActivity)
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

extension RxUIApplication {
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

extension RxUIApplication {
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

extension RxUIApplication.Model: Equatable {
  public static func == (left: RxUIApplication.Model, right: RxUIApplication.Model) -> Bool { return
    left.backgroundURLSessions == right.backgroundURLSessions &&
    left.backgroundFetch == right.backgroundFetch &&
    left.remoteAction == right.remoteAction &&
    left.localAction == right.localAction &&
    left.userActivityState == right.userActivityState &&
    left.stateRestoration == right.stateRestoration &&
    left.watchKitExtensionRequests == right.watchKitExtensionRequests &&
    left.localNotification == right.localNotification &&
    left.remoteNotifications == right.remoteNotifications &&
    left.isObservingSignificantTimeChange == right.isObservingSignificantTimeChange &&
    left.isExperiencingMemoryWarning == right.isExperiencingMemoryWarning &&
    left.session == right.session &&
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
    left.userNotificationSettings == right.userNotificationSettings &&
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

extension RxUIApplication.Model.ShortcutAction: CustomDebugStringConvertible {
  public var debugDescription: String { return
    item.type + " " + String(describing: state)
  }
}

extension AsyncAction: CustomDebugStringConvertible {
  public var debugDescription: String {
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

public enum Change<T: Equatable> {
  case pre(T)
  case currently(T)
}

extension Change: Equatable {
  public static func ==(left: Change, right: Change) -> Bool {
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

public enum Filtered<T: Equatable, U: Equatable> {
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
  public static func ==(left: Filtered, right: Filtered) -> Bool {
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

public enum AsyncAction<Handler: Equatable> {
  case idle
  case progressing(Handler)
  case complete(Handler)
}

extension RxUIApplication.Model {
  public static var empty: RxUIApplication.Model { return
    RxUIApplication.Model(
      backgroundURLSessions: [],
      backgroundFetch: RxUIApplication.Model.BackgroundFetch(
        minimumInterval: .never,
        state: .idle
      ),
      remoteAction: .idle,
      localAction: .idle,
      userActivityState: .idle,
      stateRestoration: .idle,
      watchKitExtensionRequests: [], // Readonly
      localNotification: nil,
      remoteNotifications: [],
      isObservingSignificantTimeChange: false,
      isExperiencingMemoryWarning: false,
      session: RxUIApplication.Model.Session(
        shouldLaunch: true,
        state: .currently(.awaitingLaunch)
      ),
      statusBarFrame: .currently(.zero),
      isProtectedDataAvailable: .currently(false),
      remoteNotificationRegistration: .idle,
      statusBarOrientation: .currently(.unknown),
      backgroundTasks: [],
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
      userNotificationSettings: .idle,
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

extension RxUIApplication.Model.Session: Equatable {
  public static func ==(
    left: RxUIApplication.Model.Session,
    right: RxUIApplication.Model.Session
  ) -> Bool { return
    left.shouldLaunch == right.shouldLaunch &&
    left.state == right.state
  }
}

extension RxUIApplication.Model.Session.State: Equatable {
  public static func ==(
    left: RxUIApplication.Model.Session.State,
    right: RxUIApplication.Model.Session.State
  ) -> Bool {
    switch (left, right) {
    case (.awaitingLaunch, .awaitingLaunch): return
      true
    case (.active(let a), .active(let b)): return
      a == b
    case (.resigned, .resigned): return
      true
    case (.terminated, .terminated): return
      true
    default: return
      false
    }
  }
}

extension RxUIApplication.Model.Session.State.Count: Equatable {
  public static func ==(
    left: RxUIApplication.Model.Session.State.Count,
    right: RxUIApplication.Model.Session.State.Count
  ) -> Bool {
    switch (left, right) {
    case (.first(let a), .first(let b)): return
      a.map { NSDictionary(dictionary: $0) } ==
      b.map { NSDictionary(dictionary: $0) }
    case (.some, .some): return
      true
    default: return
      false
    }
  }
}

extension RxUIApplication.Model.BackgroundURLSessionAction: Hashable {
  public var hashValue: Int { return
    id.hashValue
  }
  public static func ==(
    left: RxUIApplication.Model.BackgroundURLSessionAction,
    right: RxUIApplication.Model.BackgroundURLSessionAction
  ) -> Bool { return
    left.id == right.id &&
    left.state == right.state
  }
}

extension RxUIApplication.Model.BackgroundURLSessionAction.State: Equatable {
  public static func ==(
    left: RxUIApplication.Model.BackgroundURLSessionAction.State,
    right: RxUIApplication.Model.BackgroundURLSessionAction.State
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

extension RxUIApplication.Model.URLLaunch: Equatable {
  public static func ==(left: RxUIApplication.Model.URLLaunch, right: RxUIApplication.Model.URLLaunch) -> Bool {
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
  public static func ==(left: AsyncAction, right: AsyncAction) -> Bool {
    switch (left, right) {
    case (.idle, .idle): return true
    case (.progressing(let a), .progressing(let b)): return a == b
    case (.complete(let a), .complete(let b)): return a == b
    default: return false
    }
  }
}

extension RxUIApplication.Model.RestorationQuery: Equatable {
  public static func ==(
    left: RxUIApplication.Model.RestorationQuery,
    right: RxUIApplication.Model.RestorationQuery
  ) -> Bool { return
    left.identifier == right.identifier &&
    left.coder == right.coder
  }
}

extension RxUIApplication.Model.RestorationResponse: Equatable {
  public static func ==(
    left: RxUIApplication.Model.RestorationResponse,
    right: RxUIApplication.Model.RestorationResponse
  ) -> Bool { return
    left.identifier == right.identifier &&
    left.view == right.view
  }
}

extension RxUIApplication.Model.TargetAction: Equatable {
  public static func ==(
    left: RxUIApplication.Model.TargetAction,
    right: RxUIApplication.Model.TargetAction
  ) -> Bool { return
    left.action == right.action
    && left.event === right.event
    && (left.sender as? NSObject) === (right.sender as? NSObject)
    && (left.target as? NSObject) === (right.target as? NSObject)
  }
}

extension RxUIApplication.Model.BackgroundFetch.Interval: Equatable {
  public static func ==(
    left: RxUIApplication.Model.BackgroundFetch.Interval,
    right: RxUIApplication.Model.BackgroundFetch.Interval
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

extension RxUIApplication.Model.ActionID: Equatable {
  public static func ==(
    left: RxUIApplication.Model.ActionID,
    right: RxUIApplication.Model.ActionID
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

extension RxUIApplication.Model.ActionRemote: Equatable {
  public static func ==(
    left: RxUIApplication.Model.ActionRemote,
    right: RxUIApplication.Model.ActionRemote
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

extension RxUIApplication.Model.ActionLocal: Equatable {
  public static func ==(
    left: RxUIApplication.Model.ActionLocal,
    right: RxUIApplication.Model.ActionLocal
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

extension RxUIApplication.Model.Notification: Equatable {
  public static func ==(
    left: RxUIApplication.Model.Notification,
    right: RxUIApplication.Model.Notification
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

extension RxUIApplication.Model.BackgroundFetch: Equatable {
  public static func == (
    left: RxUIApplication.Model.BackgroundFetch,
    right: RxUIApplication.Model.BackgroundFetch
  ) -> Bool { return
    left.minimumInterval == right.minimumInterval &&
    left.state == right.state
  }
}

extension RxUIApplication.Model.BackgroundFetch.State: Equatable {
  public static func ==(
    left: RxUIApplication.Model.BackgroundFetch.State,
    right: RxUIApplication.Model.BackgroundFetch.State
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

extension RxUIApplication.Model.RemoteNofitication: Equatable {
  public static func == (
    left: RxUIApplication.Model.RemoteNofitication,
    right: RxUIApplication.Model.RemoteNofitication
  ) -> Bool { return
    left.state == right.state &&
    NSDictionary(dictionary: left.notification) == NSDictionary(dictionary: right.notification)
  }
}

extension RxUIApplication.Model.RemoteNofitication.State: Equatable {
  public static func ==(
    left: RxUIApplication.Model.RemoteNofitication.State,
    right: RxUIApplication.Model.RemoteNofitication.State
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

extension RxUIApplication.Model.UserActivityState: Equatable {
  public static func ==(
    left: RxUIApplication.Model.UserActivityState,
    right: RxUIApplication.Model.UserActivityState
  ) -> Bool {
    switch (left, right) {
    case (.idle, .idle): return
      true
    case (.willContinue(let a), .willContinue(let b)): return
      a == b
    case (.isContinuing(let a), .isContinuing(let b)): return
      a.0 == b.0
    case (.hasAvailableData(let a), .hasAvailableData(let b)): return
      a == b
    case (.shouldNotifyUserActivitiesWithType(let a), .shouldNotifyUserActivitiesWithType(let b)): return
      a == b
    case (.completing(let a), .completing(let b)): return
      a == b
    case (.failing(let a), .failing(let b)): return
      a.0 == b.0 // Need to compare errors too
    default: return
      false
    }
  }
}

extension RxUIApplication.Model.StateRestoration: Equatable {
  public static func == (
    left: RxUIApplication.Model.StateRestoration,
    right: RxUIApplication.Model.StateRestoration
  ) -> Bool {
    switch (left, right) {
    case (.idle, .idle): return true
    case (.encoding(let a), .encoding(let b)): return a == b
    case (.decoding(let a), decoding(let b)): return a == b
    default: return false
    }
  }
}

extension RxUIApplication.Model.watchKitExtensionRequests: Equatable {
  public static func ==(
    left: RxUIApplication.Model.watchKitExtensionRequests,
    right: RxUIApplication.Model.watchKitExtensionRequests
  ) -> Bool {
    switch (left.state, right.state) {
    case (.progressing(let a), .progressing(let b)): return
      a.map(NSDictionary.init(dictionary:)) ==
      b.map(NSDictionary.init(dictionary:))
    case (.responding(let a), .responding(let b)): return
      a.map(NSDictionary.init(dictionary:)) ==
      b.map(NSDictionary.init(dictionary:))
    default: return
      false
    }
  }
}

extension RxUIApplication.Model.WindowResponse: Equatable {
  public static func ==(
    left: RxUIApplication.Model.WindowResponse,
    right: RxUIApplication.Model.WindowResponse
  ) -> Bool { return
    left.window == right.window &&
    left.orientation == left.orientation
  }
}

extension RxUIApplication.Model.RemoteNotificationRegistration: Equatable {
  public static func ==(
    left: RxUIApplication.Model.RemoteNotificationRegistration,
    right: RxUIApplication.Model.RemoteNotificationRegistration
  ) -> Bool {
    switch (left, right) {
    case (.idle, .idle): return true
    case (.attempting, .attempting): return true
    case (.some(let a), .some(let b)): return a == b
    case (.error, .error): return true // Needs to compare errors
    default: return false
    }
  }
}

extension RxUIApplication.Model.ShortcutAction.State: Equatable {
  public static func ==(
    left: RxUIApplication.Model.ShortcutAction.State,
    right: RxUIApplication.Model.ShortcutAction.State
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

extension RxUIApplication.Model.ShortcutAction: Equatable {
  public static func ==(
    left: RxUIApplication.Model.ShortcutAction,
    right: RxUIApplication.Model.ShortcutAction
  ) -> Bool { return
    left.item == right.item &&
    left.state == right.state
  }
}

extension RxUIApplication.Model.URLActionOutgoing: Equatable {
  public static func ==(
    left: RxUIApplication.Model.URLActionOutgoing,
    right: RxUIApplication.Model.URLActionOutgoing
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

extension RxUIApplication.Model.TartgetActionProcess: Equatable {
  public static func ==(
    left: RxUIApplication.Model.TartgetActionProcess,
    right: RxUIApplication.Model.TartgetActionProcess
  ) -> Bool {
    switch (left, right) {
    case (.idle, .idle): return true
    case (.sending(let a), .sending(let b)): return a == b
    case (.responding(let a, let b), .responding(let c, let d)): return a == c && b == d
    default: return false
    }
  }
}

extension RxUIApplication.Model.BackgroundTask: Hashable {
  public var hashValue: Int { return
    name.hashValue
  }
  public static func ==(
    left: RxUIApplication.Model.BackgroundTask,
    right: RxUIApplication.Model.BackgroundTask
  ) -> Bool { return
    left.name == right.name &&
    left.state == right.state
  }
}

extension RxUIApplication.Model.BackgroundTask.State: Equatable {
  public static func ==(
    left: RxUIApplication.Model.BackgroundTask.State,
    right: RxUIApplication.Model.BackgroundTask.State
  ) -> Bool {
    switch (left, right) {
    case (.pending, .pending): return true
    case (.progressing(let a), .progressing(let b)): return a == b
    case (.complete, .complete): return true
    default: return false
    }
  }
}

extension RxUIApplication.Model.UserNotificationSettingsState: Equatable {
  public static func ==(
    left: RxUIApplication.Model.UserNotificationSettingsState,
    right: RxUIApplication.Model.UserNotificationSettingsState
  ) -> Bool {
    switch (left, right) {
    case (.idle, .idle): return true
    case (.attempting(let a), .attempting(let b)): return a == b
    case (.registered(let a), .registered(let b)): return a == b
    default: return false
    }
  }
}

extension RxUIApplication.Model.BackgroundFetch.Interval {
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

extension Collection where Iterator.Element == RxUIApplication.Model.BackgroundTask {
  func progressing() -> [RxUIApplication.Model.BackgroundTask] { return
    compactMap {
      if case .progressing = $0.state { return $0 }
      else { return nil }
    }
  }
  func complete() -> [RxUIApplication.Model.BackgroundTask] { return
    compactMap {
      if case .complete = $0.state { return $0 }
      else { return nil }
    }
  }
}

extension RxUIApplication.Model.BackgroundTask {
  public var ID: UIBackgroundTaskIdentifier? {
    if case .progressing(let id) = state { return id }
    else if case .complete(let id) = state { return id }
    else { return nil }
  }
}
