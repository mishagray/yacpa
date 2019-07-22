//
//  DummyCoindeskAPI.swift
//  yacpa
//
//  Created by Michael Gray on 7/21/19.
//  Copyright © 2019 Michael Gray. All rights reserved.
//

import Combine
import Foundation


extension CurrentPrice: HasDummyJSONData {
    static var dummyJSONString =
    """
        {
          "time": {
            "updated": "Jul 18, 2019 23:31:00 UTC",
            "updatedISO": "2019-07-18T23:31:00+00:00",
            "updateduk": "Jul 19, 2019 at 00:31 BST"
          },
          "chartName": "Bitcoin",
          "bpi": {
            "USD": {
              "code": "USD",
              "symbol": "&#36;",
              "rate": "10,666.5500",
              "description": "United States Dollar",
              "rate_float": 10666.55
            },
            "GBP": {
              "code": "GBP",
              "symbol": "&pound;",
              "rate": "8,512.9096",
              "description": "British Pound Sterling",
              "rate_float": 8512.9096
            },
            "EUR": {
              "code": "EUR",
              "symbol": "&euro;",
              "rate": "9,481.8696",
              "description": "Euro",
              "rate_float": 9481.8696
            }
          }
        }
        """
}

extension HistoricalClose: HasDummyJSONData {
    static var dummyJSONString: String =
    """
        {
          "bpi": {
            "2019-06-18": 9083.8167,
            "2019-06-19": 9288.5367,
            "2019-06-20": 9539.7883,
            "2019-06-21": 10232.9167,
            "2019-06-22": 10695.3683,
            "2019-06-23": 10860.8233,
            "2019-06-24": 11041.8533,
            "2019-06-25": 11752.6783,
            "2019-06-26": 12907.135,
            "2019-06-27": 11170.885,
            "2019-06-28": 12356.2783,
            "2019-06-29": 11882.5083,
            "2019-06-30": 10769.4217,
            "2019-07-01": 10599.3267,
            "2019-07-02": 10850.4,
            "2019-07-03": 11976.6317,
            "2019-07-04": 11151.9183,
            "2019-07-05": 10996.4267,
            "2019-07-06": 11252.4533,
            "2019-07-07": 11476.4083,
            "2019-07-08": 12294.6567,
            "2019-07-09": 12563.215,
            "2019-07-10": 12096.6533,
            "2019-07-11": 11345.7717,
            "2019-07-12": 11789.3367,
            "2019-07-13": 11350.6283,
            "2019-07-14": 10194.21,
            "2019-07-15": 10842.4517,
            "2019-07-16": 9422.4517,
            "2019-07-17": 9692.7067,
            "2019-07-18": 10636.91
          },
          "time": {
            "updated": "Jul 19, 2019 00:03:00 UTC",
            "updatedISO": "2019-07-19T00:03:00+00:00"
          }
        }
        """
}

extension SupportedCurrencies: HasDummyJSONData {
    static var dummyJSONString: String =
    """
        {
          "bpi": {
            "2019-06-18": 9083.8167,
            "2019-06-19": 9288.5367,
            "2019-06-20": 9539.7883,
            "2019-06-21": 10232.9167,
            "2019-06-22": 10695.3683,
            "2019-06-23": 10860.8233,
            "2019-06-24": 11041.8533,
            "2019-06-25": 11752.6783,
            "2019-06-26": 12907.135,
            "2019-06-27": 11170.885,
            "2019-06-28": 12356.2783,
            "2019-06-29": 11882.5083,
            "2019-06-30": 10769.4217,
            "2019-07-01": 10599.3267,
            "2019-07-02": 10850.4,
            "2019-07-03": 11976.6317,
            "2019-07-04": 11151.9183,
            "2019-07-05": 10996.4267,
            "2019-07-06": 11252.4533,
            "2019-07-07": 11476.4083,
            "2019-07-08": 12294.6567,
            "2019-07-09": 12563.215,
            "2019-07-10": 12096.6533,
            "2019-07-11": 11345.7717,
            "2019-07-12": 11789.3367,
            "2019-07-13": 11350.6283,
            "2019-07-14": 10194.21,
            "2019-07-15": 10842.4517,
            "2019-07-16": 9422.4517,
            "2019-07-17": 9692.7067,
            "2019-07-18": 10636.91
          },
          "time": {
            "updated": "Jul 19, 2019 00:03:00 UTC",
            "updatedISO": "2019-07-19T00:03:00+00:00"
          }
        }
        """
}


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

// swiftlint:disable identifier_name
var shared_model_Previews = APIModel(api: CoinBaseAPI_Previews.self)
