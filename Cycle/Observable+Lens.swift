//
//  Observable+MutatingLens.swift
//  Compositions
//
//  Created by Brian Semiglia on 8/11/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import Foundation
import RxSwift

protocol Lensable {}
extension Observable: Lensable {}

extension Observable {
    func lens<B>(
        get: @escaping (Observable<Element>) -> B,
        set: @escaping (B, Observable<Element>) -> [Observable<Element>]
    ) -> MutatingLens<Observable<Element>, B> { return
        MutatingLens<Observable<Element>, B>(
            value: self,
            get: get,
            set: set
        )
    }

    func lens<B>(
        get: @escaping (Observable<Element>) -> B,
        set: @escaping (B, Observable<Element>) -> Observable<Element>
    ) -> MutatingLens<Observable<Element>, B> { return
        MutatingLens<Observable<Element>, B>(
            value: self,
            get: get,
            set: set
        )
    }

    func lens<B>(
        get: @escaping (Observable<Element>) -> B
    ) -> MutatingLens<Observable<Element>, B> { return
        MutatingLens<Observable<Element>, B>(
            value: self,
            get: get
        )
    }
}
