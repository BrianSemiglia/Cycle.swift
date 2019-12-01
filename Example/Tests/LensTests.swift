//
//  LensTests.swift
//  CompositionsTests
//
//  Created by Brian Semiglia on 8/2/19.
//  Copyright © 2019 Brian Semiglia. All rights reserved.
//

import XCTest
import RxSwift
import RxBlocking
import RxTest
import RxExpect
import SnapshotTesting
import RxCocoa

@testable import Cycle

class LensTests: XCTestCase {

    func testLenzMapLeft() throws {
        let x = Observable<Int>.just(1).lens(
            get: { a in
                UILabel().rendering(a) { v, s in
                    v.text = String(s)
                    v.backgroundColor = .red
                    v.sizeToFit()
                }
            },
            set: { v, s in Observable<Int>.never() }
        )
        assertSnapshot(
            matching: x.get,
            as: .image
        )
    }

    func testLenzMapLeftMultipleStates() throws {
        let x = Observable.from([1, 2]).lens(
            get: { a in
                UILabel().rendering(a) { v, s in
                    v.text = String(s)
                    v.backgroundColor = .red
                    v.sizeToFit()
                }
            },
            set: { v, s in Observable<Int>.never() }
        )
        assertSnapshot(
            matching: x.get,
            as: .image
        )
    }

    func testMapLeftAppending() throws {
        let x = Observable.just(1).lens(
            get: { a -> UILabel in
                UILabel().rendering(a) { v, s -> Void in
                    v.text = String(s)
                    v.backgroundColor = .red
                    v.sizeToFit()
                }
            },
            set: { v, s in Observable<Int>.never() }
        )
        .map { s, v1 -> UIView in
            let v2 = UIView()
            v2.frame = CGRect(
                origin: .zero,
                size: CGSize(
                    width: v1.bounds.size.width + 10,
                    height: v1.bounds.size.height + 10
                )
            )
            v1.backgroundColor = .red
            v2.backgroundColor = .blue
            v2.addSubview(v1)
            return v2
        }

        assertSnapshot(
            matching: x.get,
            as: .image
        )
    }

    func testMapLeftMultipleStatesAppending() throws {
        let x = Observable.just(3).lens(
            get: { s -> UILabel in
                UILabel().rendering(s) { v, s -> Void in
                    v.text = String(s)
                    v.backgroundColor = .red
                    v.sizeToFit()
                }
            },
            set: { v, s in Observable<Int>.never() }
        )
        .map { s, v1 -> UIView in
            let v2 = UIView()
            v2.frame = CGRect(
                origin: .zero,
                size: CGSize(
                    width: v1.bounds.size.width + 10,
                    height: v1.bounds.size.height + 10
                )
            )
            v1.backgroundColor = .red
            v2.backgroundColor = .blue
            v2.addSubview(v1)
            return v2
        }
        .prefixed(with: .just(2))

        assertSnapshot(
            matching: x.get,
            as: .image
        )
    }

    func testMapRightMultipleMap() throws {
        let x = Observable<Int>.never().lens(
            get: { s in 0 },
            set: { v, s in Observable<Int>.from([3, 4]) }
        )
        .prefixed(with: .just(1))

        XCTAssertEqual(
            try Observable
                .merge(x.set)
                .take(3)
                .toBlocking()
                .toArray(),
            [1, 3, 4]
        )
    }

    func testMapRightMultipleStates() throws {
        let x = Observable.from([2, 3]).lens(
            get: { s in UILabel().rendering(s) { v, s in v.text = String(s) } },
            set: { v, s in Observable<Int>.never() }
        )

        XCTAssertEqual(
            x.get.text,
            "3"
        )
    }

    func testRecursiveUnique() throws {
        let x = CycledLens { stream in
            stream.lens(
                get: { s in UILabel().rendering(s) { v, s in v.text = String(s) } },
                set: { v, s in Observable.just(1) }
            )
            .prefixed(with: Observable.just(1))
        }

        XCTAssertEqual(
            try x
                .receiver
                .rx
                .observe(String.self, "text")
                .take(2)
                .toBlocking(timeout: 0.1)
                .toArray(),
            [nil, "1"]
        )

        XCTAssertThrowsError(
            try x
                .receiver
                .rx
                .observe(String.self, "text")
                .take(3)
                .toBlocking(timeout: 0.1)
                .toArray()
        )
    }

