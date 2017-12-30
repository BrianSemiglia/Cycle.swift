//
//  URLActionOutgoing.swift
//  Cycle
//
//  Created by Brian Semiglia on 2/13/17.
//  Copyright © 2017 Brian Semiglia. All rights reserved.
//

import Foundation
import Cycle
import RxSwift

@UIApplicationMain
class URLActionOutgoingDelegate: CycledApplicationDelegate<URLActionOutgoing> {
  init() {
    super.init(
      router: URLActionOutgoing()
    )
  }
}

struct ScreenDriver: UIViewControllerProviding {
  let root = UIViewController.empty
}

struct URLActionOutgoing: IORouter {
  struct Model: Initializable {
    var application = RxUIApplication.Model.empty
  }
  struct Drivers: UIApplicationDelegateProviding, ScreenDrivable {
    let screen: ScreenDriver
    let application: RxUIApplication
  }
  func driversFrom(initial: URLActionOutgoing.Model) -> URLActionOutgoing.Drivers {
    return Drivers(
      screen: ScreenDriver(),
      application: RxUIApplication(initial: initial.application)
    )
  }
  func effectsOfEventsCapturedAfterRendering(
    incoming: Observable<Model>,
    to drivers: Drivers
  ) -> Observable<Model> { return
    drivers
      .application
      .eventsCapturedAfterRendering(incoming.map { $0.application })
      .withLatestFrom(incoming) { ($0.0, $0.1) }
      .reduced()
  }
}

extension URLActionOutgoing.Model {
  static var empty: URLActionOutgoing.Model { return
    URLActionOutgoing.Model(
      application: .empty
    )
  }
}

extension ObservableType where E == (RxUIApplication.Model, URLActionOutgoing.Model) {
  func reduced() -> Observable<URLActionOutgoing.Model> { return
    map { event, context in
      
      var e = event
      if
      case .currently(.active(.first)) = context.application.session.state,
      case .currently(.active) = event.session.state {
        e.urlActionOutgoing = .attempting(URL(string: "https://www.duckduckgo.com")!)
      }
      
      var output = context
      output.application = e
      return output
    }
  }
}

extension UIViewController {
  public static var empty: UIViewController {
    let x = UIViewController()
    x.view.backgroundColor = .white
    return x
  }
}
