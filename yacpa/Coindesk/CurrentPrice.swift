//
//  CurrentPrice.swift
//  yacpa
//
//  Created by Michael Gray on 7/18/19.
//  Copyright © 2019 Michael Gray. All rights reserved.
//

import Foundation

//  from https://www.coindesk.com/api
//  https://api.coindesk.com/v1/bpi/currentprice.json

enum CoindeskAPI {
    case currentPrice
    
}


// MARK: - CurrentPrice
struct CurrentPrice: Decodable {
    let time: Time
    let disclaimer, chartName: String
    let bpi: [String: Price]
}

// MARK: - Price
struct Price: Decodable {
    let code, symbol, rate, description: String
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
    let disclaimer: String?
    let time: Time
}

// MARK: - SupportedCurrency
struct SupportedCurrency: Decodable {
    let currency, country: String
}

typealias SupportedCurrencies = [SupportedCurrency]

