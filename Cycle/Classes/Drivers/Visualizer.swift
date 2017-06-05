//
//  Visualizer.swift
//  Pods
//
//  Created by Brian Semiglia on 5/27/17.
//
//

import Foundation
import RxSwift

public class SecondScreenDriver {
  public struct Model {
    public struct Node {
      public enum State {
        case none
        case sending
        case receiving
      }
      public var state: State
      public var color: UIColor
      public var frame: CGRect
      
      public init(state: State, color: UIColor, frame: CGRect) {
        self.state = state
        self.color = color
        self.frame = frame
      }
      
      //        public static func ==(left: Node, right: Node) -> Bool { return
      //          left.state == right.state &&
      //          left.color == right.color
      //        }
    }
    public var nodes: [Node]
    public var debug: String
    public var description: String {
      return ""
    }
    
    public init(nodes: [Model.Node], description: String) {
      self.nodes = nodes
      self.debug = description
    }
    //      public static func ==(left: Model, right: Model) -> Bool { return
    //        left.nodes == right.nodes &&
    //        left.description == right.description
    //      }
  }
  
  private var window: UIWindow?
  private let cleanup = DisposeBag()
  private let output: BehaviorSubject<Model>
  private var model: Model
  private let label = UILabel(frame: .zero)
  private var input: Observable<Model>?
  
  public required init(initial: Model) {
    model = initial
    output = BehaviorSubject<Model>(value: initial)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(didReceiveScreenDidConnect(notification:)),
      name: NSNotification.Name.UIScreenDidConnect,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(didReceiveScreenDidDisconnect(notification:)),
      name: NSNotification.Name.UIScreenDidDisconnect,
      object: nil
    )
    DispatchQueue.main.async {
      self.window = self.windowFrom(screens: UIScreen.screens)
      self.window?.rootViewController?.view.addSubview(self.label)
      self.render(new: self.model, old: self.model)
    }
  }
  
  func windowFrom(screens: [UIScreen]) -> UIWindow? {
    if screens.count > 1 {
      let second = UIScreen.screens[1]
      let x = UIWindow(frame: second.bounds)
      x.screen = second
      x.rootViewController = UIViewController().with(background: .white)
      x.makeKeyAndVisible()
      return x
    } else {
      return nil
    }
  }
  
  @objc func didReceiveScreenDidConnect(notification: Notification) {
    window = windowFrom(screens: UIScreen.screens)
  }
  @objc func didReceiveScreenDidDisconnect(notification: Notification) {
    window = nil
  }
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  public func rendered(_ input: Observable<Model>) -> Observable<Model> {
    self.input = input
    self.input?.subscribe {
      if let new = $0.element {
        self.render(new: new, old: self.model)
      }
    }.disposed(by: cleanup)
    return output//.distinctUntilChanged()
  }
  func render(new: Model, old: Model) {
    label.text = new.debug
    label.font = UIFont.systemFont(ofSize: 10)
    label.numberOfLines = 0
    label.backgroundColor = .white
    label.frame = window?.rootViewController.map {
      CGRect(
        origin: .zero,
        size: $0.view.bounds.size
      )
    } ?? .zero
    
    self.window?.rootViewController?.view.subviews.forEach {
      if $0 is UILabel == false {
        $0.removeFromSuperview()
      }
    }
    
    new.nodes.forEach {
        let x = UIView(frame: $0.frame)
        x.backgroundColor = $0.color
        self.window?.rootViewController?.view.addSubview(x)
    }
    
    let lastNode = new.nodes.last.map { $0.frame } ?? .zero
    
    label.frame = CGRect(
      origin: CGPoint(x: 0, y: lastNode.origin.y + lastNode.height),
      size: window?.rootViewController.map {
        CGSize(
          width: $0.view.bounds.width,
          height: $0.view.bounds.height - lastNode.height
        )
      } ?? .zero
    )
  }
}

extension UIViewController {
  func with(background: UIColor) -> UIViewController {
    view.backgroundColor = background
    return self
  }
}

public protocol VisualizerStringConvertible {
  var description : String { get }
}

public extension VisualizerStringConvertible {
  var description : String {
    var description: String = "***** \(type(of: self)) *****\n"
    let selfMirror = Mirror(reflecting: self)
    selfMirror.children
      .filter {
        let x = String(describing: $0.label)
        return x.range(of: "secondScreen") == nil
      }
      .forEach { child in
        if let propertyName = child.label, propertyName != "secondScreen" {
          description += "\(propertyName): \(child.value)\n"
      }
    }
    
    return prettyPrint(description)
  }
  
  func prettyPrint(_ input: String) -> String { return
    Array(input.characters)
      .reduce(("", 0)) {
        switch String($1) {
        case ",":
          return (
            $0.0 + ",\n" + whiteSpaceWith(length: $0.1 - 1),
            $0.1
          ) // comma experiences weird trailing space, thus minus 1
        case "(":
          return (
            $0.0 + "(\n" + whiteSpaceWith(length: $0.1 + 4),
            $0.1 + 4
          )
        case ")":
          return (
            $0.0 + "\n" + whiteSpaceWith(length: $0.1 - 4) + ")",
            $0.1 - 4
          )
        default:
          return (
            $0.0 + String($1),
            $0.1
          )
        }
      }.0
  }
  
  func whiteSpaceWith(length: Int) -> String {
    return Array(0...length).map{ _ in " "}.reduce("", +)
  }
}
