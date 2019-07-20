//
//  Coindesk.swift
//  yacpa
//
//  Created by Michael Gray on 7/18/19.
//  Copyright © 2019 Michael Gray. All rights reserved.
//

import Foundation
import Nimble
import Quick
@testable import yacpa

class Coindesk: QuickSpec {
    // swiftlint:disable:next function_body_length
    override func spec() {

        let isoDateFormatter = ISO8601DateFormatter()
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        describe("coindesk") { // 1
            context("parsing JSON data") { // 2
                it("decode currentprice") { // 3
                    let rawData =   """
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
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601

                    guard let data = rawData.data(using: .utf16) else {
                        fail("rawdata decoding error")
                        return
                    }

                    do {
                        let currentPrice = try decoder.decode(CurrentPrice.self, from: data)

                        expect(currentPrice.time.updated) == "Jul 18, 2019 23:31:00 UTC"
                        expect(currentPrice.time.updateduk) == "Jul 19, 2019 at 00:31 BST"
                        let updatedISO = isoDateFormatter.string(from: currentPrice.time.updatedISO)
                        expect(updatedISO) == "2019-07-18T23:31:00Z"

                        expect(currentPrice.chartName) == "Bitcoin"


                        guard let usd = currentPrice.bpi["USD"] else {
                            fail("no USD price found")
                            return
                        }
                        expect(usd.code) == "USD"
                        expect(usd.rate) == "10,666.5500"
                        expect(usd.rateFloat) == 10_666.55
                        expect(usd.description) == "United States Dollar"

                        guard let gbp = currentPrice.bpi["GBP"] else {
                            fail("no GBP price found")
                            return
                        }
                        expect(gbp.code) == "GBP"
                        expect(gbp.rate) == "8,512.9096"
                        expect(gbp.rateFloat) == 8_512.909_6
                        expect(gbp.description) == "British Pound Sterling"

                        guard let eur = currentPrice.bpi["EUR"] else {
                            fail("no EUR price found")
                            return
                        }
                        expect(eur.code) == "EUR"
                        expect(eur.rate) == "9,481.8696"
                        expect(eur.rateFloat) == 9_481.869_6
                        expect(eur.description) == "Euro"
                    } catch {
                        fail("Unexpected error: \(error).")
                    }
                }

                it ("decode historical/close") {
                    let rawData =   """
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

                    guard let data = rawData.data(using: .utf16) else {
                        fail("rawdata decoding error")
                        return
                    }

                    do {
                        let historical = try decoder.decode(HistoricalClose.self, from: data)

                        expect(historical.time.updated) == "Jul 19, 2019 00:03:00 UTC"
                        expect(historical.time.updateduk).to(beNil())
                        let updatedISO = isoDateFormatter.string(from: historical.time.updatedISO)
                        expect(updatedISO) == "2019-07-19T00:03:00Z"

                        let bpi = historical.bpi
                        expect(bpi.count) == 31
                        expect(bpi["2019-06-18"]) == 9_083.816_7
                        expect(bpi["2019-07-18"]) == 10_636.91
                    } catch {
                        fail("Unexpected error: \(error).")
                    }
                }

                it ("decode supported-currencies") {
                    let rawData =
                    """
                [
                    { "currency": "AED", "country": "United Arab Emirates Dirham" },
                    { "currency": "AFN", "country": "Afghan Afghani" },
                    { "currency": "ALL", "country": "Albanian Lek" },
                    { "currency": "AMD", "country": "Armenian Dram" },
                    { "currency": "ANG", "country": "Netherlands Antillean Guilder" },
                    { "currency": "AOA", "country": "Angolan Kwanza" },
                    { "currency": "ARS", "country": "Argentine Peso" },
                    { "currency": "AUD", "country": "Australian Dollar" },
                    { "currency": "AWG", "country": "Aruban Florin" },
                    { "currency": "USD", "country": "United States Dollar" },
                    { "currency": "UYU", "country": "Uruguayan Peso" },
                    { "currency": "UZS", "country": "Uzbekistan Som" },
                    { "currency": "VEF", "country": "Venezuelan Bolívar Fuerte" },
                    { "currency": "VND", "country": "Vietnamese Dong" },
                    { "currency": "VUV", "country": "Vanuatu Vatu" },
                    { "currency": "WST", "country": "Samoan Tala" },
                    { "currency": "XAF", "country": "CFA Franc BEAC" },
                    { "currency": "XAG", "country": "Silver (troy ounce)" },
                    { "currency": "XAU", "country": "Gold (troy ounce)" },
                    { "currency": "XBT", "country": "Bitcoin" },
                    { "currency": "XCD", "country": "East Caribbean Dollar" },
                    { "currency": "XDR", "country": "Special Drawing Rights" },
                    { "currency": "XOF", "country": "CFA Franc BCEAO" },
                    { "currency": "XPF", "country": "CFP Franc" },
                    { "currency": "YER", "country": "Yemeni Rial" },
                    { "currency": "ZAR", "country": "South African Rand" },
                    { "currency": "ZMK", "country": "Zambian Kwacha (pre-2013)" },
                    { "currency": "ZMW", "country": "Zambian Kwacha" },
                    { "currency": "ZWL", "country": "Zimbabwean Dollar" }
                ]
                """

                    guard let data = rawData.data(using: .utf16) else {
                        fail("rawdata decoding error")
                        return
                    }

                    do {
                        let currencies = try decoder.decode(SupportedCurrencies.self, from: data)

                        expect(currencies.count) == 29
                        expect(currencies[0].currency) == "AED"
                        expect(currencies[0].country) == "United Arab Emirates Dirham"
                        expect(currencies[28].currency) == "ZWL"
                        expect(currencies[28].country) == "Zimbabwean Dollar"
                    } catch {
                        fail("Unexpected error: \(error).")
                    }
                }
            }
        }
    }
}
