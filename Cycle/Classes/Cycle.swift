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
  
  init(cycle: @autoclosure @escaping () -> Cycle<C>) {
    self.deferred = cycle
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
  var effects: Observable<E.Sink>?
  var events: Observable<E.Source>?
  var eventsProxy: ReplaySubject<(E.Source, E.Sink)>?
  var loop: Disposable?
  
  init(transformer: E) {
    eventsProxy = ReplaySubject.create(bufferSize: 1)
    effects = transformer.effectsFrom(events: eventsProxy!)
    events = transformer.eventsFrom(effects: effects!)
    loop = events!
      .withLatestFrom(effects!) { ($0, $1) }
      .startWith(transformer.start())
      .subscribe { [weak self] in
        self?.eventsProxy?.on($0)
    }
  }
}

protocol SinkSourceConverting {
  associatedtype Sink
  associatedtype Source
  func eventsFrom(effects: Observable<Sink>) -> Observable<Source>
  func effectsFrom(events: Observable<(Source, Sink)>) -> Observable<Sink>
  func start() -> (Source, Sink)
}

extension UIViewController {
  static var empty: UIViewController {
    let x = UIViewController()
    x.view.backgroundColor = .white
    return x
  }
}
