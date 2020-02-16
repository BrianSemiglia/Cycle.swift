//
//  ValueToggler.swift
//  Cycle
//
//  Created by Brian Semiglia on 1/2/17.
//  Copyright © 2017 Brian Semiglia. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import Cycle

final class ValueToggler: UIView, Drivable {
    
    struct Model: Equatable {
        struct Button: Equatable {
            enum State: Equatable {
                case enabled
                case disabled
                case highlighted
            }
            var state: State
            var title: String
        }
        var total: String
        var increment: Button
        var decrement: Button
    }
    
    enum Event {
        case incrementing
        case decrementing
    }
    
    let label = UILabel(
        frame: CGRect(
            origin: CGPoint(
                x: 50,
                y: 100
            ),
            size: CGSize(
                width: 100,
                height: 44
            )
        )
    )
    
    var increment = UIButton(
        frame: CGRect(
            origin: CGPoint(x: 114, y: 144),
            size: CGSize(width: 44, height: 44)
        )
    )
    var decrement = UIButton(
        frame: CGRect(
            origin: CGPoint(x: 50, y: 144),
            size: CGSize(width: 44, height: 44)
        )
    )
    
    var cleanup = DisposeBag()
    
    @available(*, unavailable) required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        increment.backgroundColor = .gray
        decrement.backgroundColor = .red
        super.init(frame: .zero)
        addSubview(label)
        addSubview(increment)
        addSubview(decrement)
    }
  
    func render(_ input: Model) {
        self.increment.setTitle(
            input.increment.title,
            for: .normal
        )
        self.increment.isEnabled =
            input.increment.state == .enabled ||
            input.increment.state == .highlighted
        self.decrement.setTitle(
            input.decrement.title,
            for: .normal
        )
        self.decrement.isEnabled =
            input.decrement.state == .enabled ||
            input.decrement.state == .highlighted
        self.label.text = input.total
    }
    
    func events() -> Observable<ValueToggler.Event> {
        return Observable.merge(
            self.increment.rx.tap.asObservable().map { Event.incrementing },
            self.decrement.rx.tap.asObservable().map { Event.decrementing }
        )
    }
}

extension ValueToggler.Model {
    static var empty: ValueToggler.Model {
        ValueToggler.Model(
            total: "0",
            increment: ValueToggler.Model.Button(state: .enabled, title: "+"),
            decrement: ValueToggler.Model.Button(state: .enabled, title: "-")
        )
    }
}
