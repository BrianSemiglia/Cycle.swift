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

class CycledApplicationDelegate<T: SinkSourceConverting>: UIResponder, UIApplicationDelegate {
  
  private var cycle: Cycle<T>
  var window: UIWindow?
  
  init(filter: T) {
    window = UIWindow(frame: UIScreen.main.bounds, root: .empty)
    window?.makeKeyAndVisible()
    // Cycle is deferred to make sure window is ready for drivers.
    cycle = Cycle(
      transformer: filter,
      host: UIApplication.shared
    )
  }
  
  override func forwardingTarget(for input: Selector!) -> Any? { return
    cycle.application
  }
  
  override func responds(to input: Selector!) -> Bool { return
    cycle.application.responds(to: input) == true
  }
}

extension UIWindow {
  convenience init(frame: CGRect, root: UIViewController) {
    self.init(frame: frame)
    rootViewController = root
  }
}

final class Cycle<E: SinkSourceConverting> {
  fileprivate var events: Observable<E.Source>?
  fileprivate var eventsProxy: ReplaySubject<E.Source>?
  fileprivate var loop: Disposable?
  fileprivate let application: RxUIApplication
  init(transformer: E, host: UIApplication) {
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

protocol SinkSourceConverting {
  associatedtype Source: Initializable
  associatedtype Drivers: CycleDrivable
  func effectsFrom(events: Observable<Source>, drivers: Drivers) -> Observable<Source>
}

protocol CycleDrivable: Initializable, RxUIApplicationStoring {}

protocol Initializable {
  init()
}

protocol RxUIApplicationStoring {
  var application: RxUIApplication! { get set } // Set internally by Cycle
}

extension UIViewController {
  public static var empty: UIViewController {
    let x = UIViewController()
    x.view.backgroundColor = .white
    return x
  }
}
