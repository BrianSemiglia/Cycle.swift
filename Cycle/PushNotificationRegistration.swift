//
//  PushNotificationRegistration.swift
//  Cycle
//
//  Created by Brian Semiglia on 2/14/17.
//  Copyright © 2017 Brian Semiglia. All rights reserved.
//

import Foundation
import RxSwift

class PushNotificationRegistrationDelegate: CycledApplicationDelegate<PushNotificationRegistration> {
  init() {
    super.init(
      filter: PushNotificationRegistration()
    )
  }
}

struct PushNotificationRegistration: SinkSourceConverting {
  struct Model: Initializable {
    var session = Session.Model.empty
  }
  struct Drivers: CycleDrivable {
    var session: Session!
  }
  func effectsFrom(events: Observable<Model>, drivers: Drivers) -> Observable<Model> { return
    drivers.session
      .rendered(events.map { $0.session })
      .withLatestFrom(events) { ($0.0, $0.1) }
      .reduced()
  }
}

extension PushNotificationRegistration.Model {
  static var empty: PushNotificationRegistration.Model { return
    PushNotificationRegistration.Model(
      session: .empty
    )
  }
}

extension ObservableType where E == (session: Session.Model, push: PushNotificationRegistration.Model) {
  func reduced() -> Observable<PushNotificationRegistration.Model> { return
    map { event, context in
      var edit = event
      switch (event.state, context.session.state) {
      case (.currently(.active), .currently(.launched)): // did change
        if case .none = event.remoteNotificationRegistration {
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
        edit.remoteNotifications = event.remoteNotifications.flatMap {
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
      output.session = edit
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
