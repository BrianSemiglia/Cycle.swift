//
//  MutatingLensVisualizer.swift
//  Integer Mutation Animated
//
//  Created by Zev Eisenberg on 1/11/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import RxSwift

final public class MutatingLensVisualizer: UIView {

    struct ViewModel {
        var inColor: UIColor
        var outColor: UIColor
    }

    private let inView = makeIOView(called: "I", color: UIColor.gray)
    private let outView = makeIOView(called: "O", color: UIColor.gray)
    private let centerLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    var model: ViewModel = .idle() {
        didSet {
            render(
                newModel: model,
                oldModel: oldValue
            )
        }
    }

    init(name: String) {
        super.init(frame: .zero)

        let stack = UIStackView(arrangedSubviews: [inView, centerLabel, outView])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 10

        centerLabel.text = name

        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    @available(*, unavailable) required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension MutatingLensVisualizer.ViewModel {

    static func activeEvent() -> Self {
        .init(inColor: .gray, outColor: .red)
    }

    static func activeInput() -> Self {
        .init(inColor: .red, outColor: .gray)
    }

    static func idle() -> Self {
        .init(inColor: .gray, outColor: .gray)
    }

}

extension UIColor {
    static func random() -> UIColor {
        UIColor(
            hue: .random(in: 0...1),
            saturation: .random(in: 0.8...1),
            brightness: 1,
            alpha: 1
        )
    }
}

public extension MutatingLens {

    func visualize<T>(name: String) -> MutatingLens<A, (B, MutatingLensVisualizer)> where A == Observable<T> {
        MutatingLens.zip(
            self,
            MutatingLens<A, MutatingLensVisualizer>(
                value: value,
                get: { state in
                    .visualize(
                        input: state,
                        output: Observable.merge(self.set),
                        name: name
                    )
                }
            )
        )
    }

public extension NSObject {
    static func zipVisualized<X, Y, Z>(
        _ first: MutatingLens<Observable<X>, Y>,
        _ second: MutatingLens<Observable<X>, Z>
    ) -> MutatingLens<Observable<X>, (Y, Z, UIView)> {
        MutatingLens
            .zip(
                first.visualize(name: "first"),
                second.visualize(name: "second")
            )
            .map { states, receivers -> (Y, Z, UIView) in
                let stack = UIStackView(
                    arrangedSubviews: [
                        receivers.0.1,
                        receivers.1.1
                    ]
                )
                let first = receivers.0.0
                let second = receivers.1.0
                return (first, second, stack)
            }
    }
    
    static func zip<X, Y, Z>(
        _ first: MutatingLens<Observable<X>, (Y, MutatingLensVisualizer)>,
        _ second: MutatingLens<Observable<X>, (Z, MutatingLensVisualizer)>
    ) -> MutatingLens<Observable<X>, (Y, Z, UIView)> {
        MutatingLens
            .zip(
                first,
                second
            )
            .map { states, receivers -> (Y, Z, UIView) in
                let stack = UIStackView(
                    arrangedSubviews: [
                        receivers.0.1,
                        receivers.1.1
                    ]
                )
                let first = receivers.0.0
                let second = receivers.1.0
                return (first, second, stack)
            }
    }
}

extension MutatingLensVisualizer {
    static func visualize<Input: ObservableType, Output: ObservableType>(
        input: Input,
        output: Output,
        name: String
    ) -> MutatingLensVisualizer {
        MutatingLensVisualizer(name: name).rendering(
            Observable
                .merge(
                    input.flatMap { _ in
                        Observable
                            .just(.activeInput())
                            .concat(
                                Observable
                                    .just(.idle())
                                    .delay(.milliseconds(25), scheduler: MainScheduler())
                            )
                    },
                    output.flatMap { _ in
                        Observable
                            .just(.activeEvent())
                            .concat(
                                Observable
                                    .just(.idle())
                                    .delay(.milliseconds(25), scheduler: MainScheduler())
                            )
                    }
                )
                .pacedBy(delay: .milliseconds(30))
            ,
            f: { visualizer, newModel in
                visualizer.model = newModel
            }
        )
    }

}

extension ObservableType {
  func pacedBy(delay: RxTimeInterval) -> Observable<Element> {
    concatMap {
        Observable
            .just($0)
            .delay(delay, scheduler: MainScheduler.instance)
    }
  }
}

private extension MutatingLensVisualizer {

    static func makeIOView(called name: String, color: UIColor) -> UIView {
        let view = UIView()
        let label = UILabel()
        label.text = name
        label.textColor = .white
        label.textAlignment = .center
        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            label.topAnchor.constraint(equalTo: view.topAnchor),
            label.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            label.widthAnchor.constraint(equalTo: label.heightAnchor),
        ])
        view.backgroundColor = color
        return view
    }

    func render(newModel: ViewModel, oldModel: ViewModel) {
        inView.backgroundColor = newModel.inColor
        outView.backgroundColor = newModel.outColor
    }

}
