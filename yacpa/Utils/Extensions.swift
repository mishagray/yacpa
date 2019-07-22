//
//  htmlDecode.swift
//  yacpa
//
//  Created by Michael Gray on 7/21/19.
//  Copyright © 2019 Michael Gray. All rights reserved.
//

import Combine
import Foundation

extension String {

    // decodes HTML into Strings.
    // used to decode CoinbaseAPI's currency symbols
    var htmlDecoded: String {
        let decoded = try? NSAttributedString(
            data: Data(utf8),
            options: [.documentType: NSAttributedString.DocumentType.html,
                      .characterEncoding: String.Encoding.utf8.rawValue],
            documentAttributes: nil).string

        return decoded ?? self
    }
}

extension Publisher {

    /// Non Type-Erased Result of Publisher.mapToResults()
    ///
    /// type erases to  AnyProducer<Result<Output,Failure> , Never>
    typealias MapToResultsProducer = Publishers.Catch<Publishers.Map<Self, Result<Self.Output, Self.Failure>>,
                                                      Just<Result<Self.Output, Self.Failure>>>

    /// Transforms a producer into a producer or results.  Errors are mapped to .failure(error, values are mapped to .success(value)
    ///
    /// `mapToResults` maps Values to Result.success(t).  maps Errors to Result.failure(error).
    ///
    /// that produces elements of that type.
    /// - Returns: A new publisher equivilant to AnyProducer<Result<Output,Failure> , Never>
    func mapToResults() -> MapToResultsProducer {
        return self.map {
            Result.success($0)
        }
        .catch {
            Just(Result.failure($0))
        }
    }
}


extension Publisher {

    /// Non Type-Erased Result of Publisher.mapErrorsToValues()
    ///
    /// type erases to AnyProducer<Output, Never>
    typealias MAP_ERRORS_TO_VALUES_RESULT = Publishers.Catch<Self, AnyPublisher<Self.Output, Never>>

    /// will map optionally map any errors to values.
    ///
    /// that produces elements of that type.
    /// - Returns: A new publisher equivilant to AnyProducer<Output, Never>
    func mapErrorsToValues(_ mapping: @escaping (Failure) -> Output?) -> MAP_ERRORS_TO_VALUES_RESULT {
        return self.catch { error -> AnyPublisher<Output, Never> in
            if let value = mapping(error) {
                return Just(value).eraseToAnyPublisher()
            } else {
                return Empty<Output, Never>().eraseToAnyPublisher()
            }
        }
    }


    /// Non Type-Erased Result of Publisher.ignoreErrors()
    ///
    /// type erases to AnyProducer<Output, Never>
    typealias IGNORE_ERRORS_RESULT_TYPE = Publishers.Catch<Self, Empty<Self.Output, Never>>


    /// will convert any Publisher into a Publisher that returns no Failures.
    ///
    /// - Returns: A new publisher equivilant to AnyProducer<Output, Never>
    func ignoreErrors() -> IGNORE_ERRORS_RESULT_TYPE {
        return self.catch { _ in Empty<Output, Never>() }
    }
}

protocol OptionalType: ExpressibleByNilLiteral {
    associatedtype Wrapped

    var unwrapped: Wrapped? { get }

    init(_ some: Wrapped)
}

extension Optional: OptionalType {
    var unwrapped: Wrapped? {
        return self
    }
}

// similar to CurrentValueSubject, but it will let you 'bind' any changes to another publisher.
// useful if you want to convert a generic Publisher into a CurrentValueSubject

// DOES THIS LEAK?  It may have a retain loop...
class BoundCurrentValue<Output>: Publisher {

    typealias Failure = Never

    let currentValue: CurrentValueSubject<Output, Never>

    let cancellable: AnyCancellable

    var value: Output {
        get {
            return currentValue.value
        }
        set(newValue) {
            currentValue.send(newValue)
        }
    }
    deinit {
        print("\(Self.self).deinit")
    }

    init<P>(initialValue: P.Output, boundTo publisher: P) where P: Publisher, P.Output == Output, P.Failure == Never {
        let innerCurrentValue = CurrentValueSubject<Output, Failure>(initialValue)
        self.cancellable = publisher.print("\(Self.self).boundto").sink(
            receiveCompletion: { innerCurrentValue.send(completion: $0) },
            receiveValue: { innerCurrentValue.send($0) }
        )
        self.currentValue = innerCurrentValue
    }

    // if Output is an Optional type, you can still 'bind' to a non-optional Publisher.
    init<P>(initialValue: Output = nil, boundTo publisher: P) where P: Publisher,
        Output: OptionalType, P.Output == Output.Wrapped, P.Failure == Never {

        let innerCurrentValue = CurrentValueSubject<Output, Failure>(initialValue)
        self.cancellable = publisher.print("\(Self.self).boundto").sink(
            receiveCompletion: { innerCurrentValue.send(completion: $0) },
            receiveValue: { innerCurrentValue.send(Output($0)) }
        )
        self.currentValue = innerCurrentValue
    }


    func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        currentValue.receive(subscriber: subscriber)
    }

}
