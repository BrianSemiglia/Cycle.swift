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
  init(start: Session.Model, reducer: @escaping ((Session.Model) -> Session.Model) = { $0 }) {
    filter = SessionTestFilter(
      seed: SessionTestFilter.Model(session: start),
      reducer: reducer
    )
    super.init(
      filter: filter
    )
  }
  var events: [Session.Model] { return
    filter.events.map { $0.session }
  }
}

class SessionTestFilter: SinkSourceConverting {
  let seed: Model
  let reducer: (Session.Model) -> Session.Model
  var events: [Model] = []
  struct Model {
    var session: Session.Model
  }
  init(seed: Model, reducer: @escaping (Session.Model) -> Session.Model) {
    self.seed = seed
    self.reducer = reducer
  }
  func effectsFrom(events: Observable<Model>, session: Session) -> Observable<Model> {
    events.subscribe {
      if let new = $0.element {
        self.events += [new]
      }
    }
    return session
      .rendered(events.map { $0.session })
      .withLatestFrom(events) {
        var edit = $0.1
        edit.session = self.reducer($0.0)
        return edit
    }
  }
  func start() -> Model { return
    seed
  }
}
