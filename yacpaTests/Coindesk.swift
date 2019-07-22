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
                    let rawData = CurrentPrice.dummyJSONString

                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601

                    guard let data = rawData.data(using: .utf8) else {
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
                    let rawData = HistoricalClose.dummyJSONString

                    guard let data = rawData.data(using: .utf8) else {
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
                    let rawData = SupportedCurrencies.dummyJSONString

                    guard let data = rawData.data(using: .utf8) else {
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
