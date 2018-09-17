//
//  ValueToggler.swift
//  Cycle
//
//  Created by Brian Semiglia on 1/2/17.
//  Copyright © 2017 Brian Semiglia. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import CoreLocation //
import Cycle

class ValueToggler: RootViewProviding {
    
  struct Model {
    struct Button {
      enum State {
        case enabled
        case disabled
        case highlighted
      }
      var state: State
      var title: String
    }
    var total: String
    var increment: Button
    var decrement: Button
  }

  
  enum Action {
    case incrementing
    case decrementing
  }
  
  let label = UILabel(
    frame: CGRect(
      origin: CGPoint(
        x: 50,
        y: 100
      ),
      size: CGSize(
        width: 100,
        height: 44
      )
    )
  )
  
  var increment = UIButton(
    frame: CGRect(
      origin: CGPoint(x: 114, y: 144),
      size: CGSize(width: 44, height: 44)
    )
  )
  var decrement = UIButton(
    frame: CGRect(
      origin: CGPoint(x: 50, y: 144),
      size: CGSize(width: 44, height: 44)
    )
  )
  
  var cleanup = DisposeBag()
  let root = UIViewController.empty
  
  init() {
    increment.backgroundColor = .gray
    decrement.backgroundColor = .red
    root.view.addSubview(label)
    root.view.addSubview(increment)
    root.view.addSubview(decrement)
  }
  
  func eventsCapturedAfterRendering(_ input: Observable<ValueToggler.Model>) -> Observable<ValueToggler.Action> {
    input
      .observeOn(MainScheduler.instance)
      .subscribe { possible in
        if let latest = possible.element {
          self.increment.isEnabled = latest.increment.state == .enabled
          self.increment.isEnabled = latest.increment.state != .disabled
          self.increment.alpha = latest.increment.state == .disabled ? 0.5 : 1
          self.increment.setTitle(
            latest.increment.title,
            for: .normal
          )
          self.decrement.isEnabled = latest.decrement.state == .enabled
          self.decrement.isEnabled = latest.decrement.state != .disabled
          self.decrement.alpha = latest.decrement.state == .disabled ? 0.5 : 1
          self.decrement.setTitle(
            latest.decrement.title,
            for: .normal
          )
          self.label.text = latest.total
        }
      }
      .disposed(by:cleanup)
    
    let inc = self.increment.rx.tap.asObservable().map { _ in
      ValueToggler.Action.incrementing
    }
    
    let dec = self.decrement.rx.tap.asObservable().map { _ in
      ValueToggler.Action.decrementing
    }
    return Observable.of(inc, dec).merge()
  }
}

extension ValueToggler.Model {
  func copyWith(inc: ValueToggler.Model.Button.State, dec: ValueToggler.Model.Button.State) -> ValueToggler.Model {
    var x = self
    x.decrement.state = dec
    x.increment.state = inc
    return x
  }
}

extension ValueToggler.Model {
  static var empty: ValueToggler.Model { return
    ValueToggler.Model(
      total: "0",
      increment: ValueToggler.Model.Button(state: .enabled, title: "+"),
      decrement: ValueToggler.Model.Button(state: .enabled, title: "-")
    )
  }
}

extension UIViewController {
  public static var empty: UIViewController {
    let x = UIViewController()
    x.view.backgroundColor = .white
    return x
  }
}
