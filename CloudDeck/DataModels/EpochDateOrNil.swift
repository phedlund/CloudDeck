//
//  EpochDateOrNil.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/22/26.
//

import Foundation

@propertyWrapper
struct EpochDateOrNil: Codable {
    var wrappedValue: Date?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        // If the JSON value is null, decodeIfPresent would handle it, 
        // but since we are in a custom init, we decode as a Double.
        let timestamp = try container.decode(TimeInterval.self)
        
        // If timestamp is 0, we treat it as nil
        self.wrappedValue = timestamp == 0 ? nil : Date(timeIntervalSince1970: timestamp)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let date = wrappedValue {
            try container.encode(date.timeIntervalSince1970)
        } else {
            // Encode back as 0 to maintain API consistency
            try container.encode(0.0)
        }
    }
}

@propertyWrapper
struct ISO8601DateOrNil: Codable {
    var wrappedValue: Date?

    private static let iso: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime,
            .withColonSeparatorInTimeZone]
        return f
    }()

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Handle null/missing keys
        if container.decodeNil() {
            self.wrappedValue = nil
            return
        }

        let dateString = try container.decode(String.self)

        if dateString.isEmpty {
            self.wrappedValue = nil
        } else {
            // Attempt to parse with your specific formatter
            self.wrappedValue = Self.iso.date(from: dateString)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let date = wrappedValue {
            try container.encode(Self.iso.string(from: date))
        } else {
            try container.encodeNil() // Or try container.encode("") if API requires empty string
        }
    }
}
