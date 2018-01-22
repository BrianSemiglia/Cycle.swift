//
//  Example.swift
//  Cycle
//
//  Created by Brian Semiglia on 1/20/17.
//  Copyright © 2017 Brian Semiglia. All rights reserved.
//

import Foundation
import Cycle
import RxSwift

@UIApplicationMain
class Example: CycledApplicationDelegate<IntegerMutatingApp> {
  init() {
    super.init(
      router: IntegerMutatingApp()
    )
  }
}

struct IntegerMutatingApp: IORouter {
  static let seed = Model()
  struct Model {
    var screen = ValueToggler.Model.empty
    var application = RxUIApplication.Model.empty
  }
  struct Drivers: UIApplicationDelegateProviding, ScreenDrivable {
    let screen: ValueToggler
    let application: RxUIApplication
  }
  func driversFrom(seed: IntegerMutatingApp.Model) -> IntegerMutatingApp.Drivers { return
    Drivers(
      screen: ValueToggler(),
      application: RxUIApplication(initial: seed.application)
    )
  }
  func effectsOfEventsCapturedAfterRendering(
    incoming: Observable<Model>,
    to drivers: Drivers
  ) -> Observable<Model> { return
    Observable.merge([
      drivers
        .screen
        .eventsCapturedAfterRendering(incoming.map { $0.screen })
        .withLatestFrom(incoming) { ($0.0, $0.1) }
        .reduced()
      ,
      drivers
        .application
        .eventsCapturedAfterRendering(incoming.map { $0.application })
        .withLatestFrom(incoming) { ($0.0, $0.1) }
        .reduced()
    ])
  }
}

extension IntegerMutatingApp.Model {
  static var empty: IntegerMutatingApp.Model { return
    IntegerMutatingApp.Model(
      screen: .empty,
      application: .empty
    )
  }
}

extension ObservableType where E == (ValueToggler.Model, IntegerMutatingApp.Model) {
  func reduced() -> Observable<IntegerMutatingApp.Model> { return
    map { event, global in
      var x = global
      x.screen = event
      if event.increment.state == .highlighted {
        x.screen.total = Int(x.screen.total).map { $0 + 1 }.map(String.init) ?? ""
        x.screen.increment.state = .enabled
      }
      if event.decrement.state == .highlighted {
        x.screen.total = Int(x.screen.total).map { $0 - 1 }.map(String.init) ?? ""
        x.screen.decrement.state = .enabled
      }
      return x
    }
  }
}

extension ObservableType where E == (RxUIApplication.Model, IntegerMutatingApp.Model) {
  func reduced() -> Observable<IntegerMutatingApp.Model> { return
    map { event, global in
      var c = global
      var model = event
      model.shouldLaunch = true
      c.application = model
      var s = c.screen
      if case .pre(.active(.some)) = event.session.state {
        s.total = "55"
      }
      c.screen = s
      return c
    }
  }
}
