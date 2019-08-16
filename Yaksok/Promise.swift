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


  /// The provided block executes when the promise is fulfilled, but cannot be
  /// further chained.
  @discardableResult
  func done(block: @escaping (Value) -> Void) -> Promise<Void> {
    doneCallbacks.append(block)
    runBlocksIfResolved()
    return Promise<Void> { $0(.success(())) }
  }


  /// The provided block executes when the promise is rejected, and cannot be
  /// further chained.
  @discardableResult
  func `catch`(block: @escaping (Error) -> Void) -> Promise<Void> {
    catchCallbacks.append(block)
    runBlocksIfResolved()
    // Should be changed
    return Promise<Void> { $0(.success(())) }
  }


  func map<Other>(block: @escaping (Value) throws -> Other) -> Promise<Other> {
    return Promise<Other> { resolve in
      promisedCallbacks.append { result in
        switch result {
        case .success(let value):
          do {
            let other = try block(value)
            resolve(.success(other))
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
            let promise = try block(value)
            promise.promisedCallbacks.append { result in
              switch result {
              case .success(let other):
                resolve(.success(other))
              case .failure(let error):
                resolve(.failure(error))
              }
            }
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

      switch result {
      case .success(let value):
        self.doneCallbacks.forEach { $0(value) }
      case .failure(let error):
        self.catchCallbacks.forEach { $0(error) }
      }

      self.promisedCallbacks.removeAll()
      self.doneCallbacks.removeAll()
      self.catchCallbacks.removeAll()
    }
  }


  enum State {
    case pending
    case resolved(Result<Value, Error>)
  }
}
