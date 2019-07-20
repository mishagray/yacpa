//
//  CurrentPrice.swift
//  yacpa
//
//  Created by Michael Gray on 7/18/19.
//  Copyright © 2019 Michael Gray. All rights reserved.
//

import Alamofire
import Foundation

//  from https://www.coindesk.com/api
//  https://api.coindesk.com/v1/bpi/currentprice.json

enum CoindeskAPI {
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

extension CoindeskAPI {
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
