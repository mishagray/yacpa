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


enum CoinDeskRequest {
    enum Index: String {
        case USD
        case CNY
    }
    case currentPrice
    case currentPriceFor(code: String)
    case historicalClose(index: Index? = .USD, currency: String? = "USD", startEnd: (String, String)? = nil)
    // didn't add support for ?for=yesterday
    case supportedCurrencies
}


extension CoinDeskRequest {
    var url: URL {
        switch self {
        case .currentPrice:
            // swiftlint:disable:next force_unwrapping
            return URL(string: "https://api.coindesk.com/v1/bpi/currentprice.json")!

        case let .currentPriceFor(code):
            // swiftlint:disable:next force_unwrapping
            return URL(string: "https://api.coindesk.com/v1/bpi/currentprice/\(code).json")!

        case let .historicalClose(index, currency, startEnd):
            var components = URLComponents()
            components.scheme = "https"
            components.host = "api.coindesk.com"
            components.path = "/v1/bpi/historical/close.json"
            var items: [URLQueryItem] = []
            if let index = index {
                items.append(URLQueryItem(name: "index", value: index.rawValue))
            }
            if let currency = currency {
                items.append(URLQueryItem(name: "currency", value: currency))
            }
            if let (start, end) = startEnd {
                items.append(URLQueryItem(name: "start", value: start))
                items.append(URLQueryItem(name: "end", value: end))
            }
            components.queryItems = items
            // swiftlint:disable:next force_unwrapping
            return components.url!

        case .supportedCurrencies:
            // swiftlint:disable:next force_unwrapping
            return URL(string: "https://api.coindesk.com/v1/bpi/supported-currencies.json")!

        }
    }

    func fetch<T: Decodable>(_ type: T.Type) -> AnyPublisher<T, Error> {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        print("fetching [\(self.url)]")
        return URLSession.shared
            .dataTaskPublisher(for: self.url)
            .map {
                let string = String(data: $0.data, encoding: .utf8)
                print("recv [\(String(describing: string))]")
                return $0.data
            }
        .decode(type: T.self, decoder: decoder)
            .eraseToAnyPublisher()
    }

}

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
