//
//  Drivable+Combine+SwiftUI.swift
//  Cycle
//
//  Created by Brian Semiglia on 2/20/20.
//

import Combine

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
public protocol DrivableSwiftUICombine {
    associatedtype Model
    associatedtype Event
    init(model: AnyPublisher<Model, Error>)
    func events() -> AnyPublisher<Event, Error>
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension AnyPublisher {
    func lens<Driver: DrivableSwiftUICombine>(
        get: @escaping (AnyPublisher<Output, Failure>) -> Driver,
        reducer: @escaping (Output, Driver.Event) -> Output,
        reducedOn: DispatchQueue = .global(qos: .userInteractive)
    ) -> MutatingLens<AnyPublisher<Output, Failure>, Driver, [AnyPublisher<Output, Failure>]> where Failure == Error {
        lens(
            get: get,
            set: { driver, states in
                driver
                    .events()
                    .withLatestFrom(states) { ($1, $0) }
                    .share()
                    .receive(on: reducedOn)
                    .map(reducer)
                    .eraseToAnyPublisher()
            }
        )
    }
}
