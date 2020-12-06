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

public enum StateMachineEror: Error {
  case duplicateTransition
}

public protocol StateMachineProtocol {
  associatedtype StateType: StateProtocol
  associatedtype EventType: EventProtocol

  var state: CurrentValueSubject<StateType, Never> { get }
  var event: PassthroughSubject<EventType, Never> { get }
  var reset: PassthroughSubject<Void, Never> { get }
  var willChangeState: PassthroughSubject<StateMachineTransition<EventType, StateType>, Never> { get }
  var didChangeState: PassthroughSubject<StateMachineTransition<EventType, StateType>, Never> { get }

  func append(transition: StateMachineTransition<EventType, StateType>) throws
}

public class StateMachine<EventType: EventProtocol, StateType: StateProtocol>: StateMachineProtocol, Loggable {
  internal let transitionQueue = OperationQueue()
  private var disposeBag = [AnyCancellable]()
  private var transitions = [EventType: [StateMachineTransition<EventType, StateType>]]()

  public var isLoggingEnabled = false {
    didSet {
      isLoggingEnabledUpdated(with: isLoggingEnabled)
    }
  }

  private let initialState: StateType
  public var state: CurrentValueSubject<StateType, Never>
  public var event = PassthroughSubject<EventType, Never>()
  public var reset = PassthroughSubject<Void, Never>()
  public var willChangeState = PassthroughSubject<StateMachineTransition<EventType, StateType>, Never>()
  public var didChangeState = PassthroughSubject<StateMachineTransition<EventType, StateType>, Never>()

  public required init(with state: StateType) {
    self.state = CurrentValueSubject(state)
    initialState = state

    setupLogger()
    
    setupEventSubject()
    setupResetSubject()
  }
}

private extension StateMachine {
  func setupLogger() {
    Logger.sharedInstance.setupLogger(logger: osLogger())
  }

  func isLoggingEnabledUpdated(with value: Bool) {
    if value {
      allowLogging()
    } else {
      disableLogging()
    }
  }
}

public extension StateMachine {
  func append(transition: StateMachineTransition<EventType, StateType>) throws {
    if let transitionsByEvent = transitions[transition.event] {
      guard transitionsByEvent.filter({ $0.from == transition.from }).isEmpty else {
        logFault(
          "Failed to appended \(transition.from) -> \(transition.to) with event \(transition.event)"
        )
        throw StateMachineEror.duplicateTransition
      }
      transitions[transition.event]?.append(transition)
    } else {
      transitions[transition.event] = [transition]
    }
  }
}

public extension StateMachine {
  func append(transitions: [StateMachineTransition<EventType, StateType>]) throws {
    try transitions.forEach { transition in
      try append(transition: transition)
    }
  }
}

private extension StateMachine {
  func setupEventSubject() {
    Publishers
      .CombineLatest(event, state)
      .sink(receiveValue: { [weak self] event, currentState in
        guard
          let self = self,
          let transitions = self.transitions[event],
          transitions.filter({ $0.from == currentState }).count == 1,
          let transition = transitions.first(where: { $0.from == currentState })
        else { return }

        let transiotion = BlockOperation {
          self.perform(transition: transition)
        }
        self.transitionQueue.addOperation(transiotion)
      })
      .store(in: &disposeBag)
  }

  func setupResetSubject() {
    reset
      .sink { [weak self] _ in
        guard let self = self else { return }
        self.log(level: .info, "Performing RESET to \(self.initialState)")
        self.state.send(self.initialState)
      }
      .store(in: &disposeBag)
  }
}

private extension StateMachine {
  func perform(transition: StateMachineTransition<EventType, StateType>) {
    willChangeState.send(transition)
    log(
      level: .info,
      "Performing transition \(transition.from) -> \(transition.to) with event \(transition.event)"
    )
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
    from.map {
      Self(
        event: event,
        from: $0,
        to: to
      )
    }
  }
}
