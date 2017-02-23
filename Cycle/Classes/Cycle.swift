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
    cycle = Cycle(transformer: filter)
    super.init()
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
  fileprivate var events: Observable<E.Source>?
  fileprivate var eventsProxy: ReplaySubject<E.Source>?
  fileprivate var loop: Disposable?
  fileprivate let delegate: UIApplicationDelegate
  public required init(transformer: E) {
    eventsProxy = ReplaySubject.create(
      bufferSize: 1
    )
    var x = E.Drivers()
    delegate = x.application
    events = transformer.effectsFrom(
      events: eventsProxy!,
      drivers: x
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

public protocol CycleDrivable: Initializable, UIApplicationProviding {}

public protocol Initializable {
  init()
}

public protocol UIApplicationProviding {
  associatedtype Delegate: UIApplicationDelegate
  var application: Delegate { get }
}

extension UIViewController {
  public static var empty: UIViewController {
    let x = UIViewController()
    x.view.backgroundColor = .white
    return x
  }
}
