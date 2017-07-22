//
//  BugReporter.swift
//  Cycle
//
//  Created by Brian Semiglia on 7/20/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import RxSwift
import MessageUI

class BugReporter: NSObject, MFMailComposeViewControllerDelegate {
  struct Model {
    enum State {
      case idle
      case shouldSend
      case sending(Data)
    }
    var state: State
  }
  enum Action {
    case none
    case didSuccessfullySend
  }
  
  let cleanup = DisposeBag()
  let output = BehaviorSubject(value: Action.none)
  var model: Model
  
  init(initial: Model) {
    model = initial
  }
  
  func rendered(_ input: Observable<Model>) -> Observable<Action> {
    input.observeOn(MainScheduler.instance).subscribe { [weak self] in
      if let new = $0.element {
        if let `self` = self {
          if self.model != new {
            self.model = new
            self.render(new)
          }
        }
      }
    }.disposed(by: cleanup)
    return output
  }
  
  func render(_ input: Model) {
    switch input.state {
    case .sending(let data) where MFMailComposeViewController.canSendMail():
      let x = MFMailComposeViewController()
      x.addAttachmentData(
        data,
        mimeType: "application/json",
        fileName: "bug-report"
      )
      x.mailComposeDelegate = self
      UIApplication.shared.keyWindow?.rootViewController?.present(
        x,
        animated: true
      )
    case .idle:
      if UIApplication.shared.keyWindow?.rootViewController?.presentedViewController?.isKind(of: MFMailComposeViewController.self) == true {
        UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: true)
      }
    default:
      break
    }
  }
  
  func mailComposeController(
    _ controller: MFMailComposeViewController,
    didFinishWith result: MFMailComposeResult,
    error: Error?
  ) {
    output.on(.next(.didSuccessfullySend))
  }
}

extension BugReporter.Model: Equatable {
  static func ==(
    left: BugReporter.Model,
    right: BugReporter.Model
  ) -> Bool {
    return left.state == right.state
  }
}

extension BugReporter.Model.State: Equatable {
  static func ==(
    left: BugReporter.Model.State,
    right: BugReporter.Model.State
  ) -> Bool {
    switch (left, right) {
    case (.idle, .idle):
      return true
    case (.shouldSend, .shouldSend):
      return true
//    case (.sending(let a), .sending(let b)):
//      return a.hashValue == b.hashValue
    case (.sending(_), .sending(_)):
      return true
    default:
      return false
    }
  }
}
