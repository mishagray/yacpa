//
//  CurrentPrices.swift
//  yacpa
//
//  Created by Michael Gray on 7/19/19.
//  Copyright © 2019 Michael Gray. All rights reserved.
//

import Combine
import Foundation


// why no protocol?  Why no
// So ... it's really nice to have @Published in a Model/ViewModel
// But you can't use propertyWrappers in a protocol definition.
// Need to figure out the balance between the desire to have 
class Model<API: CoinDeskAPIType> {

    enum ModelError: Swift.Error {
        case noValueAvailable
    }

    @Published var currentPrice: CurrentPrice?
    @Published var currentPriceError: API.Failure?
    @Published var historicalPrices: HistoricalClose?
    @Published var historicalPricesErrors: API.Failure?

    let currentPriceRefreshable: RefreshableValue<CurrentPrice, API.Failure>
    let historicalPricesRefreshable: RefreshableValue<HistoricalClose, API.Failure>

    private var cancelables = [AnyCancellable]()
    private var timerCancelable: AnyCancellable?

    var refreshRate: TimeInterval = 0.0 {
        didSet {
            self.timerCancelable?.cancel()
            if refreshRate > 0.0 {
                let sink = Timer
                    .publish(every: refreshRate, on: .main, in: .default)
                    .autoconnect()
                    .sink { [weak self] _ in
                        self?.currentPriceRefreshable.refresh()
                    }
                self.timerCancelable = AnyCancellable(sink)
            } else {
                self.timerCancelable = nil
            }
        }
    }

    init(api: API.Type) {
        currentPrice = nil
        currentPriceError = nil
        historicalPrices = nil
        historicalPricesErrors = nil

        currentPriceRefreshable = RefreshableValue {
            api.shared.currentPrice()
        }
        historicalPricesRefreshable = RefreshableValue {
            api.shared.historicalClose()
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
                print("error recd = \(String(describing: $0))")
                self?.currentPriceError = $0
            }
        .store(in: &cancelables)

        historicalPricesRefreshable
            .values
            .sink { [weak self] in
                self?.historicalPrices = $0
            }
        .store(in: &cancelables)

        historicalPricesRefreshable
            .errors
            .sink { [weak self] in
                self?.historicalPricesErrors = $0
            }
        .store(in: &cancelables)

        self.refresh()
    }
    func refresh() {
        currentPriceRefreshable.refresh()
        historicalPricesRefreshable.refresh()
    }
}
