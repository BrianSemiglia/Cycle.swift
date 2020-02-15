//
//  Cycled.swift
//  Compositions
//
//  Created by Brian Semiglia on 8/10/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

public struct CycledLens<Receiver, Value: Equatable> {
    
    public let receiver: Receiver
    private let producer = PublishSubject<Value>()
    private let cleanup = DisposeBag()
    
    public init(lens: (Observable<Value>) -> MutatingLens<Observable<Value>, Receiver, [Observable<Value>]>) {
        let lens = lens(
            producer
                .distinctUntilChanged()
                .share()
        )
        receiver = lens.get
        Observable
            .merge(lens.set)
            .observeOn(MainScheduler.asyncInstance)
            .bind(to: producer)
            .disposed(by: cleanup)
    }
}
