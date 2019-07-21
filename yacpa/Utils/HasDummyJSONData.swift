//
//  HasDummyJSONData.swift
//  yacpa
//
//  Created by Michael Gray on 7/21/19.
//  Copyright © 2019 Michael Gray. All rights reserved.
//

import Foundation

// allow a type to supply a default 'dummy' data.
// useful for testing and also for SwiftUI Canvas Previews
protocol HasDummyJSONData: Decodable {
    // this needs to be a valid, decodable JSON String,
    // otherwise it's possible for unhandled exceptions to occur during decoding.
    static var dummyJSONString: String { get }

    // Override if class needs a different decoder than the default (check extension below for default decoder setting).
    static var dummyDecoder: JSONDecoder { get }
}

extension HasDummyJSONData {

    // provide a default decoder.
    // NOTE: current default uses dateDecodingStrategy of .iso8601
    static var dummyDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    static var dummyJSONData: Data {
        guard let data = self.dummyJSONString.data(using: self.dummyJSONString.fastestEncoding) else {
            preconditionFailure("decoding error decoding \(Self.self) dummyJSONString")
        }
        return data
    }

    static var dummyData: Self {
        do {
            return try self.dummyDecoder.decode(Self.self, from: self.dummyJSONData)
        } catch {
            preconditionFailure("error \(error) decoding \(Self.self).dummyJSONData")
        }
    }

}
