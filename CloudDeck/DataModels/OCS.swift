//
//  OCS.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/25/2026.
//  Copyright © 2026 Peter Hedlund. All rights reserved.
//

import Foundation
import SwiftData

/*

 {
   "ocs": {
     "meta": {
       "status": "ok",
       "statuscode": 100,
       "message": "OK",
       "totalitems": "",
       "itemsperpage": ""
     },
     "data": {
       "version": {
         "major": 31,
         "minor": 0,
         "micro": 7,
         "string": "31.0.7",
         "edition": "",
         "extendedSupport": false
       },
       "capabilities": {
         "core": {
           "pollinterval": 60,
           "webdav-root": "remote.php\/webdav",
           "reference-api": true,
           "reference-regex": "(\\s|\\n|^)(https?:\\\/\\\/)([-A-Z0-9+_.]+(?::[0-9]+)?(?:\\\/[-A-Z0-9+&@#%?=~_|!:,.;()]*)*)(\\s|\\n|$)",
           "mod-rewrite-working": false
         }
        }
    }
 }
 */

struct OCS: Decodable {
    var meta: OCSMeta
    var data: OCSData

    enum OCSKeys: String, CodingKey {
        case meta
        case data
    }

    enum CodingKeys: String, CodingKey {
        case ocs
    }

    init(from decoder: Decoder) throws {
        // Extract the top-level values ("ocs")
        let values = try decoder.container(keyedBy: CodingKeys.self)

        // Extract the meta and data objects as a nested container
        let ocs = try values.nestedContainer(keyedBy: OCSKeys.self, forKey: .ocs)

        // Extract each property from the nested container
        meta = try ocs.decode(OCSMeta.self, forKey: .meta)
        data = try ocs.decode(OCSData.self, forKey: .data)
    }

}

/*
 "meta": {
     "itemsperpage": "",
     "message": "OK",
     "status": "ok",
     "statuscode": 100,
     "totalitems": ""
 }

 */
struct OCSMeta: Codable {
    var status: String
    var statuscode: Int
    var message: String
    var totalitems: String
    var itemsperpage: String
}

struct OCSData: Decodable {
    var version: OCSVersionDTO
    var deck: DeckDTO?

    enum CodingKeys: String, CodingKey {
        case version
        case capabilities
    }

    enum ExtraKeys: String, CodingKey {
        case deck
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        version = try values.decode(OCSVersionDTO.self, forKey: .version)
        let capabilityValues = try values.nestedContainer(keyedBy: ExtraKeys.self, forKey: .capabilities)
        deck = try capabilityValues.decodeIfPresent(DeckDTO.self, forKey: .deck)
    }
}

/*
 "version": {
     "edition": "",
     "extendedSupport": 0,
     "major": 18,
     "micro": 2,
     "minor": 0,
     "string": "18.0.2"
 }

 */
struct OCSVersionDTO: Codable {
    let major: Int
    let minor: Int
    let micro: Int
    let string: String
    let edition: String
    let extendedSupport: Bool
}

@Model
final class OCSVersion {
    var major: Int
    var minor: Int
    var micro: Int
    var string: String
    var edition: String
    var extendedSupport: Bool

    init(major: Int, minor: Int, micro: Int, string: String, edition: String, extendedSupport: Bool) {
        self.major = major
        self.minor = minor
        self.micro = micro
        self.string = string
        self.edition = edition
        self.extendedSupport = extendedSupport
    }

    convenience init(dto: OCSVersionDTO) {
        self.init(major: dto.major,
                  minor: dto.minor,
                  micro: dto.micro,
                  string: dto.string,
                  edition: dto.edition,
                  extendedSupport: dto.extendedSupport
        )
    }
}

struct DeckDTO: Decodable {
    var version: String
    var canCreateBoards: Bool
    var apiVersions: [String]
}

@Model
final class Deck {
    var version: String
    var canCreateBoards: Bool

    init(version: String, canCreateBoards: Bool) {
        self.version = version
        self.canCreateBoards = canCreateBoards
    }

    convenience init(dto: DeckDTO) {
        self.init(version: dto.version,
                  canCreateBoards: dto.canCreateBoards)
    }
}
