//
//  UIView+Reactive.swift
//  Compositions
//
//  Created by Brian Semiglia on 8/4/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

public extension Reactive where Base: UIView {
    var willMoveToSuperview: ControlEvent<Bool> {
        return ControlEvent(
            events: methodInvoked(#selector(UIView.willMove(toSuperview:)))
                .map { $0.first }
                .map { $0 as? UIView? }
                .map { $0 != nil }
        )
    }
}
