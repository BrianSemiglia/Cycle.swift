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
import Curry

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
    var secondScreen = SecondScreenDriver.Model(nodes: [], description: "No nodes to display")
    var application = RxUIApplication.Model.empty
    var bugReporter = BugReporter.Model(state: .idle)
    var motionReporter = ShakeDetection.Model(state: .listening)
  }
  struct Drivers: UIApplicationDelegateProviding, ScreenDrivable {
    let screen: ValueToggler
    let secondScreen: SecondScreenDriver
    let application: RxUIApplication
    let jsonExport: MultipeerJSON
    let bugReporter: BugReporter
    let motionReporter: ShakeDetection
  }
  func driversFrom(initial: IntegerMutatingApp.Model) -> IntegerMutatingApp.Drivers { return
    Drivers(
      screen: ValueToggler(),
      secondScreen: SecondScreenDriver(
        initial: {
          let x = [
            SecondScreenDriver.Model.Node.incrementNodeFrom(model: initial.screen),
            SecondScreenDriver.Model.Node.decrementNodeFrom(model: initial.screen),
            SecondScreenDriver.Model.Node.applicationNodeFrom(model: initial.application)
          ]
          let y = x.gridLayout()
          return SecondScreenDriver.Model(
            nodes: zip(x, y).map { $0.0($0.1) },
            description: initial.description
          )
        }()
      ),
      application: RxUIApplication(initial: initial.application),
      jsonExport: MultipeerJSON(),
      bugReporter: BugReporter(initial: initial.bugReporter),
      motionReporter: ShakeDetection(initial: initial.motionReporter)
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
      .tupledWithLatestFrom(events)
      .reduced()
    
    let applicationEffects = applicationActions
      .tupledWithLatestFrom(events)
      .reduced()

    let shakeActions = drivers.motionReporter
      .rendered(events.map { $0.motionReporter })
    .share()
    
    let shakeEffects = shakeActions
      .tupledWithLatestFrom(events)
      .reduced()
      .share()

    let visualizer = drivers
      .secondScreen
      .rendered(
        Observable.of(
          valueActions.tupledWithLatestFrom(valueEffects).toModels(),
          valueEffects.toModels(),
          applicationActions.tupledWithLatestFrom(applicationEffects).toModels(),
          applicationEffects.toModels()
        )
        .merge()
        .pacedBy(delay: 0.5)
      )
      .tupledWithLatestFrom(events)
      .reduced()
      .share()
    
    let dictionaryStateStream: Observable<[AnyHashable: Any]> = Observable.of(
      valueActions
        .map {
          if $0.increment.state == .highlighted {
            return ".highlighted"
          } else if $0.decrement.state == .highlighted {
            return ".highlighted"
          } else {
            return ""
          }
        }
        .tupledWithLatestFrom(valueEffects)
        .map {
          [
            "drivers": [
              ["label": "value", "action": $0.0],
              ["label": "session", "action": ""] //Optional<String>.none]
            ],
            "cause": ["label": "value", "action": $0.0],
            "effect": $0.1.description
          ]
      },
      applicationActions
        .map {
          switch $0.session.state {
          case .currently(.active(_)): return "active"
          case .currently(.resigned): return "resigned"
          default: return "none"
          }
        }
        .tupledWithLatestFrom(applicationEffects.map { $0.description })
        .map {
          [
            "drivers": [
              ["label": "value", "action": ""], // Optional<String>.none],
              ["label": "session", "action": $0.0]
            ],
            "cause": ["label": "session", "action": $0.0],
            "effect": $0.1
          ]
        },
        shakeActions
          .map { x -> String in
            switch x {
            case .detecting: return "detecting"
            case .none: return ""
            }
          }
          .tupledWithLatestFrom(shakeEffects.map { $0.description })
          .map { _ in
            ["": ""] as [AnyHashable: Any]
          }
      )
      .merge()
      .share()

    let json = drivers.jsonExport
      .rendered(dictionaryStateStream)
      .tupledWithLatestFrom(events)
      .map { $0.1 }
      .share()

    let reporter = drivers.bugReporter
      .rendered(
        events
          .map { $0.bugReporter }
          .tupledWithLatestFrom(
            dictionaryStateStream
              .scan([[AnyHashable: Any]]()) { $0 + [$1] }
              .map { $0.suffix(25) }
              .map (Array.init)
              .map { ["events": $0] as [AnyHashable: Any] }
          )
          .map {
            switch $0.0.state {
            case .shouldSend:
              var new = $0.0
              if let data = $0.1.binaryPropertyList() {
                new.state = .sending(data)
              } else {
                new.state = .idle
              }
              return new
            default:
              return $0.0
            }
        }
    )
    .tupledWithLatestFrom(events)
    .reduced()
    .share()

    return Observable
      .of(
        valueEffects,
        visualizer,
        applicationEffects,
        json,
        reporter,
        shakeEffects
      )
      .merge()
  }
}