    func testRecursive() throws {
        let x = CycledLens { stream in
            stream.lens(
                get: { s in UILabel().rendering(s) { l, v in l.text = v } },
                set: { l, s in Observable.just("4") }
            )
            .prefixed(with: .just("1"))
        }

        XCTAssertEqual(
            try x
                .receiver
                .rx
                .observe(String.self, "text")
                .take(3)
                .toBlocking(timeout: 1)
                .toArray(),
            [nil, "1", "4"]
        )
    }


    func testCycledRecursive() throws {
        let x = CycledLens { stream in
            stream.lens(
                get: { s in UILabel().rendering(s) { l, v in l.text = v } },
                set: { l, s in Observable.from(["4", "5"]) }
            )
        }

        XCTAssertEqual(
            try x
                .receiver
                .rx
                .observe(String.self, "text")
                .take(3)
                .toBlocking(timeout: 1)
                .toArray(),
            [nil, "4", "5"]
        )
    }

    func testRecursiveMultipleMapRight() throws {
        let x = CycledLens { stream in
            stream.lens(
                get: { s in UILabel().rendering(s) { l, v in l.text = v } },
                set: { v, s -> [Observable<String>] in [
                    s.flatMap {
                        $0.count > 2
                            ? Observable.empty()
                            : Observable.just($0 + "2")
                    },
                    s.flatMap {
                        $0.count > 2
                            ? Observable.empty()
                            : Observable.just($0 + "3")
                    }
                ]}
            )
            .prefixed(with: .just("1"))
        }

        XCTAssertEqual(
            try x
                .receiver
                .rx
                .observe(String.self, "text")
                .take(8)
                .toBlocking()
                .toArray(),
            [nil, "1", "12", "13", "122", "123", "132", "133"]
        )
    }

    func testSubscribingOn() {
        let x = CycledLens { stream in
            stream.lens(
                get: { s in UILabel().rendering(s) { l, v in l.text = v } },
                set: { l, s in
                    l.rx
                        .willMoveToSuperview
                        .flatMap { $0 ? Observable.just("3") : .never() }
                }
            )
        }
        x.receiver.willMove(toSuperview: UIView())

        XCTAssertEqual(
            try x
                .receiver
                .rx
                .observe(String.self, "text")
                .take(2)
                .toBlocking()
                .toArray(),
            [nil, "3"]
        )
    }
    
    func testSuperview() {
        let view = UIView()
        let test = RxExpect()
        test.scheduler.scheduleAt(100) { view.willMove(toSuperview: UIView()) }
        test.assert(view.rx.willMoveToSuperview) { events in
            XCTAssertEqual(
                events.filter(.next).elements,
                [true]
            )
        }
    }

    func testStartingWith() {
        let x = CycledLens { stream in
            stream.lens(
                get: { s in UILabel().rendering(s) { l, v in l.text = v } },
                set: { v, s in Observable<String>.never() }
            )
            .prefixed(with: .just("99"))
        }

        XCTAssertEqual(
            try x
                .receiver
                .rx
                .observe(String.self, "text")
                .take(2)
                .toBlocking()
                .toArray(),
            [nil, "99"]
        )
    }

    func testLensZip() {
        let single = MutatingLens<String, Int>(
            value: "4",
            get: { string in Int(string)! },
            set: { int, string in "\(int)" }
        )
        XCTAssertEqual(single.get, 4)
        XCTAssertEqual(single.set, ["4"])
        let double = MutatingLens<String, Int>(
            value: "5",
            get: { string in Int(string)! * 2 },
            set: { int, string in "\(int * 2)" }
        )
        let c = MutatingLens.zip(single, double)
        XCTAssertEqual(c.get.0, 4)
        XCTAssertEqual(c.get.1, 10)
        XCTAssertEqual(c.set, ["4", "20"])
    }
}
