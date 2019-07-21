//
//  CurrentPrice.swift
//  yacpa
//
//  Created by Michael Gray on 7/18/19.
//  Copyright © 2019 Michael Gray. All rights reserved.
//

import Alamofire
import Combine
import Foundation
import UIKit

//  from https://www.coindesk.com/api
//  https://api.coindesk.com/v1/bpi/currentprice.json

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

// MARK: - CurrentPrice
struct CurrentPrice: Decodable {
    let time: Time
    let chartName: String
    let bpi: [String: Price]
}

// MARK: - Price
struct Price: Decodable {
    let code: String
    let symbol: String
    let rate: String
    let description: String
    let rateFloat: Double

    enum CodingKeys: String, CodingKey {
        case code, symbol, rate, description
        case rateFloat = "rate_float"
    }
}

// MARK: - Time
struct Time: Decodable {
    let updated: String
    let updatedISO: Date
    let updateduk: String?
}


// MARK: - HistoricalClose
struct HistoricalClose: Decodable {
    let bpi: [String: Double]
    let time: Time
}

// MARK: - SupportedCurrency
struct SupportedCurrency: Decodable {
    let currency: String
    let country: String
}

typealias SupportedCurrencies = [SupportedCurrency]


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
}

extension CoinDeskRequest {

    func fetch<T: Decodable>(_ type: T.Type) -> AnyPublisher<T, Error> {
        return URLSession.shared
            .dataTaskPublisher(for: self.url)
            .map { $0.data }
            .decode(type: T.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }

}

class CoinDeskAPI {

    static var shared = CoinDeskAPI()

    static func currentPrice() -> AnyPublisher<CurrentPrice, Error> {

        let req: CoinDeskRequest = .currentPrice
        return req.fetch(CurrentPrice.self)
    }

    static func currentPriceFor(code: String) -> AnyPublisher<CurrentPrice, Error> {
        let req: CoinDeskRequest = .currentPriceFor(code: code)
        return req.fetch(CurrentPrice.self)
    }

    static func historicalClose(index: CoinDeskRequest.Index? = .USD,
                                currency: String? = "USD",
                                startEnd: (String, String)? = nil) -> AnyPublisher<HistoricalClose, Error> {
        let req: CoinDeskRequest = .historicalClose(index: index, currency: currency, startEnd: startEnd)
        return req.fetch(HistoricalClose.self)
    }

    static func supportedCurrencies() -> AnyPublisher<SupportedCurrencies, Error> {
        let req: CoinDeskRequest = .supportedCurrencies
        return req.fetch(SupportedCurrencies.self)
    }

}


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
