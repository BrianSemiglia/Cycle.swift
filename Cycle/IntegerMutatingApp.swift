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
  func nextFrom(previous: Observable<Model>) -> Observable<Model> { return
    ValueToggler.shared
      .rendered(previous.map { $0.screen })
      .withLatestFrom(previous) { $0.0.reduced($0.1) }
  }
  func start() -> Model { return
      Model.empty
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

extension ValueToggler.Model {
  internal func reduced(_ input: IntegerMutatingApp.Model) -> IntegerMutatingApp.Model {
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

extension String {
  func reduced(_ input: IntegerMutatingApp.Model) -> IntegerMutatingApp.Model { return
    input
  }
}
