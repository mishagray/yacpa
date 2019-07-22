//
//  ContentView.swift
//  yacpa
//
//  Created by Michael Gray on 7/16/19.
//  Copyright © 2019 Michael Gray. All rights reserved.
//

import Combine
import SwiftUI


final class PriceListRowViewModel: BindableObject, Hashable, Identifiable {
    static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }

    let willChange = PassthroughSubject<Void, Never>()
    var price: String {
        willSet {
            willChange.send()
        }
    }
    var date: Date {
        willSet {
            willChange.send()
        }
    }

    var dateString: String {
        PriceListRowViewModel.dateFormatter.string(from: self.date)
    }

    init(price: String, date: Date) {
        self.price = price
        self.date = date
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(date)
        hasher.combine(price)
    }
    static func == (lhs: PriceListRowViewModel, rhs: PriceListRowViewModel) -> Bool {
        lhs.date == rhs.date && lhs.price == rhs.price
    }

}

final class PriceListViewModel: BindableObject {
    let willChange = PassthroughSubject<Void, Never>()

    @Published var rowData: [PriceListRowViewModel] = [] {
        willSet {
            willChange.send()
        }
    }
    private var cancelables = Set<AnyCancellable>()

    init<Model: ModelType>(model: Model) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium

        model.setRefreshRate(timeInterval: 60.0)

        Publishers
            .CombineLatest3(model.currency.print("currency:"),
                            model.currentPrice.print("currentPrice:"),
                            model.historicalPrices.print("historicalPrices:"))
            .map { currency, currentPrice, historicalPrices -> [PriceListRowViewModel] in

                var rowData: [PriceListRowViewModel] = []

                let symbol = currentPrice.bpi[currency]?.symbol.htmlDecoded ?? ""

                if let price = currentPrice.bpi[currency] {
                    let string = "\(symbol)\(price.rate)"

                    let date = currentPrice.time.updatedISO
                    let row = PriceListRowViewModel(price: string, date: date)

                    rowData.append(row)

                }
                let historcalMap = historicalPrices.bpi

                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"

                for (dateString, price) in historcalMap {

                    let floatFormat = String(format: "%0.4f", price)
                    if let date = dateFormatter.date(from: dateString) {
                        let string = "\(symbol)\(floatFormat)"
                        let row = PriceListRowViewModel(price: string, date: date)
                        rowData.append(row)
                    }
                }
                return rowData.sorted {
                    $0.date > $1.date
                }
            }
            .print("Combine3:")
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rowData in
                print("setting prices = \(rowData)")
                self?.rowData = rowData
            }
            .store(in: &cancelables)
    }
}


struct PriceList: View {
    @ObjectBinding var viewModel: PriceListViewModel

    var body: some View {
        List(viewModel.rowData) { rowData in
            Text("\(rowData.price) - \(rowData.dateString) ")
        }
    }
}

#if DEBUG
// swiftlint:disable:next type_name
struct PriceList_Previews: PreviewProvider {
    static var previews: some View {
        PriceList(viewModel: PriceListViewModel(model: shared_model_Previews))
    }
}
#endif
