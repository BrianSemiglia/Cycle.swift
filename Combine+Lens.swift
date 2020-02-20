//
//  Combine+Lens.swift
//  Cycle
//
//  Created by Brian Semiglia on 2/19/20.
//

import Combine

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
public extension AnyPublisher {
    func lens<B, C>(
        get: @escaping (AnyPublisher<Output, Failure>) -> B,
        set: @escaping (B, AnyPublisher<Output, Failure>) -> [C]
    ) -> MutatingLens<AnyPublisher<Output, Failure>, B, [C]> {
        MutatingLens(
            value: self,
            get: get,
            set: set
        )
    }

    func lens<B, C>(
        get: @escaping (AnyPublisher<Output, Failure>) -> B,
        set: @escaping (B, AnyPublisher<Output, Failure>) -> C
    ) -> MutatingLens<AnyPublisher<Output, Failure>, B, [C]> {
        MutatingLens(
            value: self,
            get: get,
            set: set
        )
    }

    func lens<B, C>(
        get: @escaping (AnyPublisher<Output, Failure>) -> B
    ) -> MutatingLens<AnyPublisher<Output, Failure>, B, [C]> {
        MutatingLens(
            value: self,
            get: get
        )
    }
}
