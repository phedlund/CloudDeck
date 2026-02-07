//
//  ValetManager.swift
//  CloudNews
//
//  Created by Peter Hedlund on 8/27/25.
//

import Foundation
import Valet

class ValetManager {
    static let shared = ValetManager()
    let valet = Valet.valet(with: Identifier(nonEmpty: Constants.productName)!, accessibility: .afterFirstUnlock)

    init() { }

    func saveCredentials(username: String, password: String) throws {
        try valet.setString(username, forKey: Constants.Settings.username)
        try valet.setString(password, forKey:  Constants.Settings.password)
    }

    func logOut() {
        do {
            try valet.removeAllObjects()
        } catch {
            //
        }
    }

    private var credentials: String? {
        do {
            let username = try valet.string(forKey: Constants.Settings.username)
            let password = try valet.string(forKey: Constants.Settings.password)
            return Data("\(username):\(password)".utf8).base64EncodedString()
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }

    var basicAuthHeader: String {
        guard let credentials else { return "" }
        return "Basic \(credentials)"
    }
}
