//
//  MutatingLensVisualizer.swift
//  Integer Mutation Animated
//
//  Created by Zev Eisenberg on 1/11/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import Cycle
import RxSwift

class MutatingLensVisualizer: UIView {

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
            render(newModel: model, oldModel: oldValue)
        }
    }

    init(name: String) {
        super.init(frame: .zero)

        let stack = UIStackView(arrangedSubviews: [inView, centerLabel, outView])
        stack.axis = .vertical
        stack.alignment = .leading
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

extension MutatingLens {

    func visualize<T>(name: String, input: MutatingLens) -> MutatingLens<A, MutatingLensVisualizer> where A: ObservableType, A.Element == T {
        MutatingLens<A, MutatingLensVisualizer>.init(
            value: input.value,
            get: ({ (state: A) -> MutatingLensVisualizer in
                MutatingLensVisualizer.visualize(
                    input: state,
                    output: Observable<T>.never(),
                    name: name
                )
            }),
            set: { (visualizer: MutatingLensVisualizer, state: A) in state }
        )
    }

}

extension MutatingLensVisualizer {

    static func visualize<Input: ObservableType, Output: ObservableType>(input: Input, output: Output, name: String) -> MutatingLensVisualizer {
        MutatingLensVisualizer(name: name).rendering(
            Observable.merge(
                input.map { _ in MutatingLensVisualizer.ViewModel.activeInput() },
                output.map { _ in MutatingLensVisualizer.ViewModel.activeEvent() }
            ), f: { (visualizer, newModel) in
                visualizer.model = newModel
        })
    }

}

private extension MutatingLensVisualizer {

    static func makeIOView(called name: String, color: UIColor) -> UIView {
        let view = UIView()
        let label = UILabel()
        label.text = name
        label.textColor = .white
        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            label.topAnchor.constraint(equalTo: view.topAnchor),
            label.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        view.backgroundColor = color
        return view
    }

    func render(newModel: ViewModel, oldModel: ViewModel) {
        inView.backgroundColor = newModel.inColor
        outView.backgroundColor = newModel.outColor
    }

}
