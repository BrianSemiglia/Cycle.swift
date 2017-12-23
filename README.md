# Cycle.swift

[![Version](https://img.shields.io/cocoapods/v/Cycle.svg?style=flat)](http://cocoapods.org/pods/Cycle)
[![License](https://img.shields.io/cocoapods/l/Cycle.svg?style=flat)](http://cocoapods.org/pods/Cycle)
[![Platform](https://img.shields.io/cocoapods/p/Cycle.svg?style=flat)](http://cocoapods.org/pods/Cycle)

## Overview
Cycle provides a means of writing an application as a function that reduces a stream of events to a stream of effects.

### Anatomy
Effect - A struct representing the state of the entire application at a given moment  
Pre-Filter - A function that converts effects to driver-models that are stripped of redundancies  
Driver - An isolated, stateless object that renders effects to hardware and deliver events  
Event - An enum expressing events experienced by hardware  
Post-Filter - A function that produces Effects based on input Events  

### Composition
1. `Effects` arrive as inputs to the main function.
2. `Effects` are routed to pre-filter functions that produce models specific to `Drivers`.
3. `Models` are fed to each `Driver` to be rendered to hardware.
4. `Drivers` deliver `Events` as they arrive.
5. The `Event` along with the previous _n_ `Effects` are fed to a post-filter to produce a new `Effect`.
6. The new `Effect` is input to another execution of the main function and a cycle is produced.

```
effect --------> driver ----------> event + previous effects -> new effect
         
Network.Model -> Network                    Network.Model       Network.Model
Screen.Model  -> Screen  -> Network.Event + Screen.Model   ---> Screen.Model
Session.Model -> Session                    Session.Model       Session.Model
```

### Concept
The goal is to produce an application that has clear and uniform boundaries between the declarative and procedural. The declarative side can be understood as a timeline of `Effects` based on the incoming timeline of `Events` which when intertwined can be visualized as such:

![alt tag](cycled_model_timeline.png)

The procedural rendering of those timelines can be visualized like so:

![alt tag](cycled_drivers_reduced.gif)

[View as higher-res SVG](https://briansemiglia.github.io/cycled_drivers_reduced.svg)

## In-Depth
### Anatomy
#### Effect
The `Effect` is simply a struct representing the state of application at a given moment. Its value can store anything that you might expect objects to normally maintain such as view-frames/colors, navigation-traversal, item-selections, etc. Ideally, the storage of values that can be derived from other values should be avoided. If performance is a concern there is the potential for the caching/memoization of values due to the mostly-referentially-transparent nature of pre/post-filters.  
  
#### Pre-Filter
A pre-filter function allows for applying changes to a received Effect before being rendered. There are two common filters:
  
- A conversion from your application-specific model to a driver-specific one. This design prevents a dependency of any particular driver to any particular global domain and is basically an application of the Dependency Inversion Priciple.  

- An equality check to prevent unnecessary renderings. If a desired effect has been rendered, a model can be created with some sort of no-op value instead. In order to access the previous _n_ effects for this equality check, the `scan` Rx operator can be used. It would also make sense that `Drivers` be the providers of this sort of filter as the implementation of the filter would depend of the `private` implementation of the `Driver`. Either way, this sort of filter would provide a deterministic function for `Driver` state management.

#### Driver
Drivers are stateless objects that simply receive a value, render it to hardware in some way and output `Event` values as they are experienced by hardware. They ideally have one input function (`render(model: RxSwift.Observable<Driver.Model>)`) and one output property (`RxSwift.Observable<Driver.Event>`). They also ideally have no concept of what is beyond their interface, avoiding references to global singletons/types and having a model that they have autonomy over; this would be another application of the Dependency Inversion Principle.

#### Event
Events are simple enum values that may also contain associated values received by hardware. Events are ideally defined and owned by a `Driver` as opposed to being defined at the application level (Dependency Inversion Principle).

#### Post-Filter
A post-filter function allows for the creation of a new `Effect` based on an incoming `Event` and the current `Effect`. The `Effect` created here becomes available to the incoming `Effect` stream of the main function and is also how a previous `Effect` is accessed using the Rx `scan` operator. The `scan` operator is not limited to just the immediately preceding `Effect` in the timeline; any previous `Effect` can be accessed. This is useful for determinations that require a larger context. For example, a touch-gesture could be recognized by looking at the last _n_ number of touch-coordinates. 

## Reasoning

### Change without Change
Applications are functions that transform values based on events. However, functional programming discourages mutability. How can something change without changing? Cycle attempts to answer that question with a flip-book like model. Just as every frame of a movie is unchanging, so can be view-models. Change is only produced once a frame is fed into a projector and run past light, or rendered rather. In the same way, Cycle provides the scaffolding necessary to feed an infinite list of view-models into drivers to be procedurally rendered.

### Truth
Objects typically maintain their own version of the truth. This has the potential to lead to many truths, sometimes conflicting. These conflicts can cause stale/incorrect data to persist. A single source of truth provides consistency for all. 

At the same time, moving state out of objects removes their identity and makes them much reusable/disposable. For example, a view that is not visible can be freed/reused without losing the data that it was hosting.

### Perspective
Going back to the flip-book philosophy, more complex animations also include the use of sound. Light and sound are two perspectives rendered in unison to create the illusion of physical cohesion. The illusion is due to the mediums having no physical dependence on one another. In the Cycle architecture, drivers are the perspectives of the application's state.

Further, perspectives don't have to be specific to a single medium. For example, a screen implemented as a nested-tree of views could be instead be implemented as an array of independent views backed by a nested-model. This would prevent changes to a child-view's interface from rippling up to its parents, grandparents, etc. while still allowing for a coordinated rendering. Scaled up, this has the potential to produce an application where there is only ever one degree of delegation.

### Self-Centered Perspective
Just as paper and celluloid aren't exclusive to the purpose of movies, drivers are independent of an application’s intentions. Drivers set the terms of their contract (view-model) and the events they output. Changes to an application's model don’t break its drivers' design. Changes to its drivers' design do break the application's design. This produces modularity amongst drivers.

### Values as Commands
Frames in an animation are easy to understand as values, but they can also be understood as commands for the projector at a given moment. By storing driver-commands as values, commands can be used just as frames (verified, reversed, throttled, filtered, spliced, and replayed); all of which make for useful [development tools](https://github.com/BrianSemiglia/CycleMonitor).

![alt tag](https://github.com/BrianSemiglia/CycleMonitor/raw/master/readme_images/overview.gif)

### Live Broadcast
The flip-book model breaks a bit when it comes to the uncertain future of an application’s timeline. Each frame of an animation is usually known before playback but because drivers provide a finite set of possible events, that uncertainty can be constrained and given the means to produce the next frame for every action.

## Implementation
```swift
public protocol SinkSourceConverting {
  /* 
    Defines schema and initial values of application model.
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
  @UIApplicationMain class Example: CycledApplicationDelegate<MyFilter> {
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

    func effectsFrom(previous: Observable<AppModel>, drivers: Drivers) -> Observable<AppModel> {

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
- [Turing Machine](https://en.wikipedia.org/wiki/Turing_machine)

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
