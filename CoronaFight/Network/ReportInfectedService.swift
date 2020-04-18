//
//  ReportService.swift
//  CoronaFight
//
//  Created by Przemysław Szurmak on 14/03/2020.
//  Copyright © 2020 Przemysław Szurmak. All rights reserved.
//

import Foundation
import RxSwift

struct ReportInfectedRequest: Codable {
    let testedAt: Date
}

struct ReportInfectedService: APICall {
    static var api = APIService()
    static let base = GlobalConfig.currentEnv.url()

    private static let endpoint = "report"

    static func report(testTime: Date) -> Observable<DashboardData?> {

        let authData: (minor: String, major: String)
        do {
            authData = try Self.authData()
        } catch {
            return Observable.error(APIError.noAuthData)
        }

        let requestBody = ReportInfectedRequest(testedAt: testTime)
        let request = Self.simpleAuthenticatedJsonPostRequest(self.endpoint, minor: authData.minor, major: authData.major).jsonBody(requestBody)
        return self.api.run(request).map { $0.value }
    }
}
