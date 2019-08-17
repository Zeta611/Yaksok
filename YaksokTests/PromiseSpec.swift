//
//  PromiseSpec.swift
//  PromiseSpec
//
//  Created by Jaeho Lee on 2019/08/17.
//  Copyright © 2019 Jay Lee. All rights reserved.
//

import Nimble
import Quick
@testable import Yaksok

class PromiseSpec: QuickSpec {

  func wait(for timeInterval: TimeInterval = 0.1, body: @escaping () -> Void) {
    DispatchQueue.global(qos: .userInteractive)
      .asyncAfter(deadline: .now() + timeInterval, execute: body)
  }


  override func spec() {
    describe("Promise") {
      let string = "foo"

      context("when it is immediately fulfilled") {
        it("should immediately execute `achieved` block") {
          waitUntil(timeout: 1e-3) { done in
            Promise<String>(value: string * 2).done {
              expect($0).to(equal(string * 2))
              done()
            }
          }
        }
      }

      context("when it is immediately rejected") {
        it("should immediately execute `failed` block") {
          waitUntil(timeout: 1e-3) { done in
            Promise<Void>(error: TestError.always).catch {
              expect($0 as? TestError).to(equal(.always))
              done()
            }
          }
        }
      }

      context("when it is eventually fulfilled") {
        it("should eventually execute `achieved` block") {
          waitUntil { done in
            Promise<String> { resolve in
              self.wait { resolve(.success(string * 2)) }
            }
            .done {
              expect($0).to(equal(string * 2))
              done()
            }
          }
        }
      }

      context("when it is eventually rejected") {
        it("should eventually execute `failed` block") {
          waitUntil { done in
            Promise<Void> { resolve in
              self.wait { resolve(.failure(TestError.always)) }
            }
            .catch {
              expect($0 as? TestError).to(equal(.always))
              done()
            }
          }
        }
      }

      it("can be chained with `map`s") {
        waitUntil { done in
          Promise<String> { resolve in
            self.wait { resolve(.success(string * 2)) }
          }
          .map { $0 }
          .map { $0 * 2 }
          .map { $0 * 3 }
          .done {
            expect($0).to(equal(string * 12))
            done()
          }
        }
      }

      context("when it is rejected in a `map`-only chain") {
        context("if it is rejected in the last `map`") {
          it("should execute `failed` block") {
            waitUntil { done in
              Promise<String> { resolve in
                self.wait { resolve(.success(string * 2)) }
              }
              .map { $0 }
              .map { $0 * 2 }
              .map { _ in throw TestError.always }
              .catch {
                expect($0 as? TestError).to(equal(.always))
                done()
              }
            }
          }
        }

        context("if it is rejected in the middle `map`") {
          it("should execute `failed` block") {
            waitUntil { done in
              Promise<String> { resolve in
                self.wait { resolve(.success(string * 2)) }
              }
              .map { $0 }
              .map { _ in throw TestError.always }
              .map { $0 * 2 }
              .catch {
                expect($0 as? TestError).to(equal(.always))
                done()
              }
            }
          }
        }

        context("if it is rejected in the first `map`") {
          it("should execute `failed` block") {
            waitUntil { done in
              Promise<String> { resolve in
                self.wait { resolve(.success(string * 2)) }
              }
              .map { _ in throw TestError.always }
              .map { $0 }
              .map { $0 * 2 }
              .catch {
                expect($0 as? TestError).to(equal(.always))
                done()
              }
            }
          }
        }
      }

      it("can be chained with `flatMap`s") {
        waitUntil { done in
          Promise<String> { resolve in
            self.wait { resolve(.success(string * 2)) }
          }
          .flatMap { value in
            Promise<String> { resolve in
              self.wait { resolve(.success(value)) }
            }
          }
          .flatMap { value in
            Promise<String> { resolve in
              self.wait { resolve(.success(value * 2)) }
            }
          }
          .flatMap { value in
            Promise<String> { resolve in
              self.wait { resolve(.success(value * 3)) }
            }
          }
          .done {
            expect($0).to(equal(string * 12))
            done()
          }
        }
      }

      context("when it is rejected in a `flatMap`-only chain") {
        context("if it is rejected in the last `flatMap`") {
          it("should execute `failed` block") {
            waitUntil { done in
              Promise<String> { resolve in
                self.wait { resolve(.success(string * 2)) }
              }
              .flatMap { value in
                Promise<String> { resolve in
                  self.wait { resolve(.success(value)) }
                }
              }
              .flatMap { value in
                Promise<String> { resolve in
                  self.wait { resolve(.success(value * 2)) }
                }
              }
              .flatMap { _ in Promise<Void>(error: TestError.always) }
              .catch {
                expect($0 as? TestError).to(equal(.always))
                done()
              }
            }
          }
        }

        context("if it is rejected in the middle `flatMap`") {
          it("should execute `failed` block") {
            waitUntil { done in
              Promise<String> { resolve in
                self.wait { resolve(.success(string * 2)) }
              }
              .flatMap { value in
                Promise<String> { resolve in
                  self.wait { resolve(.success(value)) }
                }
              }
              .flatMap { _ in Promise<String>(error: TestError.always) }
              .flatMap { value in
                Promise<String> { resolve in
                  self.wait { resolve(.success(value * 2)) }
                }
              }
              .catch {
                expect($0 as? TestError).to(equal(.always))
                done()
              }
            }
          }
        }

        context("if it is rejected in the first `flatMap`") {
          it("should execute `failed` block") {
            waitUntil { done in
              Promise<String> { resolve in
                self.wait { resolve(.success(string * 2)) }
              }
              .flatMap { _ in Promise<String>(error: TestError.always) }
              .flatMap { value in
                Promise { resolve in
                  self.wait { resolve(.success(value)) }
                }
              }
              .flatMap { value in
                Promise<String> { resolve in
                  self.wait { resolve(.success(value * 2)) }
                }
              }
              .catch {
                expect($0 as? TestError).to(equal(.always))
                done()
              }
            }
          }
        }
      }

      it("can be chained with both `map`s and `flatMap`s") {
        waitUntil { done in
          Promise<String> { resolve in
            self.wait { resolve(.success(string * 2)) }
          }
          .flatMap { value in
            Promise<String> { resolve in
              self.wait { resolve(.success(value)) }
            }
          }
          .map { $0 * 2 }
          .flatMap { value in
            Promise<String> { resolve in
              self.wait { resolve(.success(value * 3)) }
            }
          }
          .map { $0 }
          .done {
            expect($0).to(equal(string * 12))
            done()
          }
        }
      }

      context("when it is rejected in a chain") {
        context("if it is rejected in the last `map`") {
          it("should execute `failed` block") {
            waitUntil { done in
              Promise<String> { resolve in
                self.wait { resolve(.success(string * 2)) }
              }
              .flatMap { value in
                Promise<String> { resolve in
                  self.wait { resolve(.success(value)) }
                }
              }
              .map { $0 * 2 }
              .flatMap { value in
                Promise<String> { resolve in
                  self.wait { resolve(.success(value * 3)) }
                }
              }
              .map { _ in throw TestError.always }
              .catch {
                expect($0 as? TestError).to(equal(.always))
                done()
              }
            }
          }
        }

        context("if it is rejected in the last `flatMap`") {
          it("should execute `failed` block") {
            waitUntil { done in
              Promise<String> { resolve in
                self.wait { resolve(.success(string * 2)) }
              }
              .map { $0 * 2 }
              .flatMap { value in
                Promise<String> { resolve in
                  self.wait { resolve(.success(value)) }
                }
              }
              .map { $0 }
              .flatMap { _ in Promise<Void>(error: TestError.always) }
              .catch {
                expect($0 as? TestError).to(equal(.always))
                done()
              }
            }
          }
        }

        context("if it is rejected in the middle `map`") {
          it("should execute `failed` block") {
            waitUntil { done in
              Promise<String> { resolve in
                self.wait { resolve(.success(string * 2)) }
              }
              .map { $0 * 2 }
              .flatMap { value in
                Promise<String> { resolve in
                  self.wait { resolve(.success(value)) }
                }
              }
              .map { _ in throw TestError.always }
              .flatMap { value in
                Promise<String> { resolve in
                  self.wait { resolve(.success(value * 3)) }
                }
              }
              .catch {
                expect($0 as? TestError).to(equal(.always))
                done()
              }
            }
          }
        }

        context("if it is rejected in the middle `flatMap`") {
          it("should execute `failed` block") {
            waitUntil { done in
              Promise<String> { resolve in
                self.wait { resolve(.success(string * 2)) }
              }
              .map { $0 * 2 }
              .flatMap { _ in Promise<String>(error: TestError.always) }
              .map { $0 }
              .flatMap { value in
                Promise<String> { resolve in
                  self.wait { resolve(.success(value * 3)) }
                }
              }
              .catch {
                expect($0 as? TestError).to(equal(.always))
                done()
              }
            }
          }
        }

        context("if it is rejected in the fist `map`") {
          it("should execute `failed` block") {
            waitUntil { done in
              Promise<String> { resolve in
                self.wait { resolve(.success(string * 2)) }
              }
              .map { _ in throw TestError.always }
              .flatMap { value in
                Promise<String> { resolve in
                  self.wait { resolve(.success(value)) }
                }
              }
              .map { $0 }
              .flatMap { value in
                Promise<String> { resolve in
                  self.wait { resolve(.success(value * 3)) }
                }
              }
              .catch {
                expect($0 as? TestError).to(equal(.always))
                done()
              }
            }
          }
        }

        context("if it is rejected in the first `flatMap`") { 
          it("should execute `failed` block") {
            waitUntil { done in
              Promise<String> { resolve in
                self.wait { resolve(.success(string * 2)) }
              }
              .flatMap { _ in Promise<String>(error: TestError.always) }
              .map { $0 * 2 }
              .flatMap { value in
                Promise<String> { resolve in
                  self.wait { resolve(.success(value * 3)) }
                }
              }
              .map { $0 }
              .catch {
                expect($0 as? TestError).to(equal(.always))
                done()
              }
            }
          }
        }
      }

      context("when used with network requests") {
        it("should handle login requests") {
          let username = "Promise"
          let password = "yaksok"
          waitUntil(timeout: 5) { done in
            User.login(username: username, password: password)
              .done {
                expect($0).to(equal(User(username: username, password: password)))
                done()
              }
              .catch { _ in
                expect { fatalError() }.toNot(throwAssertion())
              }
          }

          waitUntil(timeout: 5) { done in
            User.login(username: username, password: "foo")
              .done { _ in
                expect { fatalError() }.toNot(throwAssertion())
              }
              .catch {
                expect($0 as? User.UserError).to(equal(.passwordError))
                done()
              }
          }
        }
      }
    }
  }

  enum TestError: Error { case always, never }
}
