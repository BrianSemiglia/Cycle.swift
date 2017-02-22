##Overview
Cycle provides a means of writing an app as a filter over a stream of external events.

1. The event stream is fed to a reducer that produces a stream of driver models.
2. The driver model stream is fed to drivers that render the side-effects of those models.
3. The drivers produce a stream of new driver models which are mapped to events.
4. The cycle repeats.

For example:
```
                                DriverModel -> Network
Event + AppModel -> AppModel -> DriverModel -> Screen  -> DriverModel -> Event
                                DriverModel -> Session
```
A sample project of the infamous 'Counter' app is included.

##Usage
1. Subclass CycledApplicationDelegate and provide a SinkSourceConverting filter.

  ``` swift
  @UIApplicationMain
  class Example: CycledApplicationDelegate<MyFilter> {
    init() {
      super.init(handler: MyFilter())
    }
  }

  struct MyFilter: SinkSourceConverting {

    // Serves as schema and initial state.
    struct AppModel: Initializable {
      var network = Network.Model()
      var screen = Screen.Model()
      var session = Session.Model()
    }
    
    struct Drivers: CycleDrivable {
      var network = Network()
      var screen = Screen()
      var application = RxUIApplication! // Provided by Cycle internally. Struct must be able to host.
    }

    func effectFrom(events: Observable<AppModel>, drivers: Drivers) -> Observable<AppModel> {

      let network = drivers.network
        .rendered(events.map { $0.network })
        .withLatestFrom(events) { ($0.0, $0.1) }
        .reducingFuctionOfYourChoice()

      let screen = drivers.screen
        .rendered(events.map { $0.screen })
        .withLatestFrom(events) { ($0.0, $0.1) }
        .reduced()

      let application = drivers.application.shared
        .rendered(events.map { $0.session })
        .withLatestFrom(events) { ($0.0, $0.1) }
        .reduced()

      return Observable
        .of(network, screen, application)
        .merge()
    }

  }
  ```
2. Define reducers.

  ```swift
  extension ObservableType where E == (Network.Model, AppModel) {
    func reducingFuctionOfYourChoice() -> Observable<AppModel> { return
      map { event, context in
        var new = context
        switch event.state {
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
  }

  extension ObservableType where E == (Screen.Model, AppModel) {
    func reduced() -> Observable<AppModel> { return
      map { event, context in
        var new = context
        switch event.button.state {
          case .highlighted:
            new.network.state = .awaitingStart
          default: 
            break
        }
        return new
      }
    }
  }

  extension ObservableType where E == (Session.Model, AppModel) {
    func reduced() -> Observable<AppModel> { return
      map { event, context in
        var new = context
        switch event.state {
          case .launching:
            new.screen = Screen.Model.downloadView
          default: 
            break
        }
        return new
      }
    }
  }
```
3. Define drivers that, given a stream of models, can produce streams of model in response to events (hand-waving)

##Notes of Interest
1. Drivers are currently singletons.
2. Drivers of similar libraries communicate with the app directly. Cycle inverts that dependancy a bit with the use of observables (versus drivers subscribing to the app model) and with the return of models that are owned by the drivers (versus actions owned by the app model).

##Goals
- [x] Push boilerplate code into framework.
- [x] Refactor reducers to receive/output streams to allow for use of rx features.
- [ ] Reconsider use of singletons.
- [ ] Create drivers that provide app-state, push-notification, etc. events that the usual app-delegate would. 
