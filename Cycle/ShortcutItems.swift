//
//  ShortcutActions.swift
//  Cycle
//
//  Created by Brian Semiglia on 2/9/17.
//  Copyright © 2017 Brian Semiglia. All rights reserved.
//

import Foundation
import RxSwift

@UIApplicationMain
class ShortcutActionsExampleDelegate: CycledApplicationDelegate<ShortcutActionsExample> {
  init() {
    super.init(
      filter: ShortcutActionsExample()
    )
  }
}

struct ShortcutActionsExample: SinkSourceConverting {
  struct Model {
    var session: Session.Model
    var async: Timer.Model
  }
  func effectsFrom(events: Observable<Model>, session: Session) -> Observable<Model> {
    
    let session = session
    .rendered(events.map { $0.session })
    .withLatestFrom(events) { ($0.0, $0.1) }
    .reduced()
    
    let timer = Timer.shared
    .rendered(events.map { $0.async })
    .withLatestFrom(events) { ($0.0, $0.1) }
    .reduced()
    
    return Observable.of(session, timer).merge()
  }
  func start() -> Model { return
    .empty
  }
}

extension ShortcutActionsExample.Model {
  static var empty: ShortcutActionsExample.Model { return
    ShortcutActionsExample.Model(
      session: .empty,
      async: .empty
    )
  }
}

extension ObservableType where E == (Session.Model, ShortcutActionsExample.Model) {
  func reduced() -> Observable<ShortcutActionsExample.Model> { return
    map { event, context in
      
      var e = event
      if case .pre(.resigned) = e.state {
        e.shortcutActions = Array(0...arc4random_uniform(3)).map {
          Session.Model.ShortcutAction(
            item: UIApplicationShortcutItem(
              type: "test " + String($0),
              localizedTitle: "test " + String($0)
            ),
            state: .idle
          )
        }
      }
      
      var a = context.async
      a.operations = e.shortcutActions.flatMap {
        if case .progressing = $0.state {
          return Timer.Model.Operation(
            id: $0.item.type,
            running: true,
            length: 1
          )
        } else {
          return nil
        }
      }
      
      var output = context
      output.async = a
      output.session = e
      return output
    }
  }
}

extension ObservableType where E == (Timer.Model, ShortcutActionsExample.Model) {
  func reduced() -> Observable<ShortcutActionsExample.Model> { return
    map { event, global in

      var s = global.session
      s.shortcutActions = s.shortcutActions.map { item in
        if let _ = event.operations.filter({ $0.id == item.item.type && $0.running == false }).first {
          if case .progressing(let a) = item.state {
            var edit = item
            edit.state = .complete(true, a)
            return edit
          } else {
            return item
          }
        } else {
          return item
        }
      }
      
      var output = global
      output.session = s
      output.async = event
      return output
    }
  }
}
