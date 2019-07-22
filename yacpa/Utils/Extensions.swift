//
//  htmlDecode.swift
//  yacpa
//
//  Created by Michael Gray on 7/21/19.
//  Copyright © 2019 Michael Gray. All rights reserved.
//

import Foundation

extension String {

    // decodes HTML into Strings.
    // used to decode CoinbaseAPI's currency symbols
    var htmlDecoded: String {
        let decoded = try? NSAttributedString(
            data: Data(utf8),
            options: [.documentType: NSAttributedString.DocumentType.html,
                      .characterEncoding: String.Encoding.utf8.rawValue],
            documentAttributes: nil).string

        return decoded ?? self
    }
}

// Useful for writing generic functions that can detect if an associated type is Optional.
protocol OptionalType: ExpressibleByNilLiteral {
    associatedtype Wrapped

    var unwrapped: Wrapped? { get }

    init(_ some: Wrapped)
}

extension Optional: OptionalType {
    var unwrapped: Wrapped? {
        return self
    }
}
