# Cycle.swift

[![Version](https://img.shields.io/cocoapods/v/Cycle.svg?style=flat)](http://cocoapods.org/pods/Cycle)
[![License](https://img.shields.io/cocoapods/l/Cycle.svg?style=flat)](http://cocoapods.org/pods/Cycle)
[![Platform](https://img.shields.io/cocoapods/p/Cycle.svg?style=flat)](http://cocoapods.org/pods/Cycle)

##Overview
Cycle provides a means of writing an app as a filter over a stream of external events.

1. The event stream is fed to a reducer that produces a stream of driver models.
2. The driver model stream is fed to drivers that render the side-effects of those models.
3. The drivers produce a stream of suggested driver models in response to events.
4. The cycle repeats.

For example:
```
-------> event + context ------> effect -------> render --> event -------->
         
                 NetworkModel    NetworkModel -> Network
-> ScreenModel + ScreenModel  -> ScreenModel  -> Screen  -> NetworkModel ->
                 SessionModel    SessionModel -> Session
```

##Filter Design
```swift
public protocol SinkSourceConverting {
  /* 
    Defines schema and initial values of Driver Models.
  */
  associatedtype Source: Initializable
  
  /* 
    Defines drivers that handle effects, produce events. Requires two default drivers: 

      1. let application: UIApplicationDelegateProviding - can serve as UIApplicationDelegate
      2. let screen: ScreenDrivable - can provide a root UIViewController

    A default UIApplicationDelegateProviding driver, RxUIApplication, is included with Cycle.
  */
  associatedtype Drivers: UIApplicationDelegateProviding, ScreenDrivable

  /*
    Instantiates drivers with initial model. Necessary to for drivers that require initial values.
  */
  func driversFrom(initial: Source) -> Drivers

  /*
    Returns an effect stream of Driver Model, given an event stream of Driver Model. See example for intended implementation.
  */
  func effectsFrom(events: Observable<Source>, drivers: Drivers) -> Observable<Source>
}
```

##Example
1. Subclass CycledApplicationDelegate and provide a SinkSourceConverting filter.
  ``` swift
  @UIApplicationMain
  class Example: CycledApplicationDelegate<MyFilter> {
    init() {
      super.init(handler: MyFilter())
    }
  }

  struct MyFilter: SinkSourceConverting {

    struct AppModel: Initializable {
      let network = Network.Model()
      let screen = Screen.Model()
      let application = RxUIApplication.Model()
    }
    
    struct Drivers: UIApplicationDelegateProviding, ScreenDrivable {
      let network: Network
      let screen: Screen // Anything that provides a 'root' UIViewController
      let application: RxUIApplication // Anything that conforms to UIApplicationDelegate
    }

    func driversFrom(initial: AppModel) -> Drivers { return
      Drivers(
        network = Network(model: intitial.network),
        screen = Screen(model: intitial.screen),
        application = RxUIApplication(model: initial.application)
      )
    }

    func effectsFrom(events: Observable<AppModel>, drivers: Drivers) -> Observable<AppModel> {

      let network = drivers.network
        .rendered(events.map { $0.network })
        .withLatestFrom(events) { ($0.0, $0.1) }
        .reducingFuctionOfYourChoice()

      let screen = drivers.screen
        .rendered(events.map { $0.screen })
        .withLatestFrom(events) { ($0.0, $0.1) }
        .reduced()

      let application = drivers.application
        .rendered(events.map { $0.application })
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

  extension ObservableType where E == (RxUIApplication.Model, AppModel) {
    func reduced() -> Observable<AppModel> { return
      map { event, context in
        var new = context
        switch event.session.state {
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
  
3. Define drivers that, given a stream of event-models, can produce streams of effect-models
  ```swift
  class MyDriver {

    struct Model {
      var state: State
      enum State {
        case sending
        case receiving
      }
    }

    fileprivate let output: BehaviorSubject<Model>
    fileprivate let model: Model

    public init(initial: Model) {
      model = initial
      output = BehaviorSubject<Model>(value: initial)
    }

    public func rendered(_ input: Observable<Model>) -> Observable<Model> { 
      input.subscribe { [weak self] in
        if let strong = self, let new = $0.element {
          strong.model = new // Retain for async callback (-didReceiveEvent)
          strong.render(model: new)
        }
      }.disposed(by: cleanup)
      return self.output
    }

    func render(model: Model) {    
      if case .sending = model.state {
        // Perform side-effects...
      }
    }

    func didReceiveEvent() {
      var edit = model
      edit.state = .receiving
      output.on(.next(edit))
    }
    
    func didReceiveEvent() {
      var edit = model
      edit.state = .receiving
      output.on(.next(edit))
    }
  }
  ```

A sample project of the infamous 'Counter' app is included.

## Requirements
iOS 9+

## Installation
Cycle is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "Cycle"
```

## License
Cycle is available under the MIT license. See the LICENSE file for more info.
