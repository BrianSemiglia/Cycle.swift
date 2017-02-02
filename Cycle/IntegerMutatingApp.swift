//
//  Example.swift
//  Cycle
//
//  Created by Brian Semiglia on 1/20/17.
//  Copyright © 2017 Brian Semiglia. All rights reserved.
//

import Foundation
import RxSwift

@UIApplicationMain
class Example: CycledApplicationDelegate<IntegerMutatingApp> {
  init() {
    super.init(
      filter: IntegerMutatingApp(),
      session: Session.shared
    )
  }
}

struct IntegerMutatingApp: SinkSourceConverting {
  struct Model {
    var screen: ValueToggler.Model
    var session: Session.Model
  }
  func effectsFrom(events: Observable<Model>) -> Observable<Model> {
    let value = ValueToggler.shared
      .rendered(events.map { $0.screen })
      .withLatestFrom(events) { ($0.0, $0.1) }
      .reduced()
    
    let session = Session.shared
      .rendered(events.map { $0.session })
      .withLatestFrom(events) { ($0.0, $0.1) }
      .reduced()
    
    return Observable.of(value, session).merge()
  }
  func start() -> Model { return
      .empty
  }
}

extension IntegerMutatingApp.Model {
  static var empty: IntegerMutatingApp.Model { return
    IntegerMutatingApp.Model(
      screen: .empty,
      session: .empty
    )
  }
}

extension ObservableType where E == (ValueToggler.Model, IntegerMutatingApp.Model) {
  func reduced() -> Observable<IntegerMutatingApp.Model> { return
    map { event, context in
      var x = context
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

extension ObservableType where E == (Session.Model, IntegerMutatingApp.Model) {
  func reduced() -> Observable<IntegerMutatingApp.Model> { return
    map { event, context in
      var c = context
      var session = event
      session.shouldLaunch = true
      c.session = session
      var s = c.screen
      s.total = c.session.state == .didBecomeActive ? "55" : s.total
      c.screen = s
      return c
    }
  }
}

extension String {
  func reduced(_ input: IntegerMutatingApp.Model) -> IntegerMutatingApp.Model { return
    input
  }
}
