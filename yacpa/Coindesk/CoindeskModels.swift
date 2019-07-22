//
//  CoindeskModels.swift
//  yacpa
//
//  Created by Michael Gray on 7/21/19.
//  Copyright © 2019 Michael Gray. All rights reserved.
//

import Foundation

//  from https://www.coindesk.com/api
//  https://api.coindesk.com/v1/bpi/currentprice.json


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


// MARK: - HistoricalCloseForDay
struct HistoricalCloseForDay {
    var prices: [String: Double]
    let date: Date

    init(date: Date, prices: [String: Double] = [:]) {
        self.prices = prices
        self.date = date
    }
    init?(dateString: String, prices: [String: Double] = [:]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        self.prices = prices
        guard let date = dateFormatter.date(from: dateString) else {
            return nil
        }
        self.date = date
    }
}

extension CurrentPrice {
    var historicalCloseForDay: HistoricalCloseForDay {
        let prices = self.bpi.mapValues {
            $0.rateFloat
        }
        return HistoricalCloseForDay(date: self.time.updatedISO, prices: prices)
    }
}