extension Collection where Iterator.Element == (key: AnyHashable, value: Any) {
  func JSON() -> Data? { return
    try? JSONSerialization.data(
      withJSONObject: self,
      options: JSONSerialization.WritingOptions(rawValue: 0)
    )
  }
  func binaryPropertyList() -> Data? { return
    try? PropertyListSerialization.data(
      fromPropertyList: self,
      format: .binary,
      options: 0
    )
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

extension ObservableType {
  func tupledWithLatestFrom<T>(_ input: Observable<T>) -> Observable<(E, T)> {
    return withLatestFrom(input) { ($0.0, $0.1 ) }
  }
}

extension ObservableType where E == (ValueToggler.Model, IntegerMutatingApp.Model) {
  func toModels() -> Observable<SecondScreenDriver.Model> { return
    map { event, context in
      var new = context
      new.screen = event
      let x = [
        curry(SecondScreenDriver.Model.Node.incrementNodeFrom)(event),
        curry(SecondScreenDriver.Model.Node.decrementNodeFrom)(event),
        curry(SecondScreenDriver.Model.Node.applicationNodeFrom)(context.application)
      ]
      let y = x.gridLayout()
      return SecondScreenDriver.Model(
        nodes: zip(x, y).map { $0.0($0.1) },
        description: new.description
      )
    }
  }
}

extension ObservableType where E == (RxUIApplication.Model, IntegerMutatingApp.Model) {
  func toModels() -> Observable<SecondScreenDriver.Model> { return
    map { event, context in
      var new = context
      new.application = event
      let x = [
        curry(SecondScreenDriver.Model.Node.incrementNodeFrom)(context.screen),
        curry(SecondScreenDriver.Model.Node.decrementNodeFrom)(context.screen),
        curry(SecondScreenDriver.Model.Node.applicationNodeFrom)(event)
      ]
      let y = x.gridLayout()
      return SecondScreenDriver.Model(
        nodes: zip(x, y).map { $0.0($0.1) },
        description: new.description
      )
    }
  }
}

extension CGRect {
  static func gridWith(count: Int) -> [CGRect] {
    return Array (0..<count).map {
      CGRect(
        origin: CGPoint(x: $0 * 70, y: 0),
        size: CGSize(width: 50.0, height: 50.0)
      )
    }
  }
}

extension Collection {
  func gridLayout() -> [CGRect] {
    return enumerated().map {
      CGRect(
        origin: CGPoint(x: $0.offset * 70, y: 0),
        size: CGSize(width: 50.0, height: 50.0)
      )
    }
  }
}

extension ObservableType where E == (IntegerMutatingApp.Model) {
  func toModels() -> Observable<SecondScreenDriver.Model> { return
    map { context in
      let x = [
        SecondScreenDriver.Model.Node.incrementNodeFrom(model: context.screen),
        SecondScreenDriver.Model.Node.decrementNodeFrom(model: context.screen),
        SecondScreenDriver.Model.Node.applicationNodeFrom(model: context.application)
      ]
      let y = x.gridLayout()
      return SecondScreenDriver.Model(
        nodes: zip(x, y).map { $0.0($0.1) },
        description: context.description
      )
    }
  }
}

extension SecondScreenDriver.Model.Node {

  static func incrementNodeFrom(model: ValueToggler.Model) -> (CGRect) -> SecondScreenDriver.Model.Node { return
    { frame in
      SecondScreenDriver.Model.Node(
        state: model.increment.state == .highlighted ? .sending : .none,
        color: model.increment.state == .highlighted ? .redDark : .redLight,
        frame: frame
      )
    }
  }
  
  static func decrementNodeFrom(model: ValueToggler.Model) -> (CGRect) -> SecondScreenDriver.Model.Node { return
    { frame in
      SecondScreenDriver.Model.Node(
        state: model.decrement.state == .highlighted ? .sending : .none,
        color: model.decrement.state == .highlighted ? .redDark : .redLight,
        frame: frame
      )
    }
  }
  
  static func applicationNodeFrom(model: RxUIApplication.Model) -> (CGRect) -> SecondScreenDriver.Model.Node { return
    { frame in
      SecondScreenDriver.Model.Node(
        state: model.session.state != .currently(.active(.some)) ? .sending : .none,
        color: model.session.state != .currently(.active(.some)) ? .blueDark : .blueLight,
        frame: frame
      )
    }
  }
}

extension UIColor {
  static var orangeLight: UIColor {
    return UIColor(
      red: 248.0/255.0,
      green: 159.0/255.0,
      blue: 53.0/255.0,
      alpha: 0.5
    )
  }
  static var orangeDark: UIColor {
    return UIColor(
      red: 248.0/255.0,
      green: 159.0/255.0,
      blue: 53.0/255.0,
      alpha: 1.0
    )
  }
  static var redLight: UIColor {
    return UIColor(
      red: 244.0/255.0,
      green: 129.0/255.0,
      blue: 134.0/255.0,
      alpha: 1.0
    )
  }
  static var redDark: UIColor {
    return UIColor(
      red: 232.0/255.0,
      green: 30.0/255.0,
      blue: 38.0/255.0,
      alpha: 1.0
    )
  }
  static var blueLight: UIColor {
    return UIColor(
      red: 114.0/255.0,
      green: 206.0/255.0,
      blue: 227.0/255.0,
      alpha: 1.0
    )
  }
  static var blueDark: UIColor {
    return UIColor(
      red: 23.0/255.0,
      green: 145.0/255.0,
      blue: 178.0/255.0,
      alpha: 1.0
    )
  }
}

extension IntegerMutatingApp.Model {
  static var empty: IntegerMutatingApp.Model { return
    IntegerMutatingApp.Model(
      screen: .empty,
      secondScreen: SecondScreenDriver.Model(
        nodes: [],
        description: "No nodes to display"
      ),
      application: .empty,
      bugReporter: BugReporter.Model(
        state: .idle
      ),
      motionReporter: ShakeDetection.Model(state: .listening)
    )
  }
}

extension ObservableType where E == (ShakeDetection.Action, IntegerMutatingApp.Model) {
  func reduced() -> Observable<IntegerMutatingApp.Model> { return
    map { event, context in
      switch event {
      case .detecting:
        var new = context
        new.bugReporter.state = .shouldSend
        return new
      default:
        return context
      }
    }
  }
}

extension ObservableType where E == (BugReporter.Action, IntegerMutatingApp.Model) {
  func reduced() -> Observable<IntegerMutatingApp.Model> { return
    map { event, context in
      switch event {
      case .didSuccessfullySend:
        var new = context
        new.bugReporter.state = .idle
        return new
      default:
        return context
      }
    }
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
