//
//  CoindeskRequest.swift
//  yacpa
//
//  Created by Michael Gray on 7/22/19.
//  Copyright © 2019 Michael Gray. All rights reserved.
//

import Combine
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
