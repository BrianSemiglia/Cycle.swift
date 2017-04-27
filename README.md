# Cycle.swift

[![Version](https://img.shields.io/cocoapods/v/Cycle.svg?style=flat)](http://cocoapods.org/pods/Cycle)
[![License](https://img.shields.io/cocoapods/l/Cycle.svg?style=flat)](http://cocoapods.org/pods/Cycle)
[![Platform](https://img.shields.io/cocoapods/p/Cycle.svg?style=flat)](http://cocoapods.org/pods/Cycle)

## Overview
Cycle provides a means of writing an app as a function that filters over a stream of external events.

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

Each branch of your App.Model that can experience an Event-callback provides a Reducer function that can convert that Event into a new App.Model. The declarative side of your application becomes a timeline of App.Models based on the incoming timeline of Events.

![alt tag](cycled_model_timeline.png)

The procedural side of your application is composed of isolated drivers that render Models specific to their needs. Those drivers also execute callback functions that provide Events.

![alt tag](cycled_drivers_reduced.gif)

[View as higher-res SVG](https://briansemiglia.github.io/cycled_drivers_reduced.svg)

## Reasoning

### Change without Change
Applications are functions that transform events and values into effects and new values. However, functional programming discourages mutability. How can something change without changing? Cycle attempts to answer that question with a flip-book like model. Just as every frame of a movie is unchanging, so are view-models. Change is only produced once the frame is fed past light or rendered rather. Cycle provides the scaffolding necessary to feed an infinite list of view-models into drivers to be procedurally rendered.

### Truth and Perspective
More complex animations include the use of sound. Light and sound are rendered in unison to form a cohesive presentation. Those renderings are based on the same abstract truth. In the Cycle architecture, drivers render effects from their own perspective of the App State. A single source of truth provides consistency for all. Drivers also deliver events from the outside world but the metaphor doesn't work quite as well in explaining that.

### Parallel Perspectives
Another point of interest to note is the drivers’ parallel relationship to each other. Drivers don’t require an exclusive relationship with a specific medium/hardware but can instead have an exclusive relationship with a smaller perspective of that medium/hardware. For example, a screen implemented as a tree of drivers could be instead be implemented as an array of independent drivers backed by a nested view-model. This would prevent changes to child-view-interfaces from rippling up to their parents' while still allowing for coordinated renderings.

### Self-Centered Perspectives
Just as paper and celluloid aren't exclusive to the purpose of stories, drivers are independent of an application’s intentions. Drivers set the terms of their contract (view-model) and the events they produce. Changes to an application's model don’t break its drivers' design. Changes to its drivers' design do break the application's design.

### Values as Commands
Frames in an animation are easy to understand as values, but they can also be understood as commands for the projector at a given moment. By storing driver-commands as values, commands can be used just as frames (verified, reversed, throttled, filtered, spliced, and replayed); all of which make for useful development tools.

### Live Broadcast
The flip-book model breaks a bit when it comes to the uncertain future of an application’s timeline. Each frame of an animation is usually known before playback but because drivers provide a finite set of possible events, that uncertainty can be constrained and given the means to produce the next frame for every action.

## Filter Design
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

## Example
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

  }
  ```

A sample project of the infamous 'Counter' app is included.

## Related Material
- [Boundaries by Gary Bernhardt](https://www.youtube.com/watch?v=yTkzNHF6rMs)
- [Cycle.js](https://cycle.js.org)
- [Unidirectional data flow architectures, Andre Staltz - AtTheFrontend 2016](https://www.youtube.com/watch?v=1c6XiQsnh_U)
- [Unidirectional User Interface Architectures - Andre Staltz](https://staltz.com/unidirectional-user-interface-architectures.html)
- [Redux](http://redux.js.org), [ReSwift](https://github.com/ReSwift/ReSwift)
- [Elm Architecture](https://guide.elm-lang.org/architecture/)

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
