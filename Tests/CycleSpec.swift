//
//  CycleSpec.swift
//  Cycle
//
//  Created by Brian Semiglia on 04/10/16.
//  Copyright © 2017 BrianSemiglia. All rights reserved.
//

import Quick
import Nimble
@testable import Cycle

class CycleSpec: QuickSpec {

    override func spec() {

        describe("CycleSpec") {
            it("works") {
                expect(Cycle.name) == "Cycle"
            }
        }

    }

}
