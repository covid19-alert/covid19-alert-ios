//
//  APIService.swift
//  CoronaFight
//
//  Created by Przemysław Szurmak on 14/03/2020.
//  Copyright © 2020 Przemysław Szurmak. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import SwiftDate
import CocoaLumberjack

enum Env: String {
    case prod = "https://prod-environment-url"
    case test = "https://test-environment-url"
    case local = "http://127.0.0.1:8080"

    func url() -> URL {
        URL(string: self.rawValue)!
    }
}

/// TODO: Error response structure TBD
struct ErrorResponse: Codable {
    let timestamp: String
    let status: Int
    let error, message, path: String

    func timestampDate() -> Date? {
        var timestampValue = timestamp
        if timestamp.last != "Z" {
            timestampValue.append("Z")
        }
        return timestampValue.toDate()?.date
    }
}

enum APIError: Error {
    case invalidResponse(ErrorResponse)
    case invalidResponseCode(Int, String?)
    case noAuthData

    var localizedDescription: String {
        switch self {
        case .invalidResponse(let errorResponse):
            return NSLocalizedString(errorResponse.message, comment: "")
        case .invalidResponseCode(let errorCode, _):
            return String(format: NSLocalizedString("Wrong response code: %d", comment: ""), errorCode)
        case .noAuthData:
            return NSLocalizedString("No authorization data", comment: "")
        }
    }
}

struct APIService {
    let session = URLSession.shared

    struct DataResponse<T> {
        let value: T
        let response: URLResponse
    }

    struct EmptyResponse {
        let response: URLResponse
    }

    func run<T: Decodable>(_ request: URLRequest, _ decoder: JSONDecoder = JSONDecoder()) -> Observable<DataResponse<T>> {
        let startTime = Date()
        return self.session.rx
            .response(request: request)
            .map { result in
                let finish = Date().timeIntervalSince(startTime)
                DDLogDebug(LogHelper.bannerLine, ddlog: LogHelper.shared.networkLog)
                DDLogDebug("Request:\n" + request.curlString, ddlog: LogHelper.shared.networkLog)
                DDLogDebug("Response:\n" + LogHelper.shared.convertResponseToString(result.response, result.data, nil, finish), ddlog: LogHelper.shared.networkLog)
                DDLogDebug(LogHelper.bannerLine, ddlog: LogHelper.shared.networkLog)

                if (200..<300 ~= result.response.statusCode) == false   {
                    decoder.dateDecodingStrategy = .custom { decoder -> Date in
                        let strValue = try? decoder.singleValueContainer().decode(String.self)
                        return strValue?.toDate()?.date ?? Date()
                    }
                    if let errorValue = try? decoder.decode(ErrorResponse.self, from: result.data) {
                        throw APIError.invalidResponse(errorValue)
                    } else {
                        let stringData = String(data: result.data, encoding: .utf8)
                        throw APIError.invalidResponseCode(result.response.statusCode, stringData)
                    }
                }
                decoder.dateDecodingStrategy = .iso8601
                let value = try decoder.decode(T.self, from: result.data)
                return DataResponse(value: value, response: result.response)
            }
            .observeOn(MainScheduler.instance)
            .asObservable()
    }

    func run(_ request: URLRequest) -> Observable<EmptyResponse> {
        return self.session.rx
            .response(request: request)
            .map { result in
                if (200..<300 ~= result.response.statusCode) == false {
                    let errorDecoder = JSONDecoder()
                    errorDecoder.dateDecodingStrategy = .iso8601
                    if let errorValue = try? errorDecoder.decode(ErrorResponse.self, from: result.data) {
                        throw APIError.invalidResponse(errorValue)
                    } else {
                        let stringData = String(data: result.data, encoding: .utf8)
                        throw APIError.invalidResponseCode(result.response.statusCode, stringData)
                    }
                }
                return EmptyResponse(response: result.response)
            }
            .observeOn(MainScheduler.instance)
            .asObservable()
    }
}
