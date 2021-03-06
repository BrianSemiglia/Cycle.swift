//
//  ShortcutActions.swift
//  Cycle
//
//  Created by Brian Semiglia on 2/9/17.
//  Copyright © 2017 Brian Semiglia. All rights reserved.
//

import Foundation
import Cycle
import RxSwift
import RxUIApplicationDelegate

@UIApplicationMain
class ShortcutActionsExampleDelegate: CycledApplicationDelegate<ShortcutActionsExample> {
  override init() {
    super.init(
      router: ShortcutActionsExample()
    )
  }
}

struct ScreenDriver: RootViewProviding {
  let root = UIViewController.empty
}

struct ShortcutActionsExample: IORouter {
  static let seed = Model()
  struct Model {
    var application = RxUIApplicationDelegate.Model.empty
    var async = Timer.Model.empty
  }
  struct Drivers: MainDelegateProviding, ScreenDrivable {
    let screen: ScreenDriver
    let timer: Timer
    let application: RxUIApplicationDelegate
  }
  func driversFrom(seed: ShortcutActionsExample.Model) -> ShortcutActionsExample.Drivers {
    return Drivers(
      screen: ScreenDriver(),
      timer: Timer(seed.async),
      application: RxUIApplicationDelegate(initial: seed.application)
    )
  }
  func effectsOfEventsCapturedAfterRendering(
    incoming: Observable<Model>,
    to drivers: Drivers
  ) -> Observable<Model> { return
    Observable.merge([
      drivers
        .application
        .eventsCapturedAfterRendering(incoming.map { $0.application })
        .withLatestFrom(incoming) { ($0, $1) }
        .reduced()
      ,
      drivers
        .timer
        .eventsCapturedAfterRendering(incoming.map { $0.async })
        .withLatestFrom(incoming) { ($0, $1) }
        .reduced()
    ])
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

extension ObservableType where E == (RxUIApplicationDelegate.Model, ShortcutActionsExample.Model) {
  func reduced() -> Observable<ShortcutActionsExample.Model> { return
    map { event, context in
      
      var e = event
      if case .pre(.resigned) = e.session.state {
        e.shortcutActions = Array(0...arc4random_uniform(3)).map {
          RxUIApplicationDelegate.Model.ShortcutAction(
            item: UIApplicationShortcutItem(
              type: "test " + String($0),
              localizedTitle: "test " + String($0)
            ),
            state: .idle
          )
        }
      }
      
      var a = context.async
      a.operations = e.shortcutActions.compactMap {
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

extension UIViewController {
  public static var empty: UIViewController {
    let x = UIViewController()
    x.view.backgroundColor = .white
    return x
  }
}
