//
//  URLActionOutgoing.swift
//  Cycle
//
//  Created by Brian Semiglia on 2/13/17.
//  Copyright © 2017 Brian Semiglia. All rights reserved.
//

import Foundation
import RxSwift

class URLActionOutgoingDelegate: CycledApplicationDelegate<URLActionOutgoing> {
  init() {
    super.init(
      filter: URLActionOutgoing()
    )
  }
}

struct URLActionOutgoing: SinkSourceConverting {
  struct Model: Initializable {
    var application = RxUIApplication.Model.empty
  }
  struct Drivers: CycleDrivable {
    var application: RxUIApplication!
  }
  func effectsFrom(events: Observable<Model>, drivers: Drivers) -> Observable<Model> { return
    drivers.application
      .rendered(events.map { $0.application })
      .withLatestFrom(events) { ($0.0, $0.1) }
      .reduced()
  }
}

extension URLActionOutgoing.Model {
  static var empty: URLActionOutgoing.Model { return
    URLActionOutgoing.Model(
      application: .empty
    )
  }
}

extension ObservableType where E == (RxUIApplication.Model, URLActionOutgoing.Model) {
  func reduced() -> Observable<URLActionOutgoing.Model> { return
    map { event, context in
      
      var e = event
      if
      case .currently(.launched) = context.application.session.state,
      case .currently(.active) = event.session.state {
        e.urlActionOutgoing = .attempting(URL(string: "https://www.duckduckgo.com")!)
      }
      
      var output = context
      output.application = e
      return output
    }
  }
}
