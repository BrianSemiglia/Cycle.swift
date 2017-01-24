# Cycle.swift
A experiment in unidirectional-data-flow inspired by Cycle.js.

##Overview
Cycle provides a means of writing an app as a filter over a stream of driver events.

1. The event stream is fed to a reducer that produces a stream of new models.
2. The app stream is fed to drivers that render the side-effects of those models.
3. The drivers produce a stream of new models which are coalesced to events.
4. The cycle repeats.

```
                                DriverModel -> Network -> DriverModel
Event + AppModel -> AppModel -> DriverModel -> Screen  -> DriverModel -> Event
                                DriverModel -> Session -> DriverModel
```

##Usage
1. Subclass CycledApplicationDelegate and provide a SinkSourceConverting filter.

``` swift
@UIApplicationMain
class Example: CycledApplicationDelegate<MyFilter> {
  init() {
    super.init(handler: MyFilter())
  }
}

/* Aside from defining DriverEvent, DriverModels and _start_, this is boiler-plate and could afford to be pushed below. */
struct MyFilter: SinkSourceConverting {

  enum DriverEvent {
    case network (Network.Model)
    case screen  (Screen.Model)
    case session (Session.Model)
  }

  struct DriverModels {
    var network: Network.Model
    var screen: Screen.Model
    var session: Session.Model
  }

  func eventsFrom(effects: Observable<DriverModels>) -> Observable<DriverEvent> {
    
    let network = Network.shared
      .rendered(effects.map { $0.network })
      .map { curry(DriverEvent.network)($0) }

    let screen = Screen.shared
      .rendered(effects.map { $0.screen })
      .map { curry(DriverEvent.screen)($0) }

    let session = Session.shared
      .rendered(effects.map { $0.session })
      .map { curry(DriverEvent.session)($0) }

    return Observable
      .of(network, screen, session)
      .merge()
  }

  func effectsFrom(events: Observable<DriverEvent>) -> Observable<DriverModels> { return
    events.map {
      switch $0.0 {
      case .network(let e): return e.reduced($0.1)
      case .screen(let e): return e.reduced($0.1)
      case .session(let e): return e.reduced($0.1)
      }
    }
  }

  func start() -> (DriverEvent, DriverModels) { return
    (
      .session(Session.Model.launching),
      DriverEvent.empty
    )
  }
}
```
2. Define reducers.

```swift
extension Network.Model {
  func reduced(_ input: DriverModels) -> DriverModels {
    var new = input
    switch self.state {
      case .idle:
        new.screen.button.color = .blue
      case .awaitingStart, .awaitingResponse:
        new.screen.button.color = .grey
      default: 
        break
    }
    return new
  }
}

extension Screen.Model {
  func reduced(_ input: DriverModels) -> DriverModels {
    var new = input
    switch self.button.state {
      case .highlighted:
        new.network.state = .awaitingStart
      default: 
        break
    }
  }
}

extension Screen.Model {
  func reduced(_ input: DriverModels) -> DriverModels {
    var new = input
      switch self.state {
        case .launching:
          new.screen = Screen.Model.downloadView
        default: 
          break
    }
  }
}

```
3. Define drivers that given a stream of models can produce streams of events (hand-waving)
