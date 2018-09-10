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
  override init() {
    super.init(
      router: IntegerMutatingApp()
    )
  }
}

struct IntegerMutatingApp: IORouter {
  struct Model {
    var total: Int
    var screen: ValueToggler.Model
    var application: RxUIApplication.Model
  }
  struct Drivers: UIApplicationDelegateProviding, ScreenDrivable {
    let screen: ValueToggler
    let application: RxUIApplication
    let delay: Timer
  }
  static var seed: [Model] { return
    [
      Model(
        total: 0,
        screen: ValueToggler.Model.empty,
        application: RxUIApplication.Model.empty
      )
    ]
  }
  func driversFrom(seed: [Model]) -> IntegerMutatingApp.Drivers { return
    Drivers(
      screen: ValueToggler(),
      application: RxUIApplication(
        initial: seed.first!.application
      ),
      delay: Timer(
        Timer.Model(
          operations: []
        )
      )
    )
  }
  func effectsOfEventsCapturedAfterRendering(
    incoming: Observable<[Model]>,
    to drivers: Drivers
  ) -> Observable<[Model]> {
    
    let screenSynced = incoming.sample(
      Observable<Int>.interval(
        20.0 / 60.0,
        scheduler: MainScheduler.instance
      )
    )
    
    return Observable
      .merge(
        drivers
          .screen
          .eventsCapturedAfterRendering(screenSynced.map { $0.prefiltered() })
          .withLatestFrom(incoming) { ($0, $1) }
//          .intercepted()
          .appended()
//          .togglesDisabledUntilAnimationEnd()
        ,
        drivers
          .application
          .eventsCapturedAfterRendering(screenSynced.map { $0.first!.application })
          .withLatestFrom(incoming) { ($0, $1) }
          .reduced()
        ,
        screenSynced
          .withLatestFrom(incoming)
          .filter { $0.count > 1 }
          .map { $0.tail }
      )
  }
}

extension IntegerMutatingApp.Model {
  static var empty: IntegerMutatingApp.Model { return
    IntegerMutatingApp.Model(
      total: 0,
      screen: .empty,
      application: .empty
    )
  }
}

extension Collection where Element == IntegerMutatingApp.Model {
  func prefiltered() -> ValueToggler.Model { return
    ValueToggler.Model(
      total: String(first!.total),
      increment: first!.screen.increment,
      decrement: first!.screen.decrement
    )
  }
}

extension ObservableType where E == (ValueToggler.Action, IntegerMutatingApp.Frame) {
  func appended() -> Observable<IntegerMutatingApp.Frame> { return
    map { event, global in
      let appended = global
        .last
        .map { $0.total }
        .flatMap { total in
          Array(1...10).map { current -> IntegerMutatingApp.Model in
            var x = global.last!
            if event == .incrementing {
              x.total = x.total + current
              x.screen.increment.state = .enabled
            }
            if event == .decrementing {
              x.total = x.total - current
              x.screen.decrement.state = .enabled
            }
            return x
          }
        }
        .map { global + $0 }
      
      print(appended?.map({ $0.total }) ?? [])
      return appended ?? []
    }
  }
}

extension ObservableType where E == (ValueToggler.Action, IntegerMutatingApp.Frame) {
  func togglesDisabledUntilAnimationEnd() -> Observable<IntegerMutatingApp.Frame> { return
    map { event, global in
      let appended = global
        .last
        .map { $0.total }
        .flatMap { total in
          Array(1...10).map { current -> IntegerMutatingApp.Model in
            var x = global.last!
            switch event {
            case .incrementing:
              x.total = x.total + current
            case .decrementing:
              x.total = x.total - current
            }
            x.screen.increment.state = current == 10 ? .enabled : .disabled
            x.screen.decrement.state = current == 10 ? .enabled : .disabled
            return x
          }
        }
        .map { global + $0 }
      
      print(appended?.map { $0.total } ?? [])
      return appended ?? []
    }
  }
}

extension ObservableType where E == (ValueToggler.Action, IntegerMutatingApp.Frame) {
  func intercepted() -> Observable<IntegerMutatingApp.Frame> { return
    map { event, global in
      
      let valueDelta = event == .incrementing
        ? 10
        : -10
      
      // last: abs(10) - first: abs(20)
      let positionDelta = (global.last!.total + valueDelta) - global.first!.total
      
      let appended = Array(0...abs(positionDelta)).map { current -> IntegerMutatingApp.Model in
        var x = global.first!
        if positionDelta > 0 {
          x.total = x.total + current
          x.screen.increment.state = .enabled
        } else {
          x.total = x.total - current
          x.screen.decrement.state = .enabled
        }
        return x
      }
      
      print(appended.map { $0.total })
      return appended
    }
  }
}

extension Collection {
  var head: Element? { return
    first
  }
}

extension Collection {
  var tail: [Element] { return
    Array(dropFirst())
  }
}

extension ObservableType where E == (RxUIApplication.Model, IntegerMutatingApp.Frame) {
  func reduced() -> Observable<IntegerMutatingApp.Frame> { return
    map { event, global in
      var c = global.last!
      var model = event
      model.shouldLaunch = true
      c.application = model
      var s = c.screen
      if case .pre(.active(.some)) = event.session.state {
        s.total = "55"
      }
      c.screen = s
      return [c]
    }
  }
}
