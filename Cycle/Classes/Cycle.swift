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
    window = UIWindow(frame: UIScreen.main.bounds, root: .empty)
    window?.makeKeyAndVisible()
    // Cycle is deferred to make sure window is ready for drivers.
    cycle = Cycle(
      transformer: filter,
      host: UIApplication.shared
    )
  }
  
  override open func forwardingTarget(for input: Selector!) -> Any? { return
    cycle.application
  }
  
  override open func responds(to input: Selector!) -> Bool { return
    cycle.application.responds(to: input) == true
  }
}

extension UIWindow {
  convenience init(frame: CGRect, root: UIViewController) {
    self.init(frame: frame)
    rootViewController = root
  }
}

public final class Cycle<E: SinkSourceConverting> {
  fileprivate var events: Observable<E.Source>?
  fileprivate var eventsProxy: ReplaySubject<E.Source>?
  fileprivate var loop: Disposable?
  fileprivate let application: RxUIApplication
  public init(transformer: E, host: UIApplication) {
    eventsProxy = ReplaySubject.create(
      bufferSize: 1
    )
    application = RxUIApplication(
      intitial: .empty,
      application: host
    )
    events = transformer.effectsFrom(
      events: eventsProxy!,
      drivers: {
        var x = E.Drivers()
        x.application = application
        return x
      }()
    )
    loop = events!
      .startWith(E.Source())
      .subscribe { [weak self] in
        self?.eventsProxy?.on($0)
    }
  }
}

public protocol SinkSourceConverting {
  associatedtype Source: Initializable
  associatedtype Drivers: CycleDrivable
  func effectsFrom(events: Observable<Source>, drivers: Drivers) -> Observable<Source>
}

public protocol CycleDrivable: Initializable, RxUIApplicationStoring {}

public protocol Initializable {
  init()
}

public protocol RxUIApplicationStoring {
  var application: RxUIApplication! { get set } // Set internally by Cycle
}

extension UIViewController {
  public static var empty: UIViewController {
    let x = UIViewController()
    x.view.backgroundColor = .white
    return x
  }
}
