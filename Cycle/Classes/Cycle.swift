//
//  Cycle.swift
//  Cycle
//
//  Created by Brian Semiglia on 1/2/17.
//  Copyright © 2017 Brian Semiglia. All rights reserved.
//

import UIKit
import RxSwift

class CycledApplicationDelegate<T: SinkSourceConverting>: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
  private var deferred: (() -> Cycle<T>)?
  private var realized: Cycle<T>?
  
  init(handler: T) {
    self.deferred = { Cycle(transformer: handler) }
  }
  
  func application(_ app: UIApplication, willFinishLaunchingWithOptions options: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
    
    window = UIWindow(frame: UIScreen.main.bounds)
    window?.rootViewController = .empty
    window?.makeKeyAndVisible()
    
    // Cycle is deferred to make sure window is ready for drivers.
    realized = deferred?()
    deferred = nil
    
    return true
  }
  
  override func forwardingTarget(for aSelector: Selector!) -> Any? {
    return Session.shared
  }
  
  override func responds(to aSelector: Selector!) -> Bool {
    return Session.shared.responds(to: aSelector)
  }
}

class Cycle<E: SinkSourceConverting> {
  var events: Observable<E.Source>?
  var eventsProxy: ReplaySubject<E.Source>?
  var loop: Disposable?
  
  init(transformer: E) {
    eventsProxy = ReplaySubject.create(bufferSize: 1)
    events = transformer.effectsFrom(events: eventsProxy!)
    loop = events!
      .startWith(transformer.start())
      .subscribe { [weak self] in
        self?.eventsProxy?.on($0)
    }
  }
}

protocol SinkSourceConverting {
  associatedtype Source
  func effectsFrom(events: Observable<Source>) -> Observable<Source>
  func start() -> Source
}

extension UIViewController {
  public static var empty: UIViewController {
    let x = UIViewController()
    x.view.backgroundColor = .white
    return x
  }
}
