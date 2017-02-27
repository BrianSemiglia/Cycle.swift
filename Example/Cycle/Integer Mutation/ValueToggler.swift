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

class ValueToggler: UIViewControllerProviding {
  
  static var shared = ValueToggler()
  
  struct Model {
    struct Button {
      enum State {
        case enabled
        case highlighted
      }
      var state: State
      var title: String
    }
    var total: String
    var increment: Button
    var decrement: Button
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
  var input: Observable<Model>?
  let root = UIViewController.empty
  
  init() {
    increment.backgroundColor = .gray
    decrement.backgroundColor = .red
    root.view.addSubview(label)
    root.view.addSubview(increment)
    root.view.addSubview(decrement)
  }
  
  func rendered(_ input: Observable<ValueToggler.Model>) -> Observable<ValueToggler.Model> {
    input.subscribe { possible in
      if let latest = possible.element {
        self.increment.setTitle(
          latest.increment.title,
          for: .normal
        )
        self.decrement.setTitle(
          latest.decrement.title,
          for: .normal
        )
        self.label.text = latest.total
      }
    }.disposed(by:cleanup)

    let inc = self.increment.rx.tap.asObservable()
      .withLatestFrom(input) { _, model -> ValueToggler.Model in
        model.copyWith(
          inc: ValueToggler.Model.Button.State.highlighted,
          dec: model.decrement.state
        )
    }
    
    let dec = self.decrement.rx.tap.asObservable()
      .withLatestFrom(input) { _, model -> ValueToggler.Model in
        model.copyWith(
          inc: model.increment.state,
          dec: ValueToggler.Model.Button.State.highlighted
        )
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
