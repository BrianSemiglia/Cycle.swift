//
//  ShortcutActions.swift
//  Cycle
//
//  Created by Brian Semiglia on 2/9/17.
//  Copyright © 2017 Brian Semiglia. All rights reserved.
//

import Foundation
import RxSwift

class ShortcutActionsExampleDelegate: CycledApplicationDelegate<ShortcutActionsExample> {
  init() {
    super.init(
      filter: ShortcutActionsExample()
    )
  }
}

struct ShortcutActionsExample: SinkSourceConverting {
  struct Model: Initializable {
    var application = RxUIApplication.Model.empty
    var async = Timer.Model.empty
  }
  struct Drivers: CycleDrivable {
    let timer = Timer(.empty)
    var application: RxUIApplication!
  }
  func effectsFrom(events: Observable<Model>, drivers: Drivers) -> Observable<Model> {
    
    let application = drivers.application
    .rendered(events.map { $0.application })
    .withLatestFrom(events) { ($0.0, $0.1) }
    .reduced()
    
    let timer = drivers.timer
    .rendered(events.map { $0.async })
    .withLatestFrom(events) { ($0.0, $0.1) }
    .reduced()
    
    return Observable.of(application, timer).merge()
  }
}

extension ShortcutActionsExample.Model {
  static var empty: ShortcutActionsExample.Model { return
    ShortcutActionsExample.Model(
      application: .empty,
      async: .empty
    )
  }
}

extension ObservableType where E == (RxUIApplication.Model, ShortcutActionsExample.Model) {
  func reduced() -> Observable<ShortcutActionsExample.Model> { return
    map { event, context in
      
      var e = event
      if case .pre(.resigned) = e.state {
        e.shortcutActions = Array(0...arc4random_uniform(3)).map {
          RxUIApplication.Model.ShortcutAction(
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
      output.application = e
      return output
    }
  }
}

extension ObservableType where E == (Timer.Model, ShortcutActionsExample.Model) {
  func reduced() -> Observable<ShortcutActionsExample.Model> { return
    map { event, global in

      var s = global.application
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
      output.application = s
      output.async = event
      return output
    }
  }
}
