//
//  InfectedIdsService.swift
//  CoronaFight
//
//  Created by Piotr Adamczak on 14/03/2020.
//  Copyright © 2020 Przemysław Szurmak. All rights reserved.
//

import Foundation
import RxSwift

struct MeetEvent: Codable {
    let start: Date
    let end: Date
    let seenUserId: String
    let closeDistanceLastingTime: Int
    let closeDistance: Int

    enum CodingKeys: String, CodingKey {
        case start, end, seenUserId
        case closeDistanceLastingTime = "close_distance_lasting_time"
        case closeDistance = "close_distance"
    }
}

struct InfectedIdsResponse: Codable {
    let metInfectedIds: [String]? = []
}

struct InfectedIdsService: APICall {
    static var api = APIService()
    static let base = GlobalConfig.currentEnv.url()

    private static let endpoint = "status_only_ids"

    static func fetchInfectedIds() -> Observable<InfectedIdsResponse> {
        let authData: (minor: String, major: String)
        do {
            authData = try Self.authData()
        } catch {
            return Observable.error(APIError.noAuthData)
        }

        let request = Self.simpleAuthenticatedJsonGetRequest(self.endpoint, minor: authData.minor, major: authData.major)
        return self.api.run(request).map { $0.value }
    }
}
