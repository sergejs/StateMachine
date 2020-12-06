//
//  StateMachineTests.swift
//  StateMachineTests
//
//  Created by Sergejs Smirnovs on 05/03/2020.
//  Copyright © 2020 Sergejs Smirnovs. All rights reserved.
//

@testable import StateMachine
import XCTest

enum TestEvents: EventProtocol {
  case event1, event2, eventA, eventFinish
}

enum TestStates: StateProtocol {
  case initial, step1, step2, step2Alt, finish
}

typealias TransitionType = StateMachineTransition<TestEvents, TestStates>

final class StateMachineTests: XCTestCase {
  // Short Initial -> (Event1) -> Finish
  func testShort() {
    let stateMachine = StateMachine<TestEvents, TestStates>(with: .initial)
    stateMachine.isLoggingEnabled = true
    let transition = TransitionType(event: .event1, from: .initial, to: .finish)
    try? stateMachine.append(transition: transition)
    stateMachine.transitionQueue.waitUntilAllOperationsAreFinished()
    XCTAssertEqual(stateMachine.state.value, .initial)
    stateMachine.event.send(.event1)
    stateMachine.transitionQueue.waitUntilAllOperationsAreFinished()
    XCTAssertEqual(stateMachine.state.value, .finish)
  }

  // Long Initial -> (Event1) -> Step1 -> (Event2) -> Finish
  func testLong() {
    let stateMachine = StateMachine<TestEvents, TestStates>(with: .initial)
    stateMachine.isLoggingEnabled = true
    XCTAssertEqual(stateMachine.state.value, .initial)

    var transition = TransitionType(event: .event1, from: .initial, to: .step1)
    try? stateMachine.append(transition: transition)
    transition = TransitionType(event: .event2, from: .step1, to: .finish)
    try? stateMachine.append(transition: transition)
    stateMachine.transitionQueue.waitUntilAllOperationsAreFinished()
    XCTAssertEqual(stateMachine.state.value, .initial)
    stateMachine.event.send(.event1)
    stateMachine.transitionQueue.waitUntilAllOperationsAreFinished()
    XCTAssertEqual(stateMachine.state.value, .step1)
    stateMachine.event.send(.event2)
    stateMachine.transitionQueue.waitUntilAllOperationsAreFinished()
    XCTAssertEqual(stateMachine.state.value, .finish)
  }

  // Long Initial -> (Event1) -> Step1 -> (Event2) -> Finish
  func testLongAlternative() {
    let stateMachine = StateMachine<TestEvents, TestStates>(with: .initial)
    stateMachine.isLoggingEnabled = true
    XCTAssertEqual(stateMachine.state.value, .initial)

    try? stateMachine.append(
      transitions: [
        TransitionType(event: .event1, from: .initial, to: .step1),
        TransitionType(event: .event2, from: .step1, to: .step2),
        TransitionType(event: .eventA, from: .step1, to: .step2Alt),
        TransitionType(event: .eventFinish, from: .step2, to: .finish),
        TransitionType(event: .eventFinish, from: .step2Alt, to: .finish),
      ]
    )

    // First pass
    stateMachine.transitionQueue.waitUntilAllOperationsAreFinished()
    XCTAssertEqual(stateMachine.state.value, .initial)

    stateMachine.event.send(.event1)
    stateMachine.transitionQueue.waitUntilAllOperationsAreFinished()
    XCTAssertEqual(stateMachine.state.value, .step1)

    stateMachine.event.send(.event2)
    stateMachine.transitionQueue.waitUntilAllOperationsAreFinished()
    XCTAssertEqual(stateMachine.state.value, .step2)

    stateMachine.event.send(.eventFinish)
    stateMachine.transitionQueue.waitUntilAllOperationsAreFinished()
    XCTAssertEqual(stateMachine.state.value, .finish)

    // Alternative pass
    stateMachine.reset.send()
    stateMachine.transitionQueue.waitUntilAllOperationsAreFinished()
    XCTAssertEqual(stateMachine.state.value, .initial)

    stateMachine.event.send(.event1)
    stateMachine.transitionQueue.waitUntilAllOperationsAreFinished()
    XCTAssertEqual(stateMachine.state.value, .step1)

    stateMachine.event.send(.eventA)
    stateMachine.transitionQueue.waitUntilAllOperationsAreFinished()
    XCTAssertEqual(stateMachine.state.value, .step2Alt)

    stateMachine.event.send(.eventFinish)
    stateMachine.transitionQueue.waitUntilAllOperationsAreFinished()
    XCTAssertEqual(stateMachine.state.value, .finish)
  }

  // Should throw when adding same transition
  func testFailOnDuplicatieTransition() {
    let stateMachine = StateMachine<TestEvents, TestStates>(with: .initial)
    stateMachine.isLoggingEnabled = true
    XCTAssertEqual(stateMachine.state.value, .initial)

    var transition = TransitionType(event: .event1, from: .initial, to: .step1)
    try? stateMachine.append(transition: transition)
    transition = TransitionType(event: .event1, from: .initial, to: .step1)
    XCTAssertThrowsError(try stateMachine.append(transition: transition))
  }


  static var allTests = [
    ("testShort", testShort),
    ("testLong", testLong),
    ("testFailOnDuplicatieTransition", testFailOnDuplicatieTransition),
    ("testLongAlternative", testLongAlternative),
  ]
}
