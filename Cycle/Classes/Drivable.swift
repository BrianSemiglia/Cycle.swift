//
//  Drivable.swift
//  CycleMonitor
//
//  Created by Brian Semiglia on 2/8/20.
//  Copyright © 2020 Brian Semiglia. All rights reserved.
//

import Foundation
import RxSwift

public protocol Drivable: NSObject {
    associatedtype Model
    associatedtype Event
    func render(_ input: Model)
    func events() -> Observable<Event>
}

public extension Observable {
    func lens<Driver: Drivable>(
        driver: Driver,
        drivenOn: ImmediateSchedulerType = MainScheduler(),
        reducer: @escaping (Driver.Model, Driver.Event) -> Driver.Model,
        reducedOn: ImmediateSchedulerType = SerialDispatchQueueScheduler(qos: .userInteractive)
    ) -> MutatingLens<Observable<Driver.Model>, Driver, [Observable<Driver.Model>]> where Element == Driver.Model {
        lens(
            get: { states in
                driver.rendering(states) { (driver, state) in
                    driver.render(state)
                }
            },
            set: { toggler, state in
                toggler
                    .events()
                    .withLatestFrom(state) { ($1, $0) }
                    .share()
                    .observeOn(reducedOn)
                    .map(reducer)
            }
        )
    }
            
    func lens<Driver: Drivable>(
        lifter: @escaping (Element) -> Driver.Model,
        driver: Driver,
        drivenOn: ImmediateSchedulerType = MainScheduler(),
        reducer: @escaping (Element, Driver.Event) -> Element,
        reducedOn: ImmediateSchedulerType = SerialDispatchQueueScheduler(qos: .userInteractive)
    ) -> MutatingLens<Observable<Element>, Driver, [Observable<Element>]> {
        lens(
            get: { states in
                driver.rendering(states.map(lifter).observeOn(drivenOn)) { driver, state in
                    driver.render(state)
                }
            },
            set: { toggler, state -> Observable<Element> in
                toggler
                    .events()
                    .withLatestFrom(state) { ($1, $0) }
                    .share()
                    .observeOn(reducedOn)
                    .map(reducer)
            }
        )
    }
}
