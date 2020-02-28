import Foundation
import CoreBluetooth
import Combine

public protocol EventProtocol: Hashable {}
public protocol StateProtocol: Hashable {}

public protocol StateMachineProtocol {
  associatedtype StateType: StateProtocol
  associatedtype EventType: EventProtocol
  typealias ChangeStatePassthroughSubjectType = PassthroughSubject<StateMachine<EventType, StateType>.ChangeStateType, Never>
  
  var state: CurrentValueSubject<StateType, Never> { get }
  var event: PassthroughSubject<EventType, Never> { get }
  var reset: PassthroughSubject<Void, Never> { get }
  var willChangeState: ChangeStatePassthroughSubjectType { get }
  var didChangeState: ChangeStatePassthroughSubjectType { get }
  
  func append(transition: StateMachineTransition<EventType, StateType>)
}

public class StateMachine<EventType: EventProtocol, StateType: StateProtocol>: StateMachineProtocol {
  private var disposeBag = [AnyCancellable]()
  private var transitions = [EventType: [StateMachineTransition<EventType, StateType>]]()
  
  public let initialState: StateType
  public var state: CurrentValueSubject<StateType, Never>
  public var event: PassthroughSubject<EventType, Never>
  public var reset: PassthroughSubject<Void, Never>
  public var willChangeState: PassthroughSubject<ChangeStateType, Never>
  public var didChangeState: PassthroughSubject<ChangeStateType, Never>
  
  public required init(with state: StateType) {
    self.state = CurrentValueSubject(state)
    event = PassthroughSubject()
    reset = PassthroughSubject()
    willChangeState = PassthroughSubject()
    didChangeState = PassthroughSubject()
    initialState = state
    
    setupEventSubject()
    setupResetSubject()
  }
}

public
extension StateMachine {
  func append(transition: StateMachineTransition<EventType, StateType>) {
    if let transitionsByEvent = transitions[transition.event] {
      guard transitionsByEvent.filter ({ $0.from == transition.from }).isEmpty else {
        log("Failed to appended \(transition.from) -> \(transition.to) with event \(transition.event)")
        return assertionFailure("Transition \(transition.from) & \(transition.event) already exists!")
      }
      transitions[transition.event]?.append(transition)
    } else {
      transitions[transition.event] = [transition]
    }
    log("Appended \(transition.from) -> \(transition.to) with event \(transition.event)")
  }
}

private
extension StateMachine {
  func setupEventSubject() {
    let eventCancelable = Publishers
      .CombineLatest(event, state)
      .sink (receiveValue: { [weak self] (event, currentState) in
        guard
          let this = self,
          let transitions = this.transitions[event],
          transitions.filter ({ $0.from == currentState }).count == 1,
          let transition = transitions.filter ({ $0.from == currentState }).first
          else { return }
        
        let change = ChangeStateType(stateMachine: this, transition: transition)
        Self.performTransition(changeState: change)
      })
    
    disposeBag.append(eventCancelable)
  }
  
  func setupResetSubject() {
    let resetCancelable = reset.sink { [weak self] _ in
      guard let this = self else { return }
      
      log("Performing RESET to \(this.initialState)")
      this.state.send(this.initialState)
    }
    
    disposeBag.append(resetCancelable)
  }
}

private
extension StateMachine {
  static func performTransition(changeState: ChangeStateType) {
    let stateMachine = changeState.stateMachine
    let transition = changeState.transition
    stateMachine.willChangeState.send(changeState)
    log("Performing transition \(transition.from) -> \(transition.to) with event \(transition.event)")
    stateMachine.state.send(transition.to)
    stateMachine.didChangeState.send(changeState)
  }
}

public
extension StateMachine {
  struct ChangeStateType {
    public let stateMachine: StateMachine
    public let transition: StateMachineTransition<EventType, StateType>
  }
}


private
extension StateMachine {
  func log(value: String) {
//    print(value)
  }
}
public struct StateMachineTransition<EventType: Hashable, StateType: Hashable> {
  public let event: EventType
  public let from: StateType
  public let to: StateType
  
  public init(
    event: EventType,
    from: StateType,
    to: StateType
  ) {
    self.event = event
    self.from = from
    self.to = to
  }
}
