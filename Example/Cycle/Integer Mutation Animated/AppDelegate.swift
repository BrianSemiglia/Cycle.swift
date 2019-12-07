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
                    get: { state -> ValueToggler in
                        ValueToggler().rendering(
                            model: state
                                .map { $0.head }
                                .ignoringEmpty()
                        )
                    },
                    set: { toggler, state -> Observable<[ValueToggler.Model]> in
                        toggler
                            .events()
                            .tupledWithLatestFrom(state)
                            .map(incrementingByAppendingAnimation)
                         // .map(incrementingByDisablingControlsUntilAnimationEnd)
                         // .map(incrementingByReplacingPendingAnimation)
                    }
                )
                .map { state, toggler in
                    toggler.root
                }
                .prefixed(
                    with: .just([
                        ValueToggler.Model.empty
                    ])
                )

                return MutatingLens.zip(
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
    event: ValueToggler.Event,
    state: [ValueToggler.Model]
) -> [ValueToggler.Model] { return
    state
        .last
        .map { $0.total }
        .flatMap { total in
            Array(1...10).map { current -> ValueToggler.Model in
                var x = state.last!
                if event == .increment {
                    x.total = String(Int(x.total)! + current)
                    x.increment.state = .enabled
                }
                if event == .decrement {
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
    event: ValueToggler.Event,
    state: [ValueToggler.Model]
) -> [ValueToggler.Model] { return
    state
        .last
        .map { $0.total }
        .flatMap { total in
            Array(1...10).map { current -> ValueToggler.Model in
                var x = state.last!
                switch event {
                case .increment:
                    x.total = String(Int(x.total)! + current)
                case .decrement:
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
    event: ValueToggler.Event,
    state: [ValueToggler.Model]
) -> [ValueToggler.Model] {

    let valueDelta = event == .increment
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