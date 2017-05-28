//
//  VisualizerDemo.swift
//  Cycle
//
//  Created by Brian Semiglia on 2/13/17.
//  Copyright © 2017 Brian Semiglia. All rights reserved.
//

import Foundation
import Cycle
import RxSwift

@UIApplicationMain
class AppDelegate: CycledApplicationDelegate<VisualizerDemo> {
  init() {
    super.init(
      filter: VisualizerDemo()
    )
  }
}

struct ScreenDriver: UIViewControllerProviding {
  let root = UIViewController.empty
}

struct VisualizerDemo: SinkSourceConverting {
  struct Model: Initializable {
    var application = RxUIApplication.Model.empty
    var secondScreen = SecondScreenDriver.Model(nodes: [], description: "No nodes to display")
  }
  struct Drivers: UIApplicationDelegateProviding, ScreenDrivable {
    let screen: ScreenDriver
    let secondScreen: SecondScreenDriver
    let application: RxUIApplication
  }
  func driversFrom(initial: VisualizerDemo.Model) -> VisualizerDemo.Drivers {
    return Drivers(
      screen: ScreenDriver(),
      secondScreen: SecondScreenDriver(initial: initial.secondScreen),
      application: RxUIApplication(initial: initial.application)
    )
  }
  func effectsFrom(events: Observable<Model>, drivers: Drivers) -> Observable<Model> {
    let application = drivers.application
      .rendered(events.map { $0.application })
      .withLatestFrom(events) { ($0.0, $0.1) }
      .reduced()
    let visualizer = drivers.secondScreen
        .rendered(events.map { $0.secondScreen })
        .withLatestFrom(events) { ($0.0, $0.1) }
        .reduced()
    return Observable.of(application, visualizer).merge()
  }
}

extension VisualizerDemo.Model {
  static var empty: VisualizerDemo.Model { return
    VisualizerDemo.Model(
      application: .empty,
      secondScreen: SecondScreenDriver.Model(nodes: [], description: "No nodes to display")
    )
  }
}

extension ObservableType where E == (RxUIApplication.Model, VisualizerDemo.Model) {
  func reduced() -> Observable<VisualizerDemo.Model> { return
    map { event, context in
      return context
    }
  }
}

extension ObservableType where E == (SecondScreenDriver.Model, VisualizerDemo.Model) {
    func reduced() -> Observable<VisualizerDemo.Model> { return
        map { event, context in
            return context
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
