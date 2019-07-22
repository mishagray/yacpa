//
//  DummyCoindeskAPI.swift
//  yacpa
//
//  Created by Michael Gray on 7/21/19.
//  Copyright © 2019 Michael Gray. All rights reserved.
//

import Combine
import Foundation


struct DummyCoinDeskAPI: CoinDeskAPIType {

    enum DummyError: Error {
        case randomError
        case never
    }
    typealias Failure = DummyError

    static var shared = DummyCoinDeskAPI()

    // number between 0.0 and 1.0 = % of calls that should fail.
    var failureRate: Double = 0.0

    private func randomDataOrFail<T>(_ data: T) -> AnyPublisher<T, Failure> {
        let shouldFail = Double.random(in: 0.0...1.0) < failureRate

        if shouldFail {
            return Fail<T, Failure>(error: .randomError)
                .eraseToAnyPublisher()
        }
        return Just<T>(data)
            .mapError { _ in DummyError.never }
            .eraseToAnyPublisher()
    }

    func currentPrice() -> AnyPublisher<CurrentPrice, Failure> {
        return randomDataOrFail(CurrentPrice.dummyData)
    }

    func currentPriceFor(code: String) -> AnyPublisher<CurrentPrice, Failure> {
        return randomDataOrFail(CurrentPrice.dummyData)
    }

    func historicalClose(_ index: CoinDeskRequest.Index? = .USD,
                         _ currency: String? = "USD",
                         _ startEnd: (String, String)? = nil) -> AnyPublisher<HistoricalClose, Failure> {

        return randomDataOrFail(HistoricalClose.dummyData)
    }

    func supportedCurrencies() -> AnyPublisher<SupportedCurrencies, Failure> {
        return randomDataOrFail(SupportedCurrencies.dummyData)
    }

}

// swiftlint:disable type_name
// you can change which API to use for Previews
typealias CoinBaseAPI_Previews = DummyCoinDeskAPI
// typealias CoinBaseAPI_Previews = CoinDeskAPI      

typealias Shared_Model_Previews = APIModel<CoinBaseAPI_Previews>

// swiftlint:disable identifier_name
var shared_model_Previews = Shared_Model_Previews()
