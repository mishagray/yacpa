//
//  RefreshableValue.swift
//  yacpa
//
//  Created by Michael Gray on 7/20/19.
//  Copyright © 2019 Michael Gray. All rights reserved.
//

import Combine
import Foundation

///
//  This is to simplify refreshing() async data, that may or may not change.
//  Its also clear, that you don't want ERRORS to clobber any good cached data, but we
//  sill want Error signals to help later add error handling.
//  (There is no error handling now).
final class RefreshableValue<Output, Failure: Error> {

    typealias ResultOutput = Result<Output, Failure>

    // sends a result for each refresh()
    var results: AnyPublisher<ResultOutput, Never> {
        lastResult.compactMap { $0 }
            .eraseToAnyPublisher()
    }

    // sends succesful values received.  A refresh() failure will NOT effect this publisher.
    var values: AnyPublisher<Output, Never> {
        lastResult
            .compactMap {
                switch $0 {
                case let .some(.success(output)):
                    return output

                default:
                    return nil
                }
            }
            .eraseToAnyPublisher()
    }

    // is nil, if the last refresh was succesful, otherwise has the error for the last refresh
    var errors: AnyPublisher<Failure?, Never> {
        lastResult
            .map {
                switch $0 {
                case let .some(.failure(error)):
                    print("error = \(error)")
                    return error

                default:
                    return nil
                }
            }
            .eraseToAnyPublisher()
    }

    // will return 'true' if a refresh operation is happening.
    let refreshCount = CurrentValueSubject<Int, Never>(0)

    // this is type erased into AnyProducer<Bool,None>

    typealias IS_REFRESHING_PRODUCER = Publishers.Map<CurrentValueSubject<Int, Never>, Bool>

    var isRefreshing: IS_REFRESHING_PRODUCER {
        return self.refreshCount.map { $0 > 0 }
    }

    // used to trigger updates on a refresh() request
    private let refreshSubject = PassthroughSubject<Void, Never>()

    // this will keep fetches going, even if nobody binds to the public vars
    let lastResult: BoundCurrentValue<ResultOutput?>


    // Takes an operation that shoud return a Publisher that is fetching the data, and returns a Result<Output, Failure>
    init<P: Publisher>(fetchResultOperation: @escaping () -> P) where P.Failure == Never, P.Output == Result<Output, Failure> {

        let fetches = refreshSubject
            .flatMap { [refreshCount = self.refreshCount] () -> P in
                refreshCount.value += 1
                print("\(Self.self) increased refreshCount.value =\(refreshCount.value)")
                let fetch = fetchResultOperation()
                print("\(Self.self) fetch")
                return fetch
            }
            .map { [refreshCount = self.refreshCount] result -> P.Output in
                refreshCount.value -= 1
                print("\(Self.self) result = \(result) \n decreased refreshCount.value =\(refreshCount.value)")
                return result
            }

        self.lastResult = BoundCurrentValue<ResultOutput?>(boundTo: fetches)
  }


    // This is useful if you want want to call a traditional 'callback' based network API request.
    // (AKA Alamofire).
    convenience init(asyncOperator: @escaping ((Result<Output, Failure>) -> Void) -> Void) {
        self.init {
            Future { promise in
                 asyncOperator(promise)
            }
        }
    }

    // Takes an operation that shoud return a Publisher of ANY Output/Failure. The Publisher is 'mapped' into a
    // a new publisher that converts it into a Result<Output,Failure> type.
    convenience init<P: Publisher>(failableOperation: @escaping () -> P) where P.Failure == Failure, P.Output == Output {
        self.init {
            failableOperation()
                .map { output -> Result<Output, Failure> in
                    .success(output)
                }
                .catch {
                    Just(Result<Output, Failure>.failure($0))
                }
        }
   }

    // triggers the refresh of data().
    // This casuses the refreshSubject to trigger again.
    // This is useful since it will prevent new API calls while some are in progress.
    // Otherwise, bad things can happen if two refresh()'s occur close to each other, but return out-of-order.
    func refresh() {
        print("\(Self.self) refresh()")
        refreshSubject.send(())
    }

}
