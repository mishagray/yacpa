//
//  ContentView.swift
//  yacpa
//
//  Created by Michael Gray on 7/16/19.
//  Copyright © 2019 Michael Gray. All rights reserved.
//

import Combine
import SwiftUI

final class DetailViewModel: BindableObject {
    let willChange = PassthroughSubject<Void, Never>()

    var priceTexts: [String] = [] {
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

    init<Model: ModelType>(model: Model) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium

        model.setRefreshRate(timeInterval: 60.0)
        model.currentPrice
            .map { currentPrice -> ([String], String) in

                let priceTexts = currentPrice.bpi.values.map { price -> String in
                    let symbol = price.symbol.htmlDecoded
                    return "\(symbol) \(price.rate)"
                }
                let dateTime = dateFormatter.string(from: currentPrice.time.updatedISO)

                return (priceTexts, dateTime)
            }
            .sink { [weak self] priceTexts, dateTime in
                guard let `self` = self else {
                    return
                }
                self.priceTexts = priceTexts
                self.dateTime = dateTime
            }
            .store(in: &cancelables)
    }
}


struct DetailView: View {
    @ObjectBinding var viewModel: DetailViewModel

    var body: some View {
        VStack {
            Text("\(viewModel.dateTime)")
            ForEach(viewModel.priceTexts, id: \.self) { key in
                Text("\(key)")
            }
        }
    }
}

#if DEBUG
// swiftlint:disable:next type_name
struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        DetailView(viewModel: DetailViewModel(model: shared_model_Previews))
    }
}
#endif
