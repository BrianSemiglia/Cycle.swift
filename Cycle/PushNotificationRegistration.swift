//
//  PushNotificationRegistration.swift
//  Cycle
//
//  Created by Brian Semiglia on 2/14/17.
//  Copyright © 2017 Brian Semiglia. All rights reserved.
//

import Foundation
import RxSwift

@UIApplicationMain
class PushNotificationRegistrationDelegate: CycledApplicationDelegate<PushNotificationRegistration> {
  init() {
    super.init(
      filter: PushNotificationRegistration()
    )
  }
}

struct PushNotificationRegistration: SinkSourceConverting {
  struct Model {
    var session: Session.Model
  }
  func effectsFrom(events: Observable<Model>, session: Session) -> Observable<Model> { return
    session
      .rendered(events.map { $0.session })
      .withLatestFrom(events) { ($0.0, $0.1) }
      .reduced()
  }
  func start() -> Model { return
    .empty
  }
}

extension PushNotificationRegistration.Model {
  static var empty: PushNotificationRegistration.Model { return
    PushNotificationRegistration.Model(
      session: .empty
    )
  }
}

extension ObservableType where E == (Session.Model, PushNotificationRegistration.Model) {
  func reduced() -> Observable<PushNotificationRegistration.Model> { return
    map { event, global in
      
      var e = event
      switch e.state {
      case .did(.active):
        switch e.remoteNotificationRegistration {
        case .none:
          e.remoteNotificationRegistration = .attempting
        default:
          break
        }
      case .none(.active):
        switch e.remoteNotificationRegistration {
        case .some(let token):
          print(token)
//          e.remoteNotificationRegistration = .none
        case .error(let a):
          print(a)
        default:
          break
        }
        e.remoteNotifications = e.remoteNotifications.flatMap {
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
      var output = global
      output.session = e
      return output
    }
  }
}
