//
//  Cycle.swift
//  Cycle
//
//  Created by Brian Semiglia on 1/2/17.
//  Copyright © 2017 Brian Semiglia. All rights reserved.
//

import UIKit
import RxSwift

open class CycledApplicationDelegate<T: SinkSourceConverting>: UIResponder, UIApplicationDelegate {
  
  private var cycle: Cycle<T>
  public var window: UIWindow?
  
  public init(filter: T) {
    cycle = Cycle(transformer: filter)
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

public final class Cycle<E: SinkSourceConverting> {
  private var events: Observable<E.Source>?
  private var eventsProxy: ReplaySubject<E.Source>?
  private let cleanup = DisposeBag()
  fileprivate let delegate: UIApplicationDelegate
  fileprivate let root: UIViewController
  public required init(transformer: E) {
    eventsProxy = ReplaySubject.create(
      bufferSize: 1
    )
    let drivers = transformer.driversFrom(initial: E.Source())
    root = drivers.screen.root
    delegate = drivers.application
    events = transformer.effectsFrom(
      events: eventsProxy!,
      drivers: drivers
    )
    // `.startWith` is redundant, but necessary to kickoff cycle
    // Possibly removed if `events` was BehaviorSubject?
    // Not sure how to `merge` observables to single BehaviorSubject though.
    events?
      .startWith(E.Source())
      .subscribe { [weak self] in
        self?.eventsProxy?.on($0)
    }.disposed(by: cleanup)
  }
}

public protocol SinkSourceConverting {
  associatedtype Source: Initializable
  associatedtype Drivers: UIApplicationDelegateProviding, ScreenDrivable
  func driversFrom(initial: Source) -> Drivers
  func effectsFrom(events: Observable<Source>, drivers: Drivers) -> Observable<Source>
}

public protocol Initializable {
  init()
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
