//
//  StateMachine.swift
//  StateMachine
//
//  Created by Sergejs Smirnovs on 05/03/2020.
//  Copyright © 2020 Sergejs Smirnovs. All rights reserved.
//

import Combine
import Foundation
import SwiftLogger

public protocol EventProtocol: Hashable {}
public protocol StateProtocol: Hashable {}

public protocol StateMachineProtocol {
  associatedtype StateType: StateProtocol
  associatedtype EventType: EventProtocol

  var state: CurrentValueSubject<StateType, Never> { get }
  var event: PassthroughSubject<EventType, Never> { get }
  var reset: PassthroughSubject<Void, Never> { get }
  var willChangeState: PassthroughSubject<StateMachineTransition<EventType, StateType>, Never> { get }
  var didChangeState: PassthroughSubject<StateMachineTransition<EventType, StateType>, Never> { get }

  func append(transition: StateMachineTransition<EventType, StateType>)
}

public class StateMachine<EventType: EventProtocol, StateType: StateProtocol>: StateMachineProtocol, Loggable {
  let transitionQueue = OperationQueue()
  private var disposeBag = [AnyCancellable]()
  private var transitions = [EventType: [StateMachineTransition<EventType, StateType>]]()
  public var isLoggingEnabled = false {
    didSet {
      if isLoggingEnabled {
        allowLogging()
      } else {
        disableLogging()
      }
    }
  }

  public let initialState: StateType
  public var state: CurrentValueSubject<StateType, Never>
  public var event: PassthroughSubject<EventType, Never>
  public var reset: PassthroughSubject<Void, Never>
  public var willChangeState: PassthroughSubject<StateMachineTransition<EventType, StateType>, Never>
  public var didChangeState: PassthroughSubject<StateMachineTransition<EventType, StateType>, Never>

  public
  required init(with state: StateType) {
    self.state = CurrentValueSubject(state)
    event = PassthroughSubject()
    reset = PassthroughSubject()
    willChangeState = PassthroughSubject()
    didChangeState = PassthroughSubject()
    initialState = state

    Logger.sharedInstance.setupLogger(logger: osLogger())

    setupEventSubject()
    setupResetSubject()
  }
}

public extension StateMachine {
  func append(transition: StateMachineTransition<EventType, StateType>) {
    if let transitionsByEvent = transitions[transition.event] {
      guard transitionsByEvent.filter({ $0.from == transition.from }).isEmpty else {
        log(level: .fault, "Failed to appended \(transition.from) -> \(transition.to) with event \(transition.event)")
        return assertionFailure("Transition \(transition.from) & \(transition.event) already exists!")
      }
      transitions[transition.event]?.append(transition)
    } else {
      transitions[transition.event] = [transition]
    }
  }
}

public extension StateMachine {
  func append(transitions: [StateMachineTransition<EventType, StateType>]) {
    transitions.forEach { transition in
      append(transition: transition)
    }
  }
}

private extension StateMachine {
  func setupEventSubject() {
    Publishers
      .CombineLatest(event, state)
      .sink(receiveValue: { [weak self] event, currentState in
        guard
          let this = self,
          let transitions = this.transitions[event],
          transitions.filter({ $0.from == currentState }).count == 1,
          let transition = transitions.first(where: { $0.from == currentState })
        else { return }

        let transiotion = BlockOperation {
          this.perform(transition: transition)
        }
        this.transitionQueue.addOperation(transiotion)
      })
      .store(in: &disposeBag)
  }

  func setupResetSubject() {
    reset
      .sink { [weak self] _ in
        guard let this = self else { return }
        this.log(level: .info, "Performing RESET to \(this.initialState)")
        this.state.send(this.initialState)
      }
      .store(in: &disposeBag)
  }
}

private extension StateMachine {
  func perform(transition: StateMachineTransition<EventType, StateType>) {
    willChangeState.send(transition)
    log(level: .info, "Performing transition \(transition.from) -> \(transition.to) with event \(transition.event)")
    state.send(transition.to)
    didChangeState.send(transition)
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

  public static func make(
    event: EventType,
    from: [StateType],
    to: StateType
  ) -> [Self] {
    from.map { Self(event: event, from: $0, to: to) }
  }
}
