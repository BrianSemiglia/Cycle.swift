//
//  ShortcutItems.swift
//  Cycle
//
//  Created by Brian Semiglia on 2/9/17.
//  Copyright © 2017 Brian Semiglia. All rights reserved.
//

import Foundation
import RxSwift

@UIApplicationMain
class ShortcutItemsExampleDelegate: CycledApplicationDelegate<ShortcutItemsExample> {
  init() {
    super.init(
      filter: ShortcutItemsExample(),
      session: Session.shared
    )
  }
}

struct ShortcutItemsExample: SinkSourceConverting {
  struct Model {
    var session: Session.Model
  }
  func effectsFrom(events: Observable<Model>) -> Observable<Model> { return
    Session.shared
    .rendered(events.map { $0.session })
    .withLatestFrom(events) { ($0.0, $0.1) }
    .reduced()
  }
  func start() -> Model { return
    .empty
  }
}

extension ShortcutItemsExample.Model {
  static var empty: ShortcutItemsExample.Model { return
    ShortcutItemsExample.Model(
      session: .empty
    )
  }
}

extension ObservableType where E == (Session.Model, ShortcutItemsExample.Model) {
  func reduced() -> Observable<ShortcutItemsExample.Model> { return
    map { event, global in
      var g = global
      var e = event
      if case .will(let a) = e.state, case .resigned = a {
        e.shortcutItems = Array(0...arc4random_uniform(3)).map {
          Session.Model.ShortcutItem(
            value: UIApplicationShortcutItem(
              type: "test " + String($0),
              localizedTitle: "test " + String($0)
            ),
            action: .idle
          )
        }
      }
      g.session = e
      return g
    }
  }
}
