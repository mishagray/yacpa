//
//  RefreshableValue.swift
//  yacpa
//
//  Created by Michael Gray on 7/20/19.
//  Copyright © 2019 Michael Gray. All rights reserved.
//

import Combine
import Foundation


struct RefreshableValue<Output, Failure: Error> {

    // sends succesful values received.  A refresh() failure will NOT effect this publisher.
    let values: AnyPublisher<Output, Never>

    // is nil, if the last refresh was succesful, otherwise has the error for the fetch
    let errors: AnyPublisher<Failure?, Never>

    // sends a result for each refresh()
    let results: AnyPublisher<Result<Output, Failure>, Never>

    // used to trigger updates on a refresh() request
    private let priceFetcherRefresh: PassthroughSubject<Void, Never>


    init<P: Publisher>(_ fetchOperation: @escaping () -> P) where P.Failure == Failure, P.Output == Output {

        self.priceFetcherRefresh = PassthroughSubject<Void, Never>()

        let innerResults = self.priceFetcherRefresh
                    .flatMap { _ in
                                fetchOperation()
                                    .map { output -> Result<Output, Failure> in
                                        .success(output)
                                    }
                                    .catch {
                                        Just(Result<Output, Failure>.failure($0))
                                    }
                    }
                    .receive(on: DispatchQueue.main)

        self.results = innerResults.eraseToAnyPublisher()
        self.values = innerResults
            .compactMap {
                switch $0 {
                case let .success(output):
                    return output

                case .failure:
                    return nil
                }
            }
            .eraseToAnyPublisher()

        self.errors = innerResults
            .map {
                switch $0 {
                case .success:
                    return nil

                case let .failure(error):
                    return error
                }
            }
            .eraseToAnyPublisher()
    }
    func refresh() {
        priceFetcherRefresh.send(())
    }

}
