# StateMachine
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fsergejs%2FStateMachine%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/sergejs/StateMachine)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fsergejs%2FStateMachine%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/sergejs/StateMachine)

Package containing easy implamentation of Finite State Machine using Combine

To start using, all you need is to defeine enums with States and Events, and define Transitions. 

## TODO:

[  ] Improved logging control

## Example usage

    enum TestEvents: EventProtocol {
      case event1, event2
    }
    
    enum TestStates: StateProtocol {
      case initial, step1, step2, step1Alt, finish
    }
    
    let stateMachine = StateMachine<TestEvents, TestStates>(with: .initial)
    let transition = StateMachineTransition<TestEvents, TestStates>(event: .event1, from: .initial, to: .finish)
    try? stateMachine.append(transition: transition)
    stateMachine.transitionQueue.waitUntilAllOperationsAreFinished()
    XCTAssertEqual(stateMachine.state.value, .initial)
    
    stateMachine.event.send(.event1)
    stateMachine.transitionQueue.waitUntilAllOperationsAreFinished()
    XCTAssertEqual(stateMachine.state.value, .finish)


