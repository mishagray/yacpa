//
//  ContentView.swift
//  yacpa
//
//  Created by Michael Gray on 7/16/19.
//  Copyright © 2019 Michael Gray. All rights reserved.
//
import Combine
import SwiftUI


final class PriceListViewModel<Model: ModelType>: BindableObject {
    typealias RowViewModel = PriceListRowViewModel<Model>

    let willChange = PassthroughSubject<Void, Never>()

    @Published var latestData: PriceListRowViewModel<Model>? = nil {
        willSet {
            willChange.send()
        }
    }

    @Published var historicalData: [PriceListRowViewModel<Model>] = [] {
        willSet {
            willChange.send()
        }
    }
    private var cancelables = Set<AnyCancellable>()

    let model: Model

    init(model: Model) {
        self.model = model

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium

        model.setRefreshRate(timeInterval: 10.0)

        Publishers
            .CombineLatest3(model.currency.print("currency:"),
                            model.currentPrice.print("currentPrice:"),
                            model.historicalPrices.print("historicalPrices:"))
            .map { currency, currentPrice, historicalPrices -> (RowViewModel?, [RowViewModel]) in


                var latestData: RowViewModel?
                if let price = currentPrice.bpi[currency] {
                    let symbol = price.symbol.htmlDecoded

                    let formatter = NumberFormatter()
                    formatter.numberStyle = .currency
                    formatter.currencySymbol = symbol
                    let string = formatter.string(from: NSNumber(value: price.rateFloat)) ?? "ERROR!!!"


                    let date = currentPrice.time.updatedISO
                    latestData = PriceListRowViewModel(price: string, date: date, showMinutes: true)
                }

                var rowData: [RowViewModel] = []

                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                formatter.currencySymbol = currentPrice.bpi[currency]?.symbol.htmlDecoded ?? currency

                let historcalMap = historicalPrices.bpi

                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"

                for (dateString, price) in historcalMap {
                    if let date = dateFormatter.date(from: dateString) {
                        let string = formatter.string(from: NSNumber(value: price)) ?? "ERROR!!!"
                        let row = RowViewModel(price: string, date: date)
                        rowData.append(row)
                    }
                }
                let historicalData = rowData.sorted {
                    $0.date > $1.date
                }
                return (latestData, historicalData)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] latestData, historicalData in
                print(
                    """
                    setting latestData = \(String(describing: latestData))\
                    historicalData = \(historicalData.count) items
                    """
                )
                self?.latestData = latestData
                self?.historicalData = historicalData
            }
            .store(in: &cancelables)
    }
}


struct PriceList<Model: ModelType>: View {
    @ObjectBinding var viewModel: PriceListViewModel<Model>

    var body: some View {

        var sections: [Any] = []

        if let latestData = viewModel.latestData {

            let firstSection =
                Section(header: Text("Latest Price")) {
                    NavigationLink(destination: DetailView(viewModel: CurrentPriceDetailViewModel<Model>())) {
                        PriceListRow(viewModel: latestData)

                    }
                }
            sections.append(firstSection)
        }

        return NavigationView {
            List {
                if viewModel.latestData != nil {
                    Section(header: Text("Latest Price")) {
                        NavigationLink(destination: DetailView(viewModel: CurrentPriceDetailViewModel<Model>())) {
                                // swiftlint:disable:next force_unwrapping
                                PriceListRow(viewModel: viewModel.latestData!)

                        }
                    }
                }
                Section(header: Text("Historical Prices")) {
                    ForEach(viewModel.historicalData) { rowData in
                        NavigationLink(destination: DetailView(viewModel: rowData.historicalDetailViewModel)) {
                            PriceListRow(viewModel: rowData)
                        }
                    }
                }
            }
           .navigationBarTitle(Text("Bitcoin Prices"))
        }
    }
}

#if DEBUG
// swiftlint:disable:next type_name
struct PriceList_Previews: PreviewProvider {

    static var model: PriceListViewModel<Shared_Model_Previews> {
        let model = PriceListViewModel(model: shared_model_Previews)
        model.latestData = PriceListRowViewModel(price: "$123.00", date: Date(), showMinutes: true)

        model.historicalData = [
            PriceListRowViewModel(price: "$1234.000", date: Date()),
            PriceListRowViewModel(price: "$123.1232", date: Date()),
            PriceListRowViewModel(price: "$123.321", date: Date())
        ]
        return model
    }
    static var previews: some View {
        PriceList(viewModel: model)
    }
}
#endif
