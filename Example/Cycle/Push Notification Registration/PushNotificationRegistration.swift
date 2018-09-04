//
//  PushNotificationRegistration.swift
//  Cycle
//
//  Created by Brian Semiglia on 2/14/17.
//  Copyright © 2017 Brian Semiglia. All rights reserved.
//

import Foundation
import Cycle
import RxSwift

@UIApplicationMain
class PushNotificationRegistrationDelegate: CycledApplicationDelegate<PushNotificationRegistration> {
  init() {
    super.init(
      router: PushNotificationRegistration()
    )
  }
}

struct ScreenDriver: UIViewControllerProviding {
  let root = UIViewController.empty
}

struct PushNotificationRegistration: IORouter {
  static let seed = Model()
  struct Model {
    var application = RxUIApplication.Model.empty
  }
  struct Drivers: UIApplicationDelegateProviding, ScreenDrivable {
    let screen: ScreenDriver
    let application: RxUIApplication
  }
  func driversFrom(seed: PushNotificationRegistration.Model) -> PushNotificationRegistration.Drivers { return
    Drivers(
      screen: ScreenDriver(),
      application: RxUIApplication(initial: seed.application)
    )
  }
  func effectsOfEventsCapturedAfterRendering(
    incoming: Observable<Model>,
    to drivers: Drivers
  ) -> Observable<Model> { return
    drivers
      .application
      .eventsCapturedAfterRendering(incoming.map { $0.application })
      .withLatestFrom(incoming) { ($0, $1) }
      .reduced()
  }
}

extension PushNotificationRegistration.Model {
  static var empty: PushNotificationRegistration.Model { return
    PushNotificationRegistration.Model(
      application: .empty
    )
  }
}

extension ObservableType where E == (application: RxUIApplication.Model, push: PushNotificationRegistration.Model) {
  func reduced() -> Observable<PushNotificationRegistration.Model> { return
    map { event, context in
      var edit = event
      switch (event.session.state, context.application.session.state) {
      case (.currently(.active), .pre(.active(.first))):
        if case .idle = event.remoteNotificationRegistration {
          edit.remoteNotificationRegistration = .attempting
        }
      case (.currently(.active), .currently(.active)):
        switch event.remoteNotificationRegistration {
        case .some(let token):
          print(token)
        case .error(let error):
          print(error)
        default: break
        }
        edit.remoteNotifications = event.remoteNotifications.compactMap {
          switch $0.state {
          case .progressing(let completion):
            var edit = $0
            edit.state = .complete(.noData, completion)
            return nil
          default:
            return $0
          }
        }
      default:
        break
      }
      var output = context
      output.application = edit
      return output
    }
  }
}

extension ObservableType {
  func withPrevious() -> Observable<(old: E?, new: E)> { return
    flatMap { latest in
      self
        .scan((nil, nil)) { sum, x -> (E?, E?) in
          (sum.1, x)
        }
        .map {
          if let new = $0.1, let old = $0.0 {
            return (old, new)
          } else {
            return (nil, latest)
          }
      }
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
