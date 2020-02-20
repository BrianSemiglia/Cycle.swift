//
//  Drivable+SwiftUI.swift
//  Pods
//
//  Created by Brian Semiglia on 2/18/20.
//

import SwiftUI
import RxSwift

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
public final class PublishedObservable<T>: ObservableObject {

    @Published public var value: T
    private let updates: Observable<T>
    private let cleanup = DisposeBag()

    public init(initial: T, subsequent: Observable<T>) {
        value = initial
        updates = subsequent
        updates.subscribe(onNext: { [weak self] in
            self?.value = $0
        })
        .disposed(by: cleanup)
    }
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
public protocol DrivableSwiftUI {
    associatedtype Model
    associatedtype Event
    init(model: PublishedObservable<Model>)
    func events() -> Observable<Event>
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
public extension Observable {

    func lens<Driver: DrivableSwiftUI>(
        get: @escaping (Observable<Element>) -> Driver,
        reducer: @escaping (Element, Driver.Event) -> Element,
        reducedOn: ImmediateSchedulerType = SerialDispatchQueueScheduler(qos: .userInteractive)
    ) -> MutatingLens<Observable<Element>, Driver, [Observable<Element>]> {
        lens(
            get: get,
            set: { driver, state in
                driver
                    .events()
                    .withLatestFrom(state) { ($1, $0) }
                    .share()
                    .observeOn(reducedOn)
                    .map(reducer)
            }
        )
    }
}
