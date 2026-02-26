//
//  CloudStatus.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/25/26.
//


import Foundation

/*
 {
 "installed":true,
 "maintenance":false,
 "needsDbUpgrade":false,
 "version":"31.0.7.1",
 "versionstring":"31.0.7",
 "edition":"",
 "productname":"Nextcloud",
 "extendedSupport":false
 }
 */

struct NextcloudStatus: Decodable {
    var installed: Bool
    var maintenance: Bool
    var needsDbUpgrade: Bool
    var version: String
    var versionstring: String
    var edition: String
    var productname: String
    var extendedSupport: Bool
}
