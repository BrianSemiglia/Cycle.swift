//
//  AppDelegate.swift
//  Cycle
//
//  Created by Brian Semiglia on 8/14/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import UIKit
import Cycle
import RxSwift

@UIApplicationMain class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var lens: Any?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        let lens = CycledLens<
            (UIViewController, Animator<ValueToggler.Model>),
            [ValueToggler.Model]
        >(
            lens: { source in
                let toggler = source.lens(
                    lifter: { $0.head! },
                    driver: ValueToggler(),
                    reducer: incrementingByAppendingAnimation
                    // reducer: incrementingByDisablingControlsUntilAnimationEnd
                    // reducer: incrementingByReplacingPendingAnimation
                )
                .map { state, toggler -> UIViewController in
                    let x = UIViewController()
                    x.view = toggler
                    x.view.backgroundColor = .white
                    return x
                }
                .prefixed(
                    with: ValueToggler.Model.empty
                )

                return MutatingLens<Any, Any, Any>.zip(
                    toggler,
                    source.emittingTail(
                        every: .milliseconds(1000 / 60)
                    )
                )
            }
        )
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.makeKeyAndVisible()
        window?.rootViewController = lens.receiver.0
        self.lens = lens

        return true
    }

}

func incrementingByAppendingAnimation(
    state: [ValueToggler.Model],
    event: ValueToggler.Event
) -> [ValueToggler.Model] { return
    state
        .last
        .map { $0.total }
        .flatMap { total in
            Array(1...10).map { current -> ValueToggler.Model in
                var x = state.last!
                if event == .incrementing {
                    x.total = String(Int(x.total)! + current)
                    x.increment.state = .enabled
                }
                if event == .decrementing {
                    x.total = String(Int(x.total)! - current)
                    x.decrement.state = .enabled
                }
                return x
            }
        }
        .map { state + $0 }
        ?? []
}

func incrementingByDisablingControlsUntilAnimationEnd(
    state: [ValueToggler.Model],
    event: ValueToggler.Event
) -> [ValueToggler.Model] { return
    state
        .last
        .map { $0.total }
        .flatMap { total in
            Array(1...10).map { current -> ValueToggler.Model in
                var x = state.last!
                switch event {
                case .incrementing:
                    x.total = String(Int(x.total)! + current)
                case .decrementing:
                    x.total = String(Int(x.total)! - current)
                }
                x.increment.state = current == 10 ? .enabled : .disabled
                x.decrement.state = current == 10 ? .enabled : .disabled
                return x
            }
        }
        .map { state + $0 }
        ?? []
}

func incrementingByReplacingPendingAnimation(
    state: [ValueToggler.Model],
    event: ValueToggler.Event
) -> [ValueToggler.Model] {

    let valueDelta = event == .incrementing
        ? 10
        : -10

    let positionDelta = (Int(state.last!.total)! + valueDelta) - Int(state.first!.total)!

    let appended = Array(0...abs(positionDelta)).map { current -> ValueToggler.Model in
        var x = state.first!
        if positionDelta > 0 {
            x.total = String(Int(x.total)! + current)
            x.increment.state = .enabled
        } else {
            x.total = String(Int(x.total)! - current)
            x.decrement.state = .enabled
        }
        return x
    }

    return appended
}

private extension Observable {
    func ignoringEmpty<T>() -> Observable<T> where Element == Optional<T> {
        flatMap { $0.map(Observable<T>.just) ?? .never() }
    }
}

private extension Observable {
    func tupledWithLatestFrom<T>(_ input: Observable<T>) -> Observable<(Element, T)> {
        withLatestFrom(input) { ($0, $1) }
    }
}
