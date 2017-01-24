##Overview
Cycle provides a means of writing an app as a filter over a stream of external events.

1. The event stream is fed to a reducer that produces a stream of new models.
2. The app stream is fed to drivers that render the side-effects of those models.
3. The drivers produce a stream of new models which are mapped to events.
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

  /* Aside from defining DriverEvent, AppModel and _start_, this is boilerplate and could afford to be pushed below. */
  struct MyFilter: SinkSourceConverting {

    enum DriverEvent {
      case network (Network.Model)
      case screen  (Screen.Model)
      case session (Session.Model)
    }

    struct AppModel {
      var network: Network.Model
      var screen:  Screen.Model
      var session: Session.Model
    }

    func eventsFrom(effects: Observable<AppModel>) -> Observable<DriverEvent> {

      let network = Network.shared
        .rendered(effects.map { $0.network })
        .map { DriverEvent.network($0) }

      let screen = Screen.shared
        .rendered(effects.map { $0.screen })
        .map { DriverEvent.screen($0) }

      let session = Session.shared
        .rendered(effects.map { $0.session })
        .map { DriverEvent.session($0) }

      return Observable
        .of(network, screen, session)
        .merge()
    }

    func effectsFrom(events: Observable<DriverEvent>) -> Observable<AppModel> { return
      events.map {
        switch $0.0 {
        case .network(let e): return e.reduced($0.1)
        case .screen(let e): return e.reduced($0.1)
        case .session(let e): return e.reduced($0.1)
        }
      }
    }

    func start() -> (DriverEvent, AppModel) { return
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
    func reduced(_ input: AppModel) -> AppModel {
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
    func reduced(_ input: AppModel) -> AppModel {
      var new = input
      switch self.button.state {
        case .highlighted:
          new.network.state = .awaitingStart
        default: 
          break
      }
    }
  }

  extension Session.Model {
    func reduced(_ input: AppModel) -> AppModel {
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
3. Define drivers that, given a stream of models, can produce streams of events (hand-waving)

##Notes of Interest
1. Drivers are currently singletons.
2. Drivers of similar libraries communicate with their shared-stores directly. Cycle inverts that dependancy a bit by with the use of observables (versus drivers subscribing to the app model) and with the return of models that are owned by the drivers (versus actions owned by the app model).

##Goals
- [ ] Push boilerplate code into framework.
- [ ] Refactor reducers to receive/output streams to allow for use of rx features.
- [ ] Reconsider use of singletons.
- [ ] Create drivers that provide app-state, push-notification, etc. events that the usual app-delegate would. 
