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
  init() {
    super.init(
      filter: IntegerMutatingApp()
    )
  }
}

struct IntegerMutatingApp: SinkSourceConverting {
  struct Model: Initializable, VisualizerStringConvertible {
    var screen = ValueToggler.Model.empty
    var secondScreen = SecondScreenDriver.Model(
      nodes: [],
      description: "No nodes to display"
    )
    var application = RxUIApplication.Model.empty
  }
  struct Drivers: UIApplicationDelegateProviding, ScreenDrivable {
    let screen: ValueToggler
    let secondScreen: SecondScreenDriver
    let application: RxUIApplication
  }
  func driversFrom(initial: IntegerMutatingApp.Model) -> IntegerMutatingApp.Drivers { return
    Drivers(
      screen: ValueToggler(),
      secondScreen: SecondScreenDriver(initial: initial.secondScreen),
      application: RxUIApplication(initial: initial.application)
    )
  }
  func effectsFrom(events: Observable<Model>, drivers: Drivers) -> Observable<Model> {
    let valueActions = drivers
      .screen
      .rendered(events.map { $0.screen })
    
    let applicationActions = drivers
      .application
      .rendered(events.map { $0.application })
    
    let valueEffects = valueActions
      .withLatestFrom(events) { ($0.0, $0.1) }
      .reduced()
    
    let applicationEffects = applicationActions
      .withLatestFrom(events) { ($0.0, $0.1) }
      .reduced()
    
    let visualizer = drivers
      .secondScreen
      .rendered(
        Observable.of(
          valueActions.toModels(),
          valueEffects.toModels()
        )
        .merge()
        .pacedBy(delay: 1)
      )
      .withLatestFrom(events) { ($0.0, $0.1) }
      .reduced()
    
    return Observable.of(
      valueEffects,
      visualizer,
      applicationEffects
    ).merge()
  }
}

extension ObservableType {
  func pacedBy(delay: Double) -> Observable<E> { return
    map {
      Observable<E>
        .empty()
        .delay(delay, scheduler: MainScheduler.instance)
        .startWith($0)
    }
    .concat()
  }
}

extension ObservableType where E == (ValueToggler.Model) {
  func toModels() -> Observable<SecondScreenDriver.Model> { return
    map {
      SecondScreenDriver.Model(
        nodes: [
          SecondScreenDriver.Model.Node(
            state: $0.increment.state == .highlighted ? .sending : .none,
            color: $0.increment.state == .highlighted ? .red : .black
          )
        ],
        description: ""
      )
    }
  }
}

extension ObservableType where E == (IntegerMutatingApp.Model) {
  func toModels() -> Observable<SecondScreenDriver.Model> { return
    map {
      SecondScreenDriver.Model(
        nodes: [
          SecondScreenDriver.Model.Node(
            state: $0.screen.increment.state == .highlighted ? .sending : .none,
            color: $0.screen.increment.state == .highlighted ? .red : .black
          )
        ],
        description: ""
      )
    }
  }
}

//extension ObservableType where E == (RxUIApplication.Model) {
//  func toModels() -> Observable<SecondScreenDriver.Model> { return
//    map { _ in
//      SecondScreenDriver.Model(
//        nodes: [],
//        description: ""
//      )
//    }
//  }
//}

extension IntegerMutatingApp.Model {
  static var empty: IntegerMutatingApp.Model { return
    IntegerMutatingApp.Model(
      screen: .empty,
      secondScreen: SecondScreenDriver.Model(
        nodes: [],
        description: "No nodes to display"
      ),
      application: .empty
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
      x.secondScreen.debug = x.description
      return x
    }
  }
}

extension ObservableType where E == (RxUIApplication.Model, IntegerMutatingApp.Model) {
  func reduced() -> Observable<IntegerMutatingApp.Model> { return
    map { event, global in
      var c = global
      var model = event
      model.shouldLaunch = true
      c.application = model
      var s = c.screen
      if case .pre(.active(.some)) = event.session.state {
        s.total = "55"
      }
      c.screen = s
      c.secondScreen.debug = c.description
      return c
    }
  }
}

extension ObservableType where E == (SecondScreenDriver.Model, IntegerMutatingApp.Model) {
    func reduced() -> Observable<IntegerMutatingApp.Model> { return
        map { event, context in
          return context
        }
    }
}
