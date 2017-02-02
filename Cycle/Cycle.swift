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
  
  private var deferred: (() -> Cycle<T>)?
  private var realized: Cycle<T>?
  private let session: Session
  var window: UIWindow?
  
  init(filter: T, session: Session) {
    self.session = session
    deferred = { Cycle(transformer: filter) }
  }
  
  func application(
    _ application: UIApplication,
    willFinishLaunchingWithOptions options: [UIApplicationLaunchOptionsKey : Any]? = nil
  ) -> Bool {
    
    window = UIWindow(frame: UIScreen.main.bounds, root: .empty)
    window?.makeKeyAndVisible()

    // Cycle is deferred to make sure window is ready for drivers.
    realized = deferred?()
    deferred = nil
    
    return session.application(
      application,
      willFinishLaunchingWithOptions: options
    )
  }
  
  override func forwardingTarget(for aSelector: Selector!) -> Any? {
    return session
  }
  
  override func responds(to aSelector: Selector!) -> Bool {
    return session.responds(to: aSelector)
  }
}

extension UIWindow {
  convenience init(frame: CGRect, root: UIViewController) {
    self.init(frame: frame)
    rootViewController = root
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
