//
//  CurrentPrice.swift
//  yacpa
//
//  Created by Michael Gray on 7/18/19.
//  Copyright © 2019 Michael Gray. All rights reserved.
//

import Combine
import Foundation
import UIKit


// MARK: - CoinDeskAPIType
protocol CoinDeskAPIType {

    associatedtype Failure: Error

    static var shared: Self { get }

    func currentPrice() -> AnyPublisher<CurrentPrice, Failure>
    func currentPriceFor(code: String) -> AnyPublisher<CurrentPrice, Failure>
    func historicalClose(_ index: CoinDeskRequest.Index?,
                         _ currency: String?,
                         _ startEnd: (String, String)?) -> AnyPublisher<HistoricalClose, Failure>
    func supportedCurrencies() -> AnyPublisher<SupportedCurrencies, Failure>

}

extension CoinDeskAPIType {

    // adding a version with default values (protocols don't support default values)
    func historicalClose(index: CoinDeskRequest.Index? = .USD,
                         currency: String? = "EUR",
                         startEnd: (String, String)? = nil) -> AnyPublisher<HistoricalClose, Failure> {
        return self.historicalClose(index, currency, startEnd)
    }


    func historicalCloseForDay(
        index: CoinDeskRequest.Index? = .USD,
        currencies: [String],
        date: String,
        storeIn set: inout Set<AnyCancellable>) -> CurrentValueSubject<HistoricalCloseForDay, Never> {


        guard let close = HistoricalCloseForDay(dateString: date) else {
            preconditionFailure("ERROR - date could not be parsed \(date)")
        }
        let subject = CurrentValueSubject<HistoricalCloseForDay, Never>(close)

        for currency in currencies {
            self.historicalClose(index, currency, (date, date))
                .mapToResults()
                .receive(on: DispatchQueue.main)
                .sink { result in
                    switch result {
                    case .success(let historicalClose):
                        guard let price = historicalClose.bpi[date] else {
                            print("WARNING - no price returned for currency \(currency) date \(date)")
                            return
                        }
                        subject.value.prices[currency] = price

                    case .failure(let error):
                        print("ERROR \(error) fetching history for currency \(currency) date \(date)")
                    }
                }
            .store(in: &set)
        }
        return subject
    }

}

// MARK: - CoinDeskAPI
struct CoinDeskAPI: CoinDeskAPIType {

    static var shared = CoinDeskAPI()

    typealias Failure = Error

    func currentPrice() -> AnyPublisher<CurrentPrice, Error> {

        let req: CoinDeskRequest = .currentPrice
        return req.fetch(CurrentPrice.self)
    }

    func currentPriceFor(code: String) -> AnyPublisher<CurrentPrice, Error> {
        let req: CoinDeskRequest = .currentPriceFor(code: code)
        return req.fetch(CurrentPrice.self)
    }

    func historicalClose(_ index: CoinDeskRequest.Index? = .USD,
                         _ currency: String? = "USD",
                         _ startEnd: (String, String)? = nil) -> AnyPublisher<HistoricalClose, Error> {
        let req: CoinDeskRequest = .historicalClose(index: index, currency: currency, startEnd: startEnd)
        return req.fetch(HistoricalClose.self)
    }

    func supportedCurrencies() -> AnyPublisher<SupportedCurrencies, Error> {
        let req: CoinDeskRequest = .supportedCurrencies
        return req.fetch(SupportedCurrencies.self)
    }

}
