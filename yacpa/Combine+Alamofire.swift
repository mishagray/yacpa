//
//  Combine+Alamofire.swift
//  yacpa
//
//  Created by Michael Gray on 7/19/19.
//  Copyright © 2019 Michael Gray. All rights reserved.
//

import Alamofire
import Combine
import Foundation


enum PublisherEvents<P: Publisher> {
    case subscription(Subscription)
    case output(P.Output)
    case completion(Subscribers.Completion<P.Failure>)
    case cancel
    case request(Subscribers.Demand)
}


protocol FutureProtocol: Publisher {

    var inner: Future<Output, Failure> { get }

}

extension Future: FutureProtocol {

    var inner: Future<Output, Failure> {
        return self
    }
}

struct MappedFuture<Output, Failure: Error>: FutureProtocol, Cancellable {

    let cancelable: AnyCancellable
    let upstream: Future<Output, Failure>

    func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        upstream.receive(subscriber: subscriber)
    }

    init<F: FutureProtocol>(_ cancelable: AnyCancellable, _ upstream: F) where Failure == F.Failure, Output == F.Output {
        self.cancelable = cancelable
        self.upstream = upstream.inner
    }
    init<U: FutureProtocol>(_ upstream: U, _ mapResult: @escaping (Result<U.Output, U.Failure>) -> Result<Output, Failure>) {
        self = upstream.mapResult(mapResult)
    }

    var inner: Future<Output, Failure> {
        return self.upstream
    }

    func cancel() {
        cancelable.cancel()
    }
}

typealias AnyFuture = MappedFuture


extension FutureProtocol {

    func mapResult<T, E: Error>(_ map: @escaping (Result<Output, Failure>) -> Result<T, E>) -> MappedFuture<T, E> {
        var innerCancelable: AnyCancellable?
        let upstream = Future<T, E> { promise in

            var lastValue: Output?

            innerCancelable = self.sink(
                receiveCompletion: { completion in

                    switch completion {
                    case .finished:
                        if let lastValue = lastValue {
                            promise(map(.success(lastValue)))
                        } else {
                            fatalError("Future completed without value or error")
                        }

                    case .failure(let error):
                        promise(map(.failure(error)))
                    }

                }, receiveValue: {
                lastValue = $0
                })
        }
        guard let cancellable = innerCancelable else {
            fatalError("error initializing ChildFuture - no cancelable")
        }
        return MappedFuture(cancellable, upstream)
    }
    func mapSuccess<T>(_ map: @escaping (Output) -> T) -> MappedFuture<T, Failure> {
        return self.mapResult { result -> Result<T, Failure> in
            switch result {
            case .success(let output):
                return .success(map(output))

            case .failure(let error):
                return .failure(error)
            }
        }
    }
    func mapFailure<E: Error>(_ map: @escaping (Failure) -> E) -> MappedFuture<Output, E> {
        return self.mapResult { result -> Result<Output, E> in
            switch result {
            case .success(let output):
                return .success(output)

            case .failure(let error):
                return .failure(map(error))
            }
        }
    }
}


extension Publisher {


 }


extension Alamofire.Session {

    func fetchDecodable<U: URLRequestConvertible, T: Decodable> (url: U) -> Future<T, Error> {
        return Future { promise in
            self.request(url).responseDecodable { (response: DataResponse<T>) in
                promise(response.result)
            }
        }
    }
}


extension Alamofire.AF {

    static func fetchDecodable<U: URLRequestConvertible, T: Decodable> (url: U) -> Future<T, Error> {
        return Session.default.fetchDecodable(url: url)
    }
}
