//
//  Cycle.swift
//  Cycle
//
//  Created by Brian Semiglia on 1/2/17.
//  Copyright © 2017 Brian Semiglia. All rights reserved.
//

#if os(iOS) || os(tvOS)

import UIKit
import RxSwift

open class CycledApplicationDelegate<T: IORouter>: UIResponder, UIApplicationDelegate {
  
  private var cycle: Cycle<T>
  public var window: UIWindow?
  
  public override init() {
    fatalError("CycledApplicationDelegate must be instantiated with a router.")
  }
  
  public init(router: T) {
    cycle = Cycle(router: router)
    super.init()
  }
  
  public func application(
    _ application: UIApplication,
    willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil
  ) -> Bool {
    window = UIWindow(frame: UIScreen.main.bounds, root: cycle.root)
    window?.makeKeyAndVisible()
    return cycle.delegate.application!(
      application,
      willFinishLaunchingWithOptions: launchOptions
    )
  }
  
  override open func forwardingTarget(for input: Selector!) -> Any? { return
    cycle.delegate
  }
  
  override open func responds(to input: Selector!) -> Bool { return
    cycle.delegate.responds(to: input)
  }
}

extension UIWindow {
  convenience init(frame: CGRect, root: UIViewController) {
    self.init(frame: frame)
    rootViewController = root
  }
}

#elseif os(watchOS)

import WatchKit
import RxSwift

open class CycledApplicationDelegate<T: IORouter>: NSObject, WKExtensionDelegate {
  
  private var cycle: Cycle<T>
  
  public override init() {
    fatalError("CycledApplicationDelegate must be instantiated with a router.")
  }
  
  public init(router: T) {
    cycle = Cycle(router: router)
    super.init()
  }
  
  override open func forwardingTarget(for input: Selector!) -> Any? { return
    cycle.delegate
  }
  
  override open func responds(to input: Selector!) -> Bool { return
    cycle.delegate.responds(to: input)
  }
}

#elseif os(macOS)

import AppKit
import RxSwift

open class CycledApplicationDelegate<T: IORouter>: NSObject, NSApplicationDelegate {
  
  private var cycle: Cycle<T>
  public var main: NSWindowController? // <-- change to (NSWindow, NSViewController) combo to avoid internal storyboard use below
  
  public override init() {
    fatalError("CycledApplicationDelegate must be instantiated with a router.")
  }

  public init(router: T) {
    cycle = Cycle(router: router)
    super.init()
  }

  public func applicationWillFinishLaunching(_ notification: Notification) {
    main = NSStoryboard(
      name: NSStoryboard.Name(rawValue: "Main"),
      bundle: nil
    )
    .instantiateController(
      withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "MainWindow")
    )
    as? NSWindowController
    main?.window?.contentViewController = cycle.root
    main?.window?.makeKeyAndOrderFront(nil)
  }
  
  override open func forwardingTarget(for input: Selector!) -> Any? { return
    cycle.delegate
  }
  
  override open func responds(to input: Selector!) -> Bool {
    if input == #selector(applicationWillFinishLaunching(_:)) {
      applicationWillFinishLaunching(
        Notification(
          name: Notification.Name(
            rawValue: ""
          )
        )
      )
    }
    return cycle.delegate.responds(
      to: input
    )
  }
  
}

#endif

public final class Cycle<E: IORouter> {
  private var output: Observable<E.Frame>?
  private var inputProxy: ReplaySubject<E.Frame>?
  private let cleanup = DisposeBag()
  private let drivers: E.Drivers
  fileprivate let delegate: AppDelegate
  fileprivate let root: AppView
  public required init(router: E) {
    inputProxy = ReplaySubject.create(
      bufferSize: 1
    )
    drivers = router.driversFrom(seed: E.seed)
    root = drivers.screen.root
    delegate = drivers.application
    output = router.effectsOfEventsCapturedAfterRendering(
      incoming: inputProxy!,
      to: drivers
    )
    // `.startWith` is redundant, but necessary to kickoff cycle
    // Possibly removed if `output` was BehaviorSubject?
    // Not sure how to `merge` observables to single BehaviorSubject though.
    output?
      .startWith(E.seed)
      .subscribe(self.inputProxy!.on)
      .disposed(by: cleanup)
  }
}

public protocol IORouter {
  
  /*
   Defines schema and initial values of application model.
   */
  associatedtype Frame
  static var seed: Frame { get }
  
  /*
   Defines drivers that handle effects, produce events. Requires two default drivers:
   
   1. let application: UIApplicationDelegateProviding - can serve as UIApplicationDelegate
   2. let screen: ScreenDrivable - can provide a root UIViewController
   
   A default UIApplicationDelegateProviding driver, RxUIApplicationDelegate, is included with Cycle.
   */
  associatedtype Drivers: MainDelegateProviding, ScreenDrivable
  
  /*
   Instantiates drivers with initial model. Necessary to for drivers that require initial values.
   */
  func driversFrom(seed: Frame) -> Drivers
  
  /*
   Returns a stream of Models created by rendering the incoming stream of effects to Drivers and then capturing and transforming Driver events into the Model type.
   */
  func effectsOfEventsCapturedAfterRendering(
    incoming: Observable<Frame>,
    to drivers: Drivers
  ) -> Observable<Frame>
  
}

public protocol ScreenDrivable {
  associatedtype Driver: RootViewProviding
  var screen: Driver { get }
}

public protocol RootViewProviding {
  #if os(macOS)
  var root: NSViewController { get }
  #elseif os(iOS) || os(tvOS)
  var root: UIViewController { get }
  #elseif os(watchOS)
  var root: WKInterfaceController { get }
  #endif
}

public protocol MainDelegateProviding {
  #if os(macOS)
  associatedtype Delegate: NSApplicationDelegate
  #elseif os(iOS) || os(tvOS)
  associatedtype Delegate: UIApplicationDelegate
  #elseif os(watchOS)
  associatedtype Delegate: WKExtensionDelegate
  #endif
  var application: Delegate { get }
}

#if os(macOS)
typealias AppDelegate = NSApplicationDelegate
#elseif os(iOS) || os(tvOS)
typealias AppDelegate = UIApplicationDelegate
#elseif os(watchOS)
typealias AppDelegate = WKExtensionDelegate
#endif

#if os(macOS)
typealias AppView = NSViewController
#elseif os(iOS) || os(tvOS)
typealias AppView = UIViewController
#elseif os(watchOS)
typealias AppView = WKInterfaceController
#endif
