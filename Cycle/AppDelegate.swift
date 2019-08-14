//
//  AppDelegate.swift
//  Cycle
//
//  Created by Brian Semiglia on 8/14/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import UIKit
import RxSwift

@UIApplicationMain class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var lens: Cycled<UIViewController, ValueToggler.Model>?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        self.lens = Cycled<UIViewController, ValueToggler.Model>(
            lens: { source in
                source.lens(
                    get: { state in
                        ValueToggler().rendering(
                            model: state
                        )
                    },
                    set: { toggler, state -> Observable<ValueToggler.Model> in
                        toggler.events().withLatestFrom(state) { ($0, $1) } .map {
                            switch $0 {
                            case .increment:
                                var new = $1
                                new.total = Int($1.total).map { $0 + 1 }.map(String.init) ?? ""
                                new.increment.state = .enabled
                                return new
                            case .decrement:
                                var new = $1
                                new.total = Int($1.total).map { $0 - 1 }.map(String.init) ?? ""
                                new.increment.state = .enabled
                                return new
                            }
                        }
                    }
                )
                .map { state, toggler in
                    toggler.root
                }
                .prefixed(
                    with: .just(
                        ValueToggler.Model.empty
                    )
                )
            }
        )
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.makeKeyAndVisible()
        window?.rootViewController = self.lens?.receiver

        return true
    }

}
