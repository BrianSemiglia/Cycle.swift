//
//  MutatingLens.swift
//  Compositions
//
//  Created by Brian Semiglia on 8/2/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import Foundation

struct MutatingLens<A, B> {

    private let value: A
    let get: B
    let set: [A]

    init(
        value: A,
        get: @escaping (A) -> B,
        set: @escaping (B, A) -> [A] = { _, _ in [] }
    ) {
        self.init(
            _value: value,
            _get: get,
            _set: set
        )
    }

    init(
        value: A,
        get: @escaping (A) -> B,
        set: @escaping (B, A) -> A
    ) {
        self.init(
            _value: value,
            _get: get,
            _set: { b, a in [set(b, value)] }
        )
    }
    
    private init(
        _value: A,
        _get: @escaping (A) -> B,
        _set: @escaping (B, A) -> [A] = { _, _ in [] }
    ) {
        let b = _get(_value)
        self.value = _value
        self.get = b
        self.set = _set(b, value)
    }
    
    static func zip<C>(
        _ first: MutatingLens<A, B>,
        _ second: MutatingLens<A, C>
    ) -> MutatingLens<A, (B, C)> {
        return MutatingLens<A, (B, C)>(
            value: first.value,
            get: { a in (first.get, second.get) },
            set: { _, a in first.set + second.set }
        )
    }

    func map<C>(_ f: @escaping (A, B) -> C) -> MutatingLens<A, C> { return
        MutatingLens<A, C>(
            value: value,
            get: { a in f(a, self.get) },
            set: { _, _ in self.set }
        )
    }
    
    func mapLeft(
        _ f: @escaping (B, A) -> A
    ) -> MutatingLens<A, B> { return
        MutatingLens<A, B>(
            value: value,
            get: { _ in self.get },
            set: { b, a in
                self.set.last.map {
                    [f(b, $0)]
                } ?? []
            }
        )
    }
    
    func flatMap<C>(_ f: @escaping (A, B) -> MutatingLens<A, C>) -> MutatingLens<A, C> {
        let other = f(value, get)
        return MutatingLens<A, C>(
            value: value,
            get: { a in other.get },
            set: { c, a in self.set + other.set }
        )
    }

    func prefixed(with prefix: A) -> MutatingLens<A, B> { return
        MutatingLens(
            value: value,
            get: { _ in self.get },
            set: { _, _ in [prefix] + self.set }
        )
    }
}
