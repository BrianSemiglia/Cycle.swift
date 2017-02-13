//
//  Session.swift
//  Cycle
//
//  Created by Brian Semiglia on 1/26/17.
//  Copyright © 2017 Brian Semiglia. All rights reserved.
//

import Foundation
//import CloudKit
import RxSwift
import Changeset

class Session: NSObject, UIApplicationDelegate {
  
  struct Model {
    var backgroundURLSessionAction: BackgroundURLSessionAction
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
    var remoteNotificationRegistration: RemoteNotificationRegistration
    var statusBarOrientation: Change<UIInterfaceOrientation>
    var backgroundTasks: Set<BackgroundTask>
    var isExperiencingHealthAuthorizationRequest: Bool
    var isIgnoringUserEvents: Bool
    var isIdleTimerDisabled: Bool
    var urlActionOutgoing: URLActionOutgoing
    var sendingEvent: UIEvent?
    var sendingAction: TartgetActionProcess
    var isNetworkActivityIndicatorVisible: Bool
    var iconBadgeNumber: Int
    var supportsShakeToEdit: Bool
    var minimumBackgroundFetchInterval: FetchInterval
    var presentedLocalNotification: UILocalNotification?
    var scheduledLocalNotifications: [UILocalNotification]
    var registeredUserNotificationSettings: UIUserNotificationSettings?
    var isReceivingRemoteControlEvents: Bool
    var newsStandIconImage: UIImage?
    var shortcutItems: [ShortcutItem]
    var shouldSaveApplicationState: Filtered<NSCoder, Bool>
    var shouldRestoreApplicationState: Filtered<NSCoder, Bool>
    var shouldLaunch: Bool
    var urlActionIncoming: Filtered<Session.Model.URLLaunch, URL>
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
    enum URLActionOutgoing {
      case idle
      case attempting(URL)
      case opening(URL)
      case failing(URL)
    }
    enum BackgroundURLSessionAction {
      case idle
      case progressing(String, (Void) -> Void)
      case complete
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
      case hasAvailableData(NSUserActivity)
      case shouldNotifyUserActivitiesWithType(String)
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
      var state: State
      enum State {
        case pending
        case progressing(UIBackgroundTaskIdentifier)
        case complete(UIBackgroundTaskIdentifier)
        case expired
      }
    }
    enum TartgetActionProcess {
      case idle
      case sending(TargetAction)
      case responding(TargetAction, Bool)
    }
    struct TargetAction {
      var action: Selector
      var target: Any?
      var sender: Any?
      var event: UIEvent?
    }
  }
  
  init(_ input: Session.Model) {
    model = input
    output = BehaviorSubject<Model>(value: input)
  }
  
