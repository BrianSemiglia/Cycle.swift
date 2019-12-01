//
//  NSObject+Binding.swift
//  Compositions
//
//  Created by Brian Semiglia on 8/10/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import Foundation
import RxSwift

public protocol Consumer {}
extension NSObject: Consumer {}
private var AssociatedObjectHandle: UInt8 = 0

extension Consumer where Self: AnyObject {
    public func rendering<T>(_ o: Observable<T>, f: @escaping (Self, T) -> Void) -> Self  {
        objc_setAssociatedObject(
            self,
            &AssociatedObjectHandle,
            o.subscribe(onNext: { f(self, $0) }),
            objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        return self
    }
}
