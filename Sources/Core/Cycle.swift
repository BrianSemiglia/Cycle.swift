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

public final class Cycle<E: IORouter> {
  private var output: Observable<E.Frame>?
  private var inputProxy: ReplaySubject<E.Frame>?
  private let cleanup = DisposeBag()
  private let drivers: E.Drivers
  fileprivate let delegate: UIApplicationDelegate
  fileprivate let root: UIViewController
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
  associatedtype Drivers: UIApplicationDelegateProviding, ScreenDrivable
  
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
  associatedtype Driver: UIViewControllerProviding
  var screen: Driver { get }
}

public protocol UIViewControllerProviding {
  var root: UIViewController { get }
}

public protocol UIApplicationDelegateProviding {
  associatedtype Delegate: UIApplicationDelegate
  var application: Delegate { get }
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

public final class Cycle<E: IORouter> {
  private var output: Observable<E.Frame>?
  private var inputProxy: ReplaySubject<E.Frame>?
  private let cleanup = DisposeBag()
  private let drivers: E.Drivers
  fileprivate let delegate: NSApplicationDelegate
  fileprivate let root: NSViewController
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
  associatedtype Drivers: UIApplicationDelegateProviding, ScreenDrivable

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
  associatedtype Driver: UIViewControllerProviding
  var screen: Driver { get }
}

public protocol UIViewControllerProviding {
  var root: NSViewController { get }
}

public protocol UIApplicationDelegateProviding {
  associatedtype Delegate: NSApplicationDelegate
  var application: Delegate { get }
}

#endif
