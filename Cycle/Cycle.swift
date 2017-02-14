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
  
  private var deferred: ((UIApplication) -> Cycle<T>)?
  private var realized: Cycle<T>?
  var window: UIWindow?
  
  init(filter: T) {
    deferred = { Cycle(transformer: filter, application: $0) }
  }
  
  func application(
    _ application: UIApplication,
    willFinishLaunchingWithOptions options: [UIApplicationLaunchOptionsKey : Any]? = nil
  ) -> Bool {
    
    window = UIWindow(frame: UIScreen.main.bounds, root: .empty)
    window?.makeKeyAndVisible()
    
    // Cycle is deferred to make sure window is ready for drivers.
    realized = deferred?(application)
    deferred = nil
    
    return realized!.session.application(
      application,
      willFinishLaunchingWithOptions: options
    )
  }
  
  override func forwardingTarget(for aSelector: Selector!) -> Any? {
    return realized?.session
  }
  
  override func responds(to aSelector: Selector!) -> Bool {
    return realized?.session.responds(to: aSelector) == true
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
  let session: Session
  init(transformer: E, application: UIApplication) {
    session = Session(model: .empty, application: application)
    eventsProxy = ReplaySubject.create(bufferSize: 1)
    events = transformer.effectsFrom(events: eventsProxy!, session: session)
    loop = events!
      .startWith(transformer.start())
      .subscribe { [weak self] in
        self?.eventsProxy?.on($0)
    }
  }
}

protocol SinkSourceConverting {
  associatedtype Source
  func effectsFrom(events: Observable<Source>, session: Session) -> Observable<Source>
  func start() -> Source
}

extension UIViewController {
  public static var empty: UIViewController {
    let x = UIViewController()
    x.view.backgroundColor = .white
    return x
  }
}
