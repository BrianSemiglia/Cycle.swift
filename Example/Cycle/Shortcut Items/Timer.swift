//
//  Timer.swift
//  Cycle
//
//  Created by Brian Semiglia on 2/9/17.
//  Copyright © 2017 Brian Semiglia. All rights reserved.
//

import Foundation
import RxSwift
import Changeset

class Timer {
  init(_ input: Model) {
    model = input
    output = BehaviorSubject<Model>(value: input)
  }
  
  static let shared = Timer(.empty)
  fileprivate var cleanup = DisposeBag()
  fileprivate let input: Observable<Model>?
  fileprivate let output: BehaviorSubject<Model>
  fileprivate var model: Model {
    didSet {
      Changeset(source: oldValue.operations, target: model.operations)
      .edits
      .flatMap { x -> Model.Operation? in
        if case .insertion = x.operation { return x.value }
        else { return nil }
      }
      .filter { $0.running }
      .forEach { old in
        DispatchQueue.main.asyncAfter(deadline: .now() + old.length) { [weak self] in
          if var model = self?.model {
            model.operations = model.operations.map { new in
              if new.id == old.id {
                var edit = new
                edit.running = false
                return edit
              } else {
                return new
              }
            }
            self?.output.on(.next(model))
          }
        }
      }
    }
  }
  
  struct Model {
    struct Operation {
      var id: String
      var running: Bool
      var length: TimeInterval
    }
    var operations: [Operation]
  }
  
  func rendered(_ input: Observable<Model>) -> Observable<Model> {
    self.input = input
    self.input?.subscribe {
      if let model = $0.element {
        self.model = model
      }
    }.disposed(by: cleanup)
    return output
  }
}

extension Timer.Model {
  static var empty: Timer.Model { return
    Timer.Model(operations: [])
  }
}

extension Timer.Model.Operation: Equatable {
  static func ==(left: Timer.Model.Operation, right: Timer.Model.Operation) -> Bool { return
    left.id == right.id &&
    left.running == right.running &&
    left.length == right.length
  }
}
