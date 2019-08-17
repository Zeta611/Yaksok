//
//  Promise.swift
//  Yaksok
//
//  Created by Jaeho Lee on 2019/08/17.
//  Copyright © 2019 Jay Lee. All rights reserved.
//

import Foundation

class Promise<Value> {
  private var state: State = .pending
  private var queue: DispatchQueue = .main

  fileprivate var promisedCallbacks: [(Result<Value, Error>) -> Void] = []
  private var doneCallbacks: [(Value) -> Void] = []
  private var catchCallbacks: [(Error) -> Void] = []


  /// Initialize a new promise that can be fulfilled or rejected with provided
  /// `fulfill` and `reject` methods.
  init(
    on queue: DispatchQueue = .main,
    block: (_ resolve: @escaping (Result<Value, Error>) -> ()) -> Void)
  {
    self.queue = queue
    block(resolve)
  }


  convenience init(value: Value) {
    self.init { resolve in resolve(.success(value)) }
  }

  
  convenience init(error: Error) {
    self.init { resolve in resolve(.failure(error)) }
  }


  /// The provided block executes when the promise is fulfilled, and should be
  /// further chained.
  @discardableResult
  func done(block: @escaping (Value) -> Void) -> Self {
    doneCallbacks.append(block)
    runBlocksIfResolved()
    return self
  }


  /// The provided block executes when the promise is rejected, and should be
  /// further chained.
  @discardableResult
  func `catch`(block: @escaping (Error) -> Void) -> Self {
    catchCallbacks.append(block)
    runBlocksIfResolved()
    return self
  }


  func map<Other>(block: @escaping (Value) throws -> Other) -> Promise<Other> {
    return Promise<Other> { resolve in
      promisedCallbacks.append { result in
        switch result {
        case .success(let value):
          do {
            resolve(.success(try block(value)))
          } catch {
            resolve(.failure(error))
          }

        case .failure(let error):
          resolve(.failure(error))
        }
      }
      runBlocksIfResolved()
    }
  }


  func flatMap<Other>(block: @escaping (Value) throws -> Promise<Other>) -> Promise<Other> {
    return Promise<Other> { resolve in
      promisedCallbacks.append { result in
        switch result {
        case .success(let value):
          do {
            try block(value).promisedCallbacks.append { resolve($0) }
          } catch {
            resolve(.failure(error))
          }

        case .failure(let error):
          resolve(.failure(error))
        }
      }
      runBlocksIfResolved()
    }
  }


  private func resolve(_ result: Result<Value, Error>) {
    guard case .pending = state else { return }
    state = .resolved(result)
    runBlocksIfResolved()
  }


  private func runBlocksIfResolved() {
    guard case let .resolved(result) = state else { return }
    queue.async {
      self.promisedCallbacks.forEach { $0(result) }
      self.promisedCallbacks.removeAll()

      switch result {
      case .success(let value):
        self.doneCallbacks.forEach { $0(value) }
        self.doneCallbacks.removeAll()

      case .failure(let error):
        self.catchCallbacks.forEach { $0(error) }
        self.catchCallbacks.removeAll()
      }
    }
  }


  enum State {
    case pending
    case resolved(Result<Value, Error>)
  }
}
