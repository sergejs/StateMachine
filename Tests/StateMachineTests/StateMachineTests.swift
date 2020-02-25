import XCTest
@testable import StateMachine

enum TestEvents: EventProtocol {
  case event1, event2
}

enum TestStates: StateProtocol {
  case initial, step1, step2, step1Alt, finish
}

// Just few common tests
final class StateMachineTests: XCTestCase {
  // Short Initial -> (Event1) -> Finish
  func testShort() {
    let stateMachine = StateMachine<TestEvents, TestStates>(with: .initial)
    let transition = StateMachineTransition<TestEvents, TestStates>(event: .event1, from: .initial, to: .finish)
    stateMachine.append(transition: transition)
    XCTAssertEqual(stateMachine.state.value, .initial)
    stateMachine.event.send(.event1)
    XCTAssertEqual(stateMachine.state.value, .finish)
  }

  // Long Initial -> (Event1) -> Step1 -> (Event2) -> Finish
  func testLong() {
    let stateMachine = StateMachine<TestEvents, TestStates>(with: .initial)
    XCTAssertEqual(stateMachine.state.value, .initial)

    var transition = StateMachineTransition<TestEvents, TestStates>(event: .event1, from: .initial, to: .step1)
    stateMachine.append(transition: transition)
    transition = StateMachineTransition<TestEvents, TestStates>(event: .event2, from: .step1, to: .finish)
    stateMachine.append(transition: transition)
    XCTAssertEqual(stateMachine.state.value, .initial)
    stateMachine.event.send(.event1)
    XCTAssertEqual(stateMachine.state.value, .step1)
    stateMachine.event.send(.event2)
    XCTAssertEqual(stateMachine.state.value, .finish)
  }

  static var allTests = [
    ("testShort", testShort),
  ]
}
