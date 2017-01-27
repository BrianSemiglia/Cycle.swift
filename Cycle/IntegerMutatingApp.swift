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
    super.init(handler: IntegerMutatingApp())
  }
}

struct IntegerMutatingApp: SinkSourceConverting {
  struct Model {
    var screen: ValueToggler.Model
    var test: String
  }
  func effectsFrom(events: Observable<Model>) -> Observable<Model> { return
    ValueToggler.shared
      .rendered(events.map { $0.screen })
      .withLatestFrom(events) { ($0.0, $0.1) }
      .reduced()
  }
  func start() -> Model { return
      .empty
  }
}

extension IntegerMutatingApp.Model {
  static var empty: IntegerMutatingApp.Model { return
    IntegerMutatingApp.Model(
      screen: .empty,
      test: ""
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

extension String {
  func reduced(_ input: IntegerMutatingApp.Model) -> IntegerMutatingApp.Model { return
    input
  }
}
