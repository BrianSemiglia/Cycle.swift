//
//  MutatingLens.swift
//  Compositions
//
//  Created by Brian Semiglia on 8/2/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import Foundation

public struct Prefixed {}

public struct MutatingLens<A, B, C> {

    public let value: A
    public let get: B
    public let set: C

    public init(
        value: A,
        get: @escaping (A) -> B,
        set: @escaping (B, A) -> C
    ) {
        let b = get(value)
        self.value = value
        self.get = b
        self.set = set(b, value)
    }
    
    public func map<X>(_ f: @escaping (A, B) -> X) -> MutatingLens<A, X, C> {
        .init(
            value: value,
            get: { a in f(a, self.get) },
            set: { _, _ in self.set }
        )
    }
}

extension MutatingLens {
    public func prefixed<T>(with prefix: T) -> MutatingLens<A, B, C> where C == [T] {
        .init(
            value: value,
            get: { _ in self.get },
            set: { _, _ in [prefix] + self.set }
        )
    }
}

extension MutatingLens {
    public init<T>(
        value: A,
        get: @escaping (A) -> B,
        set: @escaping (B, A) -> T
    ) where C == [T] {
        self.init(
            value: value,
            get: get,
            set: { b, a in [set(b, value)] }
        )
    }
    
    public init<T>(
        value: A,
        get: @escaping (A) -> B
    ) where C == [T] {
        self.init(
            value: value,
            get: get,
            set: { b, a in [] }
        )
    }
}

extension MutatingLens {
        
    public static func zip<A1, B1, B2, C1>(
        _ _1: MutatingLens<A1, B1, [C1]>,
        _ _2: MutatingLens<A1, B2, [C1]>
    ) -> MutatingLens<A1, (B1, B2), [C1]> {
        .init(
            value: _1.value,
            get: { a in (_1.get, _2.get) },
            set: { _, a in _1.set + _2.set }
        )
    }
    
    public static func zip<A1, B1, B2, B3, C1>(
        _ _1: MutatingLens<A1, B1, [C1]>,
        _ _2: MutatingLens<A1, B2, [C1]>,
        _ _3: MutatingLens<A1, B3, [C1]>
    ) -> MutatingLens<A1, (B1, B2, B3), [C1]> {
        .init(
            value: _1.value,
            get: { a in (_1.get, _2.get, _3.get) },
            set: { _, a in _1.set + _2.set + _3.set }
        )
    }
    
    public static func zip<A1, B1, B2, B3, B4, C1>(
        _ _1: MutatingLens<A1, B1, [C1]>,
        _ _2: MutatingLens<A1, B2, [C1]>,
        _ _3: MutatingLens<A1, B3, [C1]>,
        _ _4: MutatingLens<A1, B4, [C1]>
    ) -> MutatingLens<A1, (B1, B2, B3, B4), [C1]> {
        .init(
            value: _1.value,
            get: { a in (_1.get, _2.get, _3.get, _4.get) },
            set: { _, a in _1.set + _2.set + _3.set + _4.set }
        )
    }
    
    public static func zip<A1, B1, B2, B3, B4, B5, C1>(
        _ _1: MutatingLens<A1, B1, [C1]>,
        _ _2: MutatingLens<A1, B2, [C1]>,
        _ _3: MutatingLens<A1, B3, [C1]>,
        _ _4: MutatingLens<A1, B4, [C1]>,
        _ _5: MutatingLens<A1, B5, [C1]>
    ) -> MutatingLens<A1, (B1, B2, B3, B4, B5), [C1]> {
        .init(
            value: _1.value,
            get: { a in (_1.get, _2.get, _3.get, _4.get, _5.get) },
            set: { _, a in _1.set + _2.set + _3.set + _4.set + _5.set }
        )
    }
    
    public static func zip<A1, B1, B2, B3, B4, B5, B6, C1>(
        _ _1: MutatingLens<A1, B1, [C1]>,
        _ _2: MutatingLens<A1, B2, [C1]>,
        _ _3: MutatingLens<A1, B3, [C1]>,
        _ _4: MutatingLens<A1, B4, [C1]>,
        _ _5: MutatingLens<A1, B5, [C1]>,
        _ _6: MutatingLens<A1, B6, [C1]>
    ) -> MutatingLens<A1, (B1, B2, B3, B4, B5, B6), [C1]> {
        .init(
            value: _1.value,
            get: { a in (_1.get, _2.get, _3.get, _4.get, _5.get, _6.get) },
            set: { _, a in _1.set + _2.set + _3.set + _4.set + _5.set + _6.set }
        )
    }
}
