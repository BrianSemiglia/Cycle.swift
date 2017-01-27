//
//  Cycle.swift
//  Cycle
//
//  Created by Brian Semiglia on 1/2/17.
//  Copyright © 2017 Brian Semiglia. All rights reserved.
//

import UIKit
import RxSwift
import Curry

protocol Reduceable {
  associatedtype Reduced
  func reduced(_: Reduced) -> Reduced
}

class CycledApplicationDelegate<C: SinkSourceConverting>: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
  private var deferred: (() -> Cycle<C>)?
  private var realized: Cycle<C>?
  
  init(handler: C) {
    self.deferred = { Cycle(transformer: handler) }
  }
  
  func application(_ app: UIApplication, didFinishLaunchingWithOptions options: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
    
    window = UIWindow(frame: UIScreen.main.bounds)
    window?.rootViewController = .empty
    window?.makeKeyAndVisible()
    
    // Cycle is deferred to make sure window is ready for drivers.
    realized = deferred?()
    deferred = nil
    
    return true
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
  static var empty: UIViewController {
    let x = UIViewController()
    x.view.backgroundColor = .white
    return x
  }
}
