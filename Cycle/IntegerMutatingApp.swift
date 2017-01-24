//
//  Example.swift
//  Cycle
//
//  Created by Brian Semiglia on 1/20/17.
//  Copyright © 2017 Brian Semiglia. All rights reserved.
//

import Foundation
import RxSwift
import Curry

@UIApplicationMain
class Example: CycledApplicationDelegate<IntegerMutatingApp> {
  init() {
    super.init(
      cycle: Cycle(transformer: IntegerMutatingApp())
    )
  }
}

struct IntegerMutatingApp: SinkSourceConverting {
  enum Cause {
    case screen (ValueToggler.Model)
    case test (String)
  }
  struct Effect {
    var screen: ValueToggler.Model
    var test: String
  }
  func eventsFrom(effects: Observable<Effect>) -> Observable<Cause> { return
    ValueToggler.shared
      .rendered(effects.map { $0.screen })
      .map { Cause.screen($0) }
  }
  func effectsFrom(events: Observable<(Cause, Effect)>) -> Observable<Effect> { return
    events
    .map {
      switch $0.0 {
      case .screen(let e): return e.reduced($0.1)
      case .test(let e): return e.reduced($0.1)
      }
    }
  }
  func start() -> (Cause, Effect) { return
    (
      .screen(ValueToggler.Model.empty),
      Effect.empty
    )
  }
}

extension IntegerMutatingApp.Effect {
  static var empty: IntegerMutatingApp.Effect { return
    IntegerMutatingApp.Effect(
      screen: .empty,
      test: ""
    )
  }
}

extension ValueToggler.Model: Reduceable {
  internal func reduced(_ input: IntegerMutatingApp.Effect) -> IntegerMutatingApp.Effect {
    var edit = input
    edit.screen = self
    if increment.state == .highlighted {
      edit.screen.total = Int(edit.screen.total).map { $0 + 1 }.map(String.init) ?? ""
      edit.screen.increment.state = .enabled
    }
    if decrement.state == .highlighted {
      edit.screen.total = Int(edit.screen.total).map { $0 - 1 }.map(String.init) ?? ""
      edit.screen.decrement.state = .enabled
    }
    return edit
  }
}

extension String: Reduceable {
  func reduced(_ input: IntegerMutatingApp.Effect) -> IntegerMutatingApp.Effect { return
    input
  }
}