  static let shared = Session(.empty)
  var application: UIApplication!
  fileprivate var disposable: Disposable?
  fileprivate let output: BehaviorSubject<Session.Model>
  fileprivate var model: Session.Model {
    didSet {

      var edit = model

      if model.isIgnoringUserEvents != oldValue.isIgnoringUserEvents {
        model.isIgnoringUserEvents
          ? application.beginIgnoringInteractionEvents()
          : application.endIgnoringInteractionEvents()
      }
      
      application.isIdleTimerDisabled = model.isIdleTimerDisabled
      
      switch model.urlActionOutgoing {
      case .attempting(let url):
        edit.urlActionOutgoing = .opening(url)
        model = edit
        application.openURL(url)
      case .opening:
        edit.urlActionOutgoing = .idle
        model = edit
      default:
        break
      }
      
      if let new = model.sendingEvent {
        application.sendEvent(new)
        edit.sendingEvent = nil
      }
      
      if case .sending(let new) = model.sendingAction {
        let didSend = application.sendAction(
          new.action,
          to: new.target,
          from: new.sender,
          for: new.event
        )
        edit.sendingAction = .responding(new, didSend)
        DispatchQueue.main.async { [weak self] in
          if let strong = self {
            if case .responding(let action, _) = strong.model.sendingAction, action == new {
              var edit = strong.model
              edit.sendingAction = .idle
              strong.output.on(.next(edit))
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
      edit.backgroundTasks = Set(
        Session.additions(
          new: Array(model.backgroundTasks),
          old: Array(oldValue.backgroundTasks)
        )
        .filter {
          if case .progressing = $0.state {
            return true
          } else {
            return false
          }
        }
        .map { task in
          var ID: UIBackgroundTaskIdentifier = 0
          ID = application.beginBackgroundTask( // SIDE EFFECT!
            withName: task.name,
            expirationHandler: { [weak self] in
              if let strong = self {
                strong.application.endBackgroundTask(ID) // SIDE EFFECT!
                var edit = strong.model
                edit.backgroundTasks = Set(
                  edit.backgroundTasks
                  .filter { $0.name == task.name }
                  .map {
                    var edit = $0
                    edit.state = .expired
                    return edit
                  }
                )
                strong.output.on(.next(edit))
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
        old: Array(oldValue.backgroundTasks),
        new: Array(model.backgroundTasks)
        ).progressing().flatMap { $0.ID }
      
      (complete + deletions).forEach {
        application.endBackgroundTask($0)
      }
      
      application.setMinimumBackgroundFetchInterval(
        model.minimumBackgroundFetchInterval.asUIApplicationBackgroundFetchInterval()
      )
      
      switch model.remoteNotificationRegistration {
      case .attempting:
        application.registerForRemoteNotifications()
      case .unregistering:
        application.unregisterForRemoteNotifications()
      default:
        break
      }
      
      if
      let new = model.presentedLocalNotification,
      oldValue.presentedLocalNotification != new {
        application.presentLocalNotificationNow(new)
      }
      
      Session.additions(
        new: model.scheduledLocalNotifications,
        old: oldValue.scheduledLocalNotifications
      ).forEach {
        application.scheduleLocalNotification($0)
      }
      
      Session.deletions(
        old: oldValue.scheduledLocalNotifications,
        new: model.scheduledLocalNotifications
      ).forEach {
        application.cancelLocalNotification($0)
      }
      
      if
      let new = model.registeredUserNotificationSettings,
      oldValue.registeredUserNotificationSettings != new {
        application.registerUserNotificationSettings(new)
      }
      
      if oldValue.isReceivingRemoteControlEvents != model.isReceivingRemoteControlEvents {
        model.isReceivingRemoteControlEvents
          ? application.beginReceivingRemoteControlEvents()
          : application.endReceivingRemoteControlEvents()
      }
      
      if oldValue.newsStandIconImage != model.newsStandIconImage {
        application.setNewsstandIconImage(model.newsStandIconImage)
      }
      
      application.shortcutItems = model.shortcutItems.map { $0.value }
      
      let change = Changeset(source: oldValue.shortcutItems, target: model.shortcutItems)
        
      change
      .edits
      .flatMap { completionHandler(type: .deletion, edit: $0) }
      .forEach { $0(false) }

      change
      .edits
      .flatMap { completionHandler(type: .substitution, edit: $0) }
      .forEach { $0(true) }

      if
      case .complete = model.backgroundURLSessionAction,
      model.backgroundURLSessionAction != oldValue.backgroundURLSessionAction {
        if case .progressing(let handler) = oldValue.backgroundURLSessionAction {
          handler.1()
        }
        edit.backgroundURLSessionAction = .idle
      }
      
      output.on(.next(edit))
    }
  }
  
  func rendered(_ input: Observable<Model>) -> Observable<Model> { return
    input.distinctUntilChanged().flatMap { model in
      Observable.create { [weak self] observer in if let strong = self {
        strong.model = model
        if strong.disposable == nil {
          strong.disposable = strong.output.distinctUntilChanged().subscribe {
            if let new = $0.element {
              observer.on(.next(new))
            }
          }
        }}
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
    var edit2 = model
    edit2.state = .none(.launched(launchOptions))
    output.on(.next(edit2))
    return model.shouldLaunch == true
  }

  func applicationDidBecomeActive(_ application: UIApplication) {
    var edit = model
    edit.state = .did(.active)
    output.on(.next(edit))
    var edit2 = model
    edit2.state = .none(.active)
    output.on(.next(edit2))
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
    edit.urlActionIncoming = .considering(
      .ios4(
        url: url,
        app: sourceApplication,
        annotation: annotation
      )
    )
    output.on(.next(edit))
    if case .allowing(let allowed) = model.urlActionIncoming {
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
    edit.urlActionIncoming = .considering(.ios9(url: url, options: options))
    output.on(.next(edit))
    if case .allowing(let allowed) = model.urlActionIncoming {
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
    var edit2 = model
    edit2.statusBarOrientation = .none(oldStatusBarOrientation)
    output.on(.next(edit2))
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
    edit.statusBarFrame = .did(application.statusBarFrame)
    output.on(.next(edit))
    var edit2 = model
    edit2.statusBarFrame = .none(application.statusBarFrame)
    output.on(.next(edit2))
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
    edit.remoteNotificationRegistration = .token(token)
    output.on(.next(edit))
  }

  func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    var edit = model
    edit.remoteNotificationRegistration = .error(error)
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
    edit.backgroundURLSessionAction = .progressing(identifier, completionHandler)
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
    var edit2 = model
    edit2.state = .none(.resigned)
    output.on(.next(edit2))
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
    var edit2 = model
    edit.isProtectedDataAvailable = .none(false)
    output.on(.next(edit2))
  }

  func applicationProtectedDataDidBecomeAvailable(_ application: UIApplication) {
    var edit = model
    edit.isProtectedDataAvailable = .did(true)
    output.on(.next(edit))
    var edit2 = model
    edit2.isProtectedDataAvailable = .none(true)
    output.on(.next(edit2))
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
    edit.stateRestoration = .idle
    output.on(.next(edit))
  }

  func application(
    _ application: UIApplication,
    didDecodeRestorableStateWith coder: NSCoder
  ) {
    var edit = model
    edit.stateRestoration = .didDecode(coder)
    output.on(.next(edit))
    var edit2 = model
    edit2.stateRestoration = .idle
    output.on(.next(edit2))
  }

  func application(
    _ application: UIApplication,
    willContinueUserActivityWithType type: String
  ) -> Bool {
    var edit = model
    edit.userActivityState = .willContinue(type)
    output.on(.next(edit))
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
    var edit = model
    edit.userActivityState = .isContinuing(userActivity)
    output.on(.next(edit))
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
    var edit = model
    edit.userActivityState = .didFail(userActivityType, error)
    output.on(.next(edit))
    var edit2 = model
    edit2.userActivityState = .idle
    output.on(.next(edit2))
  }

  func application(
    _ application: UIApplication,
    didUpdate userActivity: NSUserActivity
  ) {
    var edit = model
    edit.userActivityState = .didContinue(userActivity)
    output.on(.next(edit))
    var edit2 = model
    edit2.userActivityState = .idle
    output.on(.next(edit2))
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
    left.remoteNotificationRegistration == right.remoteNotificationRegistration &&
    left.statusBarOrientation == right.statusBarOrientation &&
    left.backgroundTasks == right.backgroundTasks &&
    left.isExperiencingHealthAuthorizationRequest == right.isExperiencingHealthAuthorizationRequest &&
    left.isIgnoringUserEvents == right.isIgnoringUserEvents &&
    left.isIdleTimerDisabled == right.isIdleTimerDisabled &&
    left.urlActionOutgoing == right.urlActionOutgoing &&
    left.sendingEvent == right.sendingEvent &&
    left.sendingAction == right.sendingAction &&
    left.isNetworkActivityIndicatorVisible == right.isNetworkActivityIndicatorVisible &&
    left.iconBadgeNumber == right.iconBadgeNumber &&
    left.supportsShakeToEdit == right.supportsShakeToEdit &&
    left.minimumBackgroundFetchInterval == right.minimumBackgroundFetchInterval &&
    left.presentedLocalNotification == right.presentedLocalNotification &&
    left.scheduledLocalNotifications == right.scheduledLocalNotifications &&
    left.registeredUserNotificationSettings == right.registeredUserNotificationSettings &&
    left.isReceivingRemoteControlEvents == right.isReceivingRemoteControlEvents &&
    left.newsStandIconImage == right.newsStandIconImage &&
    left.shortcutItems == right.shortcutItems &&
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

extension Session.Model.ShortcutItem: CustomDebugStringConvertible {
  var debugDescription: String { return
    value.type + " " + String(describing: action)
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

func completionHandler(
    type: EditOperation,
    edit: Edit<Session.Model.ShortcutItem>
  ) -> ((Bool) -> Void)? {
  if let d = edit.possible(type), case .progressing(let a) = d.value.action { return
    a.completion
  } else { return
    nil
  }
}

enum Change<T: Equatable> {
  case none(T)
  case will(T)
  case did(T)
}

extension Change: Equatable {
  static func ==(left: Change, right: Change) -> Bool {
    switch (left, right) {
    case (.none(let a), .none(let b)): return
      a == b
    case (.will(let a), .will(let b)): return
      a == b
    case (.did(let a), .did(let b)): return
      a == b
    default: return
      false
    }
  }
}

enum RemoteNotificationRegistration {
  case idle
  case attempting
  case token(Data)
  case error(Error)
  case unregistering
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
      backgroundURLSessionAction: .idle,
      fetch: .idle,
      remoteAction: .idle,
      localAction: .idle,
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
      remoteNotificationRegistration: .idle,
      statusBarOrientation: .none(.unknown),
      backgroundTasks: Set(),
      isExperiencingHealthAuthorizationRequest: false,
      isIgnoringUserEvents: false,
      isIdleTimerDisabled: false,
      urlActionOutgoing: .idle,
      sendingEvent: nil,
      sendingAction: .idle,
      isNetworkActivityIndicatorVisible: false,
      iconBadgeNumber: 0,
      supportsShakeToEdit: true,
      minimumBackgroundFetchInterval: .never,
      presentedLocalNotification: nil,
      scheduledLocalNotifications: [],
      registeredUserNotificationSettings: nil,
      isReceivingRemoteControlEvents: false,
      newsStandIconImage: nil,
      shortcutItems: [],
      shouldSaveApplicationState: .idle,
      shouldRestoreApplicationState: .idle,
      shouldLaunch: false,
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

extension Session.Model.BackgroundURLSessionAction: Equatable {
  static func ==(
    left: Session.Model.BackgroundURLSessionAction,
    right: Session.Model.BackgroundURLSessionAction
  ) -> Bool {
    switch (left, right) {
    case (.idle, .idle): return
      true
    case (.progressing(let a), .progressing(let b)): return
      a.0 == b.0
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

extension RemoteNotificationRegistration: Equatable {
  static func ==(
    left: RemoteNotificationRegistration,
    right: RemoteNotificationRegistration
  ) -> Bool {
    switch (left, right) {
    case (.idle, .idle): return true
    case (.token(let a), .token(let b)): return a == b
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

extension Session.Model.URLActionOutgoing: Equatable {
  static func ==(left: Session.Model.URLActionOutgoing, right: Session.Model.URLActionOutgoing) -> Bool {
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

extension Session.Model.FetchInterval {
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
