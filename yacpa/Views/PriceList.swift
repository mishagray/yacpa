//
//  ContentView.swift
//  yacpa
//
//  Created by Michael Gray on 7/16/19.
//  Copyright © 2019 Michael Gray. All rights reserved.
//

import Combine
import SwiftUI


final class PriceListViewModel: BindableObject {
    let willChange = PassthroughSubject<Void, Never>()

    var currencyCode: String = "EUR" {
        willSet {
            willChange.send()
        }
    }
    var prices: [String] = [] {
        willSet {
            willChange.send()
        }
    }
    var dateTime: String = "" {
        willSet {
            willChange.send()
        }
    }

    private var cancelables = Set<AnyCancellable>()

    init<API: CoinDeskAPIType>(api: API.Type) {
        let model = Model(api: api)

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium

        model.refreshRate = 60.0
//        model.$currentPrice
//            .map { currentPrice -> (String, String) in
//                guard
//                    let currentPrice = currentPrice,
//                    let price = currentPrice.bpi[currency] else {
//                    return ("", "")
//                }
//                let symbol = price.symbol.htmlDecoded
//
//                let dateString = dateFormatter.string(from: currentPrice.time.updatedISO)
//
//                return ("\(symbol) \(price.rate)", dateString)
//            }
//            .sink { [weak self] price, dateString in
//                self?.prices = [price]
//                self?.dateTime = dateString
//            }
//            .store(in: &cancelables)
    }
}


struct PriceList: View {
    @ObjectBinding var viewModel: PriceListViewModel

    var listData = [0, 1, 2, 3, 5]

    var body: some View {
        Text("hi")
    }
}

#if DEBUG
// swiftlint:disable:next type_name
struct PriceList_Previews: PreviewProvider {
    static let viewModel = PriceListViewModel(api: CoinBaseAPI_Previews.self)

    static var previews: some View {
        return PriceList(viewModel: viewModel)
    }
}
#endif
