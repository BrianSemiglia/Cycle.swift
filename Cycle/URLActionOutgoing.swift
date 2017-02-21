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
    var session = Session.Model.empty
  }
  struct Drivers: CycleDrivable {
    var session: Session!
  }
  func effectsFrom(events: Observable<Model>, drivers: Drivers) -> Observable<Model> { return
    drivers.session
      .rendered(events.map { $0.session })
      .withLatestFrom(events) { ($0.0, $0.1) }
      .reduced()
  }
}

extension URLActionOutgoing.Model {
  static var empty: URLActionOutgoing.Model { return
    URLActionOutgoing.Model(
      session: .empty
    )
  }
}

extension ObservableType where E == (Session.Model, URLActionOutgoing.Model) {
  func reduced() -> Observable<URLActionOutgoing.Model> { return
    map { event, context in
      
      var e = event
      if
      case .currently(.launched) = context.session.state,
      case .currently(.active) = event.state {
        e.urlActionOutgoing = .attempting(URL(string: "https://www.duckduckgo.com")!)
      }
      
      var output = context
      output.session = e
      return output
    }
  }
}
