//
//  Observable+MutatingLens.swift
//  Compositions
//
//  Created by Brian Semiglia on 8/11/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import RxSwift

public extension Observable {
    func lens<B, C>(
        get: @escaping (Observable<Element>) -> B,
        set: @escaping (B, Observable<Element>) -> [C]
    ) -> MutatingLens<Observable<Element>, B, [C]> {
        MutatingLens(
            value: self,
            get: get,
            set: set
        )
    }

    func lens<B, C>(
        get: @escaping (Observable<Element>) -> B,
        set: @escaping (B, Observable<Element>) -> C
    ) -> MutatingLens<Observable<Element>, B, [C]> {
        MutatingLens(
            value: self,
            get: get,
            set: set
        )
    }

    func lens<B, C>(
        get: @escaping (Observable<Element>) -> B
    ) -> MutatingLens<Observable<Element>, B, [C]> {
        MutatingLens(
            value: self,
            get: get
        )
    }
}

public extension MutatingLens {
    func prefixed<T>(with prefix: T) -> MutatingLens<A, B, C> where C == [Observable<T>] {
        .init(
            value: value,
            get: { _ in self.get },
            set: { _, _ in [.just(prefix)] + self.set }
        )
    }
    
    func prefixed<T>(with prefix: T) -> MutatingLens<A, B, C> where C == [Observable<[T]>] {
        .init(
            value: value,
            get: { _ in self.get },
            set: { _, _ in [.just([prefix])] + self.set }
        )
    }
}
