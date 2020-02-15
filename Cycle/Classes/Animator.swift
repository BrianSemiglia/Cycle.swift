//
//  Animator.swift
//  Cycle
//
//  Created by Brian Semiglia on 11/29/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import Foundation
import RxSwift

final public class Animator<A>: NSObject {
    let output: Observable<[A]>
    init(input: Observable<[A]>, interval: RxTimeInterval) {
        output = input.sample(
            Observable<Int>.interval(
                interval,
                scheduler: MainScheduler.instance
            )
        )
        .ignoringEmpty()
        .map { $0.count == 1 ? [$0.first!] : $0.tail }
    }
}

public extension Observable {
    func emittingTail<T>(every: RxTimeInterval) -> MutatingLens<Observable<[T]>, Animator<T>, [Observable<[T]>]> where Element == Array<T> {
        return lens(
            get: { Animator(input: $0, interval: every) },
            set: { b, a in
                [b.output]
            }
        )
    }
}

private extension Observable where Element: Collection {
    func ignoringEmpty() -> Observable {
        flatMap { $0.count > 0 ? Observable.just($0) : .never() }
    }
}

public extension Collection {
    var head: Element? {
        first
    }
}

public extension Collection {
    var tail: [Element] {
        Array(dropFirst())
    }
}
