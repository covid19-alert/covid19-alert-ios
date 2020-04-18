//
//  RegisterService.swift
//  CoronaFight
//
//  Created by Przemysław Szurmak on 14/03/2020.
//  Copyright © 2020 Przemysław Szurmak. All rights reserved.
//

import Foundation
import RxSwift

struct RegisterRequest: Codable {
    let deviceUUID: String
    let lat: Double?
    let lon: Double?
    let firebaseToken: String?
}

struct RegisterResponse: Codable {
    let major: Int
    let minor: Int
    let authToken: String?
    let status: DashboardData?
}

struct RegisterService: APICall {
    static var api = APIService()
    static let base = GlobalConfig.currentEnv.url()

    private static let endpoint = "register"

    static func register(_ deviceUUID: String,
                         lat: Double?,
                         lon: Double?,
                         firebaseToken: String?) -> Observable<RegisterResponse>  {
        let requestBody = RegisterRequest(deviceUUID: deviceUUID, lat: lat, lon: lon, firebaseToken: firebaseToken)
        let request = Self.postJsonRequest(endpoint: Self.endpoint).jsonBody(requestBody)
        return self.api.run(request).map { $0.value }
    }
}
