//
//  CurrentPrices.swift
//  yacpa
//
//  Created by Michael Gray on 7/19/19.
//  Copyright © 2019 Michael Gray. All rights reserved.
//

import Alamofire
import Combine
import Foundation


class Model {

    static var shared = Model()

    enum ModelError: Swift.Error {
        case noValueAvailable
    }

    @Published var currentPrice: CurrentPrice?
    @Published var currentPriceError: Error?
    @Published var historicalPrices: HistoricalClose?

    let currentPriceRefreshable: RefreshableValue<CurrentPrice, Error>
    let historicalPricesRefreshable: RefreshableValue<HistoricalClose, Error>

    private var cancelables = [AnyCancellable]()

    init() {
        currentPrice = nil
        currentPriceError = nil
        historicalPrices = nil

        currentPriceRefreshable = RefreshableValue {
            return CoinDeskAPI.currentPrice()
        }
        historicalPricesRefreshable = RefreshableValue {
            return CoinDeskAPI.historicalClose()
        }

        currentPriceRefreshable
            .values
            .sink { [weak self] in
                self?.currentPrice = $0
            }
            .store(in: &cancelables)

        currentPriceRefreshable
             .errors
             .sink { [weak self] in
                 self?.currentPriceError = $0
             }
             .store(in: &cancelables)

     }
    func refresh() {
        currentPriceRefreshable.refresh()
    }
}
