//
//  TodayViewController.swift
//  today
//
//  Created by Michael Gray on 7/22/19.
//  Copyright © 2019 Michael Gray. All rights reserved.
//

import Combine
import NotificationCenter
import UIKit

class TodayViewController: UIViewController, NCWidgetProviding {

    @IBOutlet private weak var time: UILabel!
    @IBOutlet private weak var price: UILabel!

    let model = APIModel<CoinDeskAPI>()
    private var cancelables = Set<AnyCancellable>()

    @IBAction private func tapped(_ sender: Any) {

        let url = URL(string: "yacpa://")! // swiftlint:disable:this force_unwrapping
        self.extensionContext?.open(url) { completed in
            print("open url completed = \(completed)")
        }

    }
    override func viewDidLoad() {
        super.viewDidLoad()

        self.time.text = ""
        self.price.text = ""
        // Do any additional setup after loading the view.
        _ = self.bindOnce
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.model.refresh()
        self.model.setRefreshRate(timeInterval: 10.0)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.model.setRefreshRate(timeInterval: 0.0)
    }

    let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()


    lazy var bindOnce: Void = {
        self.bind()
    }()

    func bind() {
         self.model.setRefreshRate(timeInterval: 10.0)
         // swiftlint:disable:next nesting
         typealias HORRIBLE_RETURN_TYPE = Publishers
             .Map<Publishers.Catch<AnyPublisher<HistoricalCloseForDay, Never>,
                                   Empty<HistoricalCloseForDay, Never>>,
                  (HistoricalCloseForDay, [String: String])>

         model.currentPrice
             .map { currentPrice -> (String, String) in
                guard let euroPrice = currentPrice.bpi["EUR"] else {
                    return ("", "")
                }
                let dateString = self.formatter.string(from: currentPrice.time.updatedISO)

                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                formatter.currencySymbol = euroPrice.symbol.htmlDecoded
                guard let priceString = formatter.string(from: NSNumber(value: euroPrice.rateFloat)) else {
                    return (dateString, "ERROR!!!")
                }
                return (dateString, priceString)
             }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.time.text = $0
                self?.price.text = $1
            }
            .store(in: &cancelables)
     }

    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {

        _ = self.bindOnce
        self.model.refresh()


        // Perform any setup necessary in order to update the view.

        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData

        // TODO:  Should wait until the next refresh is done.
        completionHandler(NCUpdateResult.newData)
    }

}
