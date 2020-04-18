//
//  APICall.swift
//  CoronaFight
//
//  Created by Przemysław Szurmak on 14/03/2020.
//  Copyright © 2020 Przemysław Szurmak. All rights reserved.
//

import Foundation

protocol APICall {
    static var api: APIService { get set }
    static var base: URL { get }
}

extension APICall {
    private static func jsonRequest(endpoint: String) -> URLRequest {
        let fullUrl = base.appendingPathComponent(endpoint)
        var request = URLRequest(url: fullUrl)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    static func getJsonRequest(endpoint: String) -> URLRequest {
        var request = Self.jsonRequest(endpoint: endpoint)
        request.httpMethod = "GET"
        return request
    }

    static func postJsonRequest(endpoint: String) -> URLRequest {
        var request = Self.jsonRequest(endpoint: endpoint)
        request.httpMethod = "POST"
        return request
    }

    static func simpleAuthenticatedJsonPostRequest(_ endpoint: String, minor: String, major: String) -> URLRequest {
        var request = Self.postJsonRequest(endpoint: endpoint)
        request.setValue("\(major):\(minor)", forHTTPHeaderField: "Authorization")
        return request
    }

    static func simpleAuthenticatedJsonGetRequest(_ endpoint: String, minor: String, major: String) -> URLRequest {
        var request = Self.getJsonRequest(endpoint: endpoint)
        request.setValue("\(major):\(minor)", forHTTPHeaderField: "Authorization")
        return request
    }

    static func authenticatedJsonRequest(_ endpoint: String, bearerToken: String) -> URLRequest {
        var request = Self.postJsonRequest(endpoint: endpoint)
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        return request
    }

    static func authData() throws -> (minor: String, major: String) {
        guard let minor = SessionManager.shared.minor,
            let major = SessionManager.shared.major else {
                throw APIError.noAuthData
        }
        let minorString = String(minor)
        let majorString = String(major)

        return (minor: minorString, major: majorString)
    }
}

extension URLRequest {
    func jsonBody<T: Encodable>(_ data: T, _ encoder: JSONEncoder = JSONEncoder()) -> URLRequest {
        var newRequest = self
        encoder.dateEncodingStrategy = .iso8601
        newRequest.httpBody = try? encoder.encode(data)
        return newRequest
    }
}
