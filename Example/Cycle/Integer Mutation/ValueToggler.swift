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

final class ValueToggler: NSObject {
    
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
        case increment
        case decrement
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
    let root = UIViewController.empty
    
    override init() {
        increment.backgroundColor = .gray
        decrement.backgroundColor = .red
        root.view.addSubview(label)
        root.view.addSubview(increment)
        root.view.addSubview(decrement)
        super.init()
    }
  
    func rendering(model input: Observable<Model>) -> ValueToggler {
        input
            .subscribe(onNext: { latest in
                self.increment.setTitle(
                    latest.increment.title,
                    for: .normal
                )
                self.increment.isEnabled =
                    latest.increment.state == .enabled ||
                    latest.increment.state == .highlighted
                self.decrement.setTitle(
                    latest.decrement.title,
                    for: .normal
                )
                self.decrement.isEnabled =
                    latest.decrement.state == .enabled ||
                    latest.decrement.state == .highlighted
                self.label.text = latest.total
            })
            .disposed(by:cleanup)
        return self
    }
    
    func events() -> Observable<ValueToggler.Event> {
        return Observable.merge(
            self.increment.rx.tap.asObservable().map { Event.increment },
            self.decrement.rx.tap.asObservable().map { Event.decrement }
        )
    }
}

extension ValueToggler.Model {
    static var empty: ValueToggler.Model { return
        ValueToggler.Model(
            total: "0",
            increment: ValueToggler.Model.Button(state: .enabled, title: "+"),
            decrement: ValueToggler.Model.Button(state: .enabled, title: "-")
        )
    }
}

extension UIViewController {
    public static var empty: UIViewController {
        let x = UIViewController()
        x.view.backgroundColor = .systemBackground
        return x
    }
}
