//
//  ShortcutItems.swift
//  Cycle
//
//  Created by Brian Semiglia on 2/9/17.
//  Copyright © 2017 Brian Semiglia. All rights reserved.
//

import Foundation
import RxSwift

class ShortcutItemsExampleDelegate: CycledApplicationDelegate<ShortcutItemsExample> {
  init() {
    super.init(
      filter: ShortcutItemsExample()
    )
  }
}

struct ShortcutItemsExample: SinkSourceConverting {
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

extension ShortcutItemsExample.Model {
  static var empty: ShortcutItemsExample.Model { return
    ShortcutItemsExample.Model(
      session: .empty,
      async: .empty
    )
  }
}

extension ObservableType where E == (Session.Model, ShortcutItemsExample.Model) {
  func reduced() -> Observable<ShortcutItemsExample.Model> { return
    map { event, global in
      
      var e = event
      if case .will(.resigned) = e.state {
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
      
      var a = global.async
      a.operations = e.shortcutItems.flatMap {
        if case .progressing(let a) = $0.action {
          return Timer.Model.Operation(
            id: a.id.type,
            running: true,
            length: 1
          )
        } else {
          return nil
        }
      }
      
      var output = global
      output.async = a
      output.session = e
      return output
    }
  }
}

extension ObservableType where E == (Timer.Model, ShortcutItemsExample.Model) {
  func reduced() -> Observable<ShortcutItemsExample.Model> { return
    map { event, global in

      var s = global.session
      s.shortcutItems = s.shortcutItems.map { item in
        if let _ = event.operations.filter({ $0.id == item.value.type && $0.running == false }).first {
          if case .progressing(let a) = item.action {
            var edit = item
            edit.action = .complete(a)
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
