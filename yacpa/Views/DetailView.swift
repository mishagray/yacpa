//
//  ContentView.swift
//  yacpa
//
//  Created by Michael Gray on 7/16/19.
//  Copyright © 2019 Michael Gray. All rights reserved.
//

import Combine
import SwiftUI

protocol DetailViewModelType: BindableObject {

    var prices: [String: Double] { get }
    var date: Date? { get }
    var symbols: [String: String] { get }

}


final class HistoricalDetailViewModel<Model: ModelType>: DetailViewModelType {

    lazy var willChange = BindOnSubscription { [weak self] in
        self?.bind()
    }

    var prices: [String: Double] = [:] {
        willSet {
            willChange.send()
        }
    }
    var symbols: [String: String] = [:] {
        willSet {
            willChange.send()
        }
    }

    var date: Date? = nil {
        willSet {
            willChange.send()
        }
    }

    private var cancelables = Set<AnyCancellable>()
    private var dateString: String


    init(dateString: String) {
        self.dateString = dateString
    }


    func bind() {

        // swiftlint:disable:next nesting
        typealias HORRIBLE_RETURN_TYPE = Publishers
            .Map<Publishers.Catch<AnyPublisher<HistoricalCloseForDay, Never>,
                                  Empty<HistoricalCloseForDay, Never>>,
                 (HistoricalCloseForDay, [String: String])>

        let model = Model()
        model.currentPrice
            .first()   // first fetch the currencies and codes from latest value
            .flatMap { currentPrice -> HORRIBLE_RETURN_TYPE in
                var symbols = [String: String]()
                for price in currentPrice.bpi.values {
                    symbols[price.code] = price.symbol.htmlDecoded
                }

                let currencies = Array(symbols.keys)
                return model
                    .getHistoricalCloseForDay(currencies: currencies, date: self.dateString)
                    .ignoreErrors()
                    .map { ($0, symbols) }
            }
            .ignoreErrors()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] close, symbols in
                guard let `self` = self else {
                    return
                }
                self.prices = close.prices
                self.date = close.date
                self.symbols = symbols
            }
            .store(in: &cancelables)
    }
}

final class CurrentPriceDetailViewModel<Model: ModelType>: DetailViewModelType {
     lazy var willChange = BindOnSubscription { [weak self] in
        self?.bind()
     }

    var prices: [String: Double] = [:] {
        willSet {
            willChange.send()
        }
    }
    var symbols: [String: String] = [:] {
        willSet {
            willChange.send()
        }
    }

    var date: Date? = nil {
        willSet {
            willChange.send()
        }
    }

    let model = Model()
    private var cancelables = Set<AnyCancellable>()

    func bind() {
        self.model.setRefreshRate(timeInterval: 10.0)
        // swiftlint:disable:next nesting
        typealias HORRIBLE_RETURN_TYPE = Publishers
            .Map<Publishers.Catch<AnyPublisher<HistoricalCloseForDay, Never>,
                                  Empty<HistoricalCloseForDay, Never>>,
                 (HistoricalCloseForDay, [String: String])>

        model.currentPrice
            .map { ($0.historicalCloseForDay, $0.symbols) }
            .sink { [weak self] close, symbols in
                guard let `self` = self else {
                    return
                }
                self.prices = close.prices
                self.date = close.date
                self.symbols = symbols
            }
            .store(in: &cancelables)
    }
}


struct IdentifierString: Identifiable {
    var id: ObjectIdentifier

    var string: String
}

struct DetailView<ViewModel: DetailViewModelType>: View {
    @ObjectBinding var viewModel: ViewModel

    let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()

    var priceTexts: [String] {
        return self.viewModel.prices
            .map { entry in
                let (currency, price) = entry

                let symbol = viewModel.symbols[currency] ?? currency

                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                formatter.currencySymbol = symbol
                return formatter.string(from: NSNumber(value: price)) ?? "ERROR!!!"

            }
            .sorted()
            .reversed()
    }

    var dateText: String {
        guard let date = self.viewModel.date else {
            return ""
        }
        return self.formatter.string(from: date)
    }

    var body: some View {
        VStack {
            Text("\(self.dateText)")
            VStack(alignment: .trailing) {
                ForEach(self.priceTexts, id: \.self) {
                    Text("\($0)")
                }
                Spacer()
            }
        }
    }
}

#if DEBUG
// swiftlint:disable:next type_name
struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyView()
//        DetailView(viewModel: DetailViewModel(model: shared_model_Previews))
    }
}
#endif
