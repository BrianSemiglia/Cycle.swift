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

        let lens = CycledLens<UIViewController, ValueToggler.Model>(
            lens: { source in
                source.lens(
                    driver: ValueToggler(),
                    reducer: mutatingInteger
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
            }
        )
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.makeKeyAndVisible()
        window?.rootViewController = lens.receiver
        self.lens = lens

        return true
    }

}

func mutatingInteger(
    state: ValueToggler.Model,
    event: ValueToggler.Event
) -> ValueToggler.Model {
    var x = state
    if event == .incrementing {
        x.total = String(Int(x.total)! + 1)
        x.increment.state = .enabled
    }
    if event == .decrementing {
        x.total = String(Int(x.total)! - 1)
        x.decrement.state = .enabled
    }
    return x
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
