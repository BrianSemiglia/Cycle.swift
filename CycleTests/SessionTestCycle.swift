//
//  SessionTestCycle.swift
//  Cycle
//
//  Created by Brian Semiglia on 2/13/17.
//  Copyright © 2017 Brian Semiglia. All rights reserved.
//

import Foundation
import RxSwift

class SessionTestDelegate: CycledApplicationDelegate<SessionTestFilter> {
  let filter: SessionTestFilter
  init(start: Session.Model) {
    filter = SessionTestFilter(seed: SessionTestFilter.Model(session: start))
    super.init(
      filter: filter,
      session: Session.shared
    )
  }
  var events: [Session.Model] { return
    filter.events.map { $0.session }
  }
}

class SessionTestFilter: SinkSourceConverting {
  let seed: Model
  var events: [Model] = []
  struct Model {
    var session: Session.Model
  }
  init(seed: Model) {
    self.seed = seed
  }
  func effectsFrom(events: Observable<Model>) -> Observable<Model> {
    events.subscribe {
      if let new = $0.element {
        self.events += [new]
      }
    }
    return Session.shared
      .rendered(events.map { $0.session })
      .withLatestFrom(events) {
        var edit = $0.1
        edit.session = $0.0
        return edit
    }
  }
  func start() -> Model { return
    seed
  }
}
