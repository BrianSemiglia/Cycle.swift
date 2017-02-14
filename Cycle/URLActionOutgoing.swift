//
//  URLActionOutgoing.swift
//  Cycle
//
//  Created by Brian Semiglia on 2/13/17.
//  Copyright © 2017 Brian Semiglia. All rights reserved.
//

import Foundation
import RxSwift

@UIApplicationMain
class URLActionOutgoingDelegate: CycledApplicationDelegate<URLActionOutgoing> {
  init() {
    super.init(
      filter: URLActionOutgoing()
    )
  }
}

struct URLActionOutgoing: SinkSourceConverting {
  struct Model {
    var session: Session.Model
  }
  func effectsFrom(events: Observable<Model>, session: Session) -> Observable<Model> { return
    session
      .rendered(events.map { $0.session })
      .withLatestFrom(events) { ($0.0, $0.1) }
      .reduced()
  }
  func start() -> Model { return
    .empty
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
    map { event, global in
      
      var e = event
      if case .did(.active) = e.state {
//        e.urlAction = .attempting(URL(string: "https://www.duckduckgo.com")!)
      }
      
      var output = global
      output.session = e
      return output
    } // .delay(1, scheduler: MainScheduler.instance)
  }
}
