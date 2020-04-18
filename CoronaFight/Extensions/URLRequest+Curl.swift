//
//  URLRequest.swift
//  CoronaFight
//
//  Created by Przemysław Szurmak on 01/04/2020.
//  Copyright © 2020 Przemysław Szurmak. All rights reserved.
//

import Foundation

extension URLRequest {
    public var curlString: String {
        let method = self.httpMethod ?? "GET"
        var returnValue = "curl -X \(method) "

        if let httpBody = self.httpBody, self.httpMethod == "POST" || self.httpMethod == "PUT" {
            let maybeBody = String(data: httpBody, encoding: String.Encoding.utf8)
            if let body = maybeBody {
                returnValue += "-d \"\(escapeTerminalString(body))\" "
            }
        }

        for (key, value) in self.allHTTPHeaderFields ?? [:] {
            let escapedKey = escapeTerminalString(key as String)
            let escapedValue = escapeTerminalString(value as String)
            returnValue += "\n    -H \"\(escapedKey): \(escapedValue)\" "
        }

        let URLString = self.url?.absoluteString ?? "<unknown url>"

        returnValue += "\n\"\(escapeTerminalString(URLString))\""

        returnValue += " -i -v"

        return returnValue
    }

    private func escapeTerminalString(_ value: String) -> String {
        return value.replacingOccurrences(of: "\"", with: "\\\"", options:[], range: nil)
    }
}
